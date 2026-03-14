// KeyboardSuppressor.swift
// FloatingKeyboard — macOS 15+ · Swift 6
//
// Suppresses internal keyboard events using a global CGEventTap,
// while allowing external/Bluetooth keyboards to function.
// ─────────────────────────────────────────────────────────────────────────────

import Foundation
import AppKit
import IOKit.hid
import CoreGraphics

@MainActor
final class KeyboardSuppressor {
    static let shared = KeyboardSuppressor()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isEnabled = false
    
    private init() {}
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            startSuppression()
        } else {
            stopSuppression()
        }
    }
    
    private func startSuppression() {
        guard eventTap == nil else { return }
        
        // Cache IDs immediately before starting tap
        cacheInternalDeviceIDs()
        
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let suppressor = Unmanaged<KeyboardSuppressor>.fromOpaque(refcon).takeUnretainedValue()
                
                if suppressor.shouldSuppress(event: event) {
                    return nil // Suppress the event
                }
                
                return Unmanaged.passUnretained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("[KeyboardSuppressor] Failed to create event tap")
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("[KeyboardSuppressor] Suppression started")
    }
    
    private func stopSuppression() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let rls = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rls, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
            print("[KeyboardSuppressor] Suppression stopped")
        }
    }
    
    private func shouldSuppress(event: CGEvent) -> Bool {
        guard isEnabled else { return false }
        
        let field87 = CGEventField(rawValue: 87)!
        let registryID = event.getIntegerValueField(field87)
        
        if isInternalDevice(registryID: UInt64(registryID)) {
            print("[KeyboardSuppressor] SUPPRESSING Event from ID: \(registryID)")
            return true
        }
        
        return false
    }
    
    private var internalDeviceIDs: Set<UInt64> = []
    private var externalDeviceIDs: Set<UInt64> = []
    
    private func isInternalDevice(registryID: UInt64) -> Bool {
        if registryID == 0 { return false }
        if internalDeviceIDs.contains(registryID) { return true }
        if externalDeviceIDs.contains(registryID) { return false }
        
        // Dynamic check for unknown ID
        let matching = IORegistryEntryIDMatching(registryID)
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching! as CFDictionary, &iterator)
        
        if result == KERN_SUCCESS {
            let device = IOIteratorNext(iterator)
            if device != 0 {
                let name = getDeviceName(device) ?? "Unknown"
                let transport = IORegistryEntryCreateCFProperty(device, kIOHIDTransportKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String ?? ""
                let vendorID = IORegistryEntryCreateCFProperty(device, kIOHIDVendorIDKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber ?? 0
                
                let isAppleInternal = (vendorID.intValue == 1452 && 
                                      (transport == "Internal" || transport == "SPI" || transport == "FIFO" || transport == "PS2" || transport == "N/A" || transport == "" || name.lowercased().contains("internal")))
                
                let isGenericInternal = (transport == "PS2" || transport == "SPI" || (transport == "" && name == "Keyboard") || name.lowercased().contains("apple internal"))
                
                IOObjectRelease(device)
                IOObjectRelease(iterator)
                
                if isAppleInternal || isGenericInternal {
                    print("[KeyboardSuppressor] Dynamically Matched Internal -> \(name), Transport: \(transport), ID: \(registryID)")
                    internalDeviceIDs.insert(registryID)
                    return true
                } else {
                    print("[KeyboardSuppressor] Dynamically Matched External -> \(name), Transport: \(transport), ID: \(registryID)")
                    externalDeviceIDs.insert(registryID)
                    return false
                }
            }
            IOObjectRelease(iterator)
        }
        
        return false
    }
    
    private func cacheInternalDeviceIDs() {
        // Clear caches on new session
        internalDeviceIDs.removeAll()
        externalDeviceIDs.removeAll()
        
        let matchingDict = IOServiceMatching(kIOHIDDeviceKey) as NSMutableDictionary
        matchingDict[kIOHIDDeviceUsagePageKey] = kHIDPage_GenericDesktop
        matchingDict[kHIDUsage_GD_Keyboard] = kHIDUsage_GD_Keyboard
        
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
        
        if result == KERN_SUCCESS {
            var device = IOIteratorNext(iterator)
            while device != 0 {
                var regID: UInt64 = 0
                IORegistryEntryGetRegistryEntryID(device, &regID)
                
                let name = getDeviceName(device) ?? "Unknown"
                let transport = IORegistryEntryCreateCFProperty(device, kIOHIDTransportKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String ?? ""
                let vendorID = IORegistryEntryCreateCFProperty(device, kIOHIDVendorIDKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber ?? 0
                let primaryUsagePage = IORegistryEntryCreateCFProperty(device, kIOHIDPrimaryUsagePageKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber ?? 0
                let primaryUsage = IORegistryEntryCreateCFProperty(device, kIOHIDPrimaryUsageKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber ?? 0
                
                let isKeyboardUsage = (primaryUsagePage.intValue == 1 && primaryUsage.intValue == 6)
                
                let isAppleInternal = (vendorID.intValue == 1452 && 
                                      (transport == "Internal" || transport == "SPI" || transport == "FIFO" || transport == "PS2" || transport == "N/A" || transport == "" || name.lowercased().contains("internal")))
                
                let isGenericInternal = (transport == "PS2" || transport == "SPI" || (transport == "" && name == "Keyboard") || name.lowercased().contains("apple internal"))
                
                if (isAppleInternal || isGenericInternal) && isKeyboardUsage {
                    internalDeviceIDs.insert(regID)
                    print("[KeyboardSuppressor] Cache: Internal -> \(name), Transport: \(transport), ID: \(regID)")
                } else if isKeyboardUsage {
                    externalDeviceIDs.insert(regID)
                    print("[KeyboardSuppressor] Cache: External -> \(name), Transport: \(transport), ID: \(regID)")
                }
                
                IOObjectRelease(device)
                device = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
    }
    
    private func getDeviceName(_ device: io_object_t) -> String? {
        if let name = IORegistryEntryCreateCFProperty(device, kIOHIDProductKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
            return name
        }
        return nil
    }
}
