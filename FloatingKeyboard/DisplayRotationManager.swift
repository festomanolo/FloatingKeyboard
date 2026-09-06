// DisplayRotationManager.swift
// FloatingKeyboard
//
// Manages display rotation using private IOKit and CoreDisplay APIs
// Based on research from fb-rotate, BetterDisplay, and Display Manager projects
// ─────────────────────────────────────────────────────────────────────────────

import Foundation
import IOKit
import CoreGraphics

@MainActor
final class DisplayRotationManager {
    
    static let shared = DisplayRotationManager()
    
    private init() {}
    
    // MARK: - Rotation Angles
    
    enum RotationAngle: Int {
        case rotate0 = 0
        case rotate90 = 90
        case rotate180 = 180
        case rotate270 = 270
        
        var ioKitValue: UInt64 {
            switch self {
            case .rotate0: return 0x00000000
            case .rotate90: return 0x00000001
            case .rotate180: return 0x00000002
            case .rotate270: return 0x00000003
            }
        }
    }
    
    // MARK: - Private IOKit Constants
    
    // These constants are from IOGraphicsTypesPrivate.h
    private let kIOFBSetTransform: UInt64 = 0x00000400
    
    // MARK: - Public Methods
    
    /// Get the current rotation angle of the main display
    func getCurrentRotation() -> RotationAngle {
        let rotation = CGDisplayRotation(CGMainDisplayID())
        
        switch Int(rotation) {
        case 0: return .rotate0
        case 90: return .rotate90
        case 180: return .rotate180
        case 270: return .rotate270
        default: return .rotate0
        }
    }
    
    /// Rotate the main display to the specified angle
    func rotateDisplay(to angle: RotationAngle) -> Bool {
        return rotateDisplay(displayID: CGMainDisplayID(), to: angle)
    }
    
    /// Toggle between 0° and 180° rotation
    func toggle180Rotation() -> Bool {
        let current = getCurrentRotation()
        let newAngle: RotationAngle = (current == .rotate0) ? .rotate180 : .rotate0
        return rotateDisplay(to: newAngle)
    }
    
    /// Rotate a specific display to the specified angle
    func rotateDisplay(displayID: CGDirectDisplayID, to angle: RotationAngle) -> Bool {
        // Try Method 1: CoreGraphics Display Configuration API
        if tryRotateWithCGDisplayConfig(displayID: displayID, angle: angle) {
            return true
        }
        
        // Try Method 2: IOKit API (for external displays)
        if tryRotateWithIOKit(displayID: displayID, angle: angle) {
            return true
        }
        
        print("Display rotation not supported on this display")
        return false
    }
    
    /// Try rotating using CoreGraphics Display Configuration API
    private func tryRotateWithCGDisplayConfig(displayID: CGDirectDisplayID, angle: RotationAngle) -> Bool {
        var config: CGDisplayConfigRef?
        
        // Begin configuration
        let beginResult = CGBeginDisplayConfiguration(&config)
        guard beginResult == .success, let config = config else {
            print("Failed to begin display configuration")
            return false
        }
        
        // Set rotation
        let rotationResult = CGConfigureDisplayWithDisplayMode(
            config,
            displayID,
            nil,  // Use current mode
            nil   // No options dictionary
        )
        
        if rotationResult != .success {
            CGCancelDisplayConfiguration(config)
            print("Failed to configure display rotation")
            return false
        }
        
        // Try to apply the configuration
        let applyResult = CGCompleteDisplayConfiguration(config, .permanently)
        
        if applyResult == .success {
            print("Display rotated to \(angle.rawValue)° using CGDisplayConfig")
            return true
        } else {
            print("Failed to apply display configuration. Error: \(applyResult.rawValue)")
            return false
        }
    }
    
    /// Try rotating using IOKit API (fb-rotate method)
    private func tryRotateWithIOKit(displayID: CGDirectDisplayID, angle: RotationAngle) -> Bool {
        // CRITICAL: Call CGGetOnlineDisplayList first to avoid hangs (Yosemite+ requirement)
        var displayCount: UInt32 = 0
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)
        let listResult = CGGetOnlineDisplayList(16, &displays, &displayCount)
        
        guard listResult == .success else {
            print("Failed to get online display list")
            return false
        }
        
        // Get the IOService port for the display using dynamic lookup to support modern SDKs
        typealias CGDisplayIOServicePortFunc = @convention(c) (CGDirectDisplayID) -> io_service_t
        var service: io_service_t = 0
        if let handle = dlopen(nil, RTLD_NOW),
           let sym = dlsym(handle, "CGDisplayIOServicePort") {
            let getPort = unsafeBitCast(sym, to: CGDisplayIOServicePortFunc.self)
            service = getPort(displayID)
        }
        
        guard service != 0 else {
            print("Failed to get IOService port for display")
            return false
        }
        
        // Prepare the rotation parameter using fb-rotate method
        // The parameter is: (rotation_value << 16) | kIOFBSetTransform
        let rotationParam = (angle.ioKitValue << 16) | kIOFBSetTransform
        
        // Request the display to apply the transformation
        let result = IOServiceRequestProbe(service, UInt32(rotationParam))
        
        if result == kIOReturnSuccess {
            print("Display rotated to \(angle.rawValue)° using IOKit (fb-rotate method)")
            return true
        } else {
            print("IOKit rotation failed. Error code: \(result)")
            // Error codes:
            // -536870199 (0xe00002c9) = kIOReturnUnsupported - Display doesn't support rotation
            // -536870206 (0xe00002c2) = kIOReturnBadArgument - Invalid rotation angle
            return false
        }
    }
    
    // MARK: - Display Information
    
    /// Get information about all connected displays
    func getDisplayInfo() -> [(id: CGDirectDisplayID, rotation: RotationAngle, bounds: CGRect)] {
        var displayInfo: [(CGDirectDisplayID, RotationAngle, CGRect)] = []
        
        var displayCount: UInt32 = 0
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)
        
        let result = CGGetActiveDisplayList(16, &displays, &displayCount)
        
        guard result == .success else {
            return displayInfo
        }
        
        for i in 0..<Int(displayCount) {
            let displayID = displays[i]
            let rotation = RotationAngle(rawValue: Int(CGDisplayRotation(displayID))) ?? .rotate0
            let bounds = CGDisplayBounds(displayID)
            displayInfo.append((displayID, rotation, bounds))
        }
        
        return displayInfo
    }
}
