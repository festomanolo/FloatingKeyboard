// KeyboardPanel.swift
// FloatingKeyboard — macOS 15+ · Swift 6
//
// NSPanel subclass that:
//   • Floats above every other window  (.floating level)
//   • Never steals keyboard focus      (.nonactivatingPanel)
//   • Has a blurred glass background   (SwiftUI .ultraThinMaterial)
//   • Is freely resizable              (.resizable style mask)
//   • Remembers its last position      (setFrameAutosaveName)
// ─────────────────────────────────────────────────────────────────────────────

import AppKit
import SwiftUI

final class KeyboardPanel: NSPanel {

    // The observable state shared between this panel and all SwiftUI key views.
    let viewModel = KeyboardViewModel()

    // MARK: – Init

    init() {
        super.init(
            contentRect: KeyboardPanel.defaultFrame(),
            styleMask: [
                .nonactivatingPanel,     // ← the critical bit: no focus steal
                .titled,
                .resizable,
                .closable,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )
        configure()
        installSwiftUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(screenConfigurationChanged(_:)), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        
        DispatchQueue.main.async { [weak self] in
            self?.validatePosition()
        }
    }

    // MARK: – Configuration

    private func configure() {
        // Float above all application windows (but stay below the menu bar).
        level = .floating
        isFloatingPanel    = true
        worksWhenModal     = true

        // Transparent chrome for the glass look.
        titlebarAppearsTransparent  = true
        titleVisibility             = .hidden
        isMovableByWindowBackground = true
        isOpaque                    = false
        backgroundColor             = .clear
        hasShadow                   = true

        // Slide in/out like a standard utility window.
        animationBehavior = .utilityWindow

        // Appear on every Space; don't show in Mission Control / Exposé cycling.
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // Persist the last position between launches.
        setFrameAutosaveName("FloatingKeyboard_Frame")

        // Sensible size limits.
        minSize = NSSize(width: 480,  height: 200)
        maxSize = NSSize(width: 1800, height: 750)
    }

    // MARK: – SwiftUI root view

    private func installSwiftUI() {
        let root = KeyboardContainerView(viewModel: viewModel)
        let host = NSHostingView(rootView: root)
        host.frame = contentView?.bounds ?? .zero
        host.autoresizingMask = [.width, .height]
        contentView = host
    }

    // MARK: – Show / Hide with animation

    func show(animated: Bool = true) {
        guard !isVisible else { return }
        
        let targetFrame = self.frame
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let hiddenY = screen.frame.minY - targetFrame.height
        let hiddenFrame = NSRect(x: targetFrame.origin.x, y: hiddenY, width: targetFrame.width, height: targetFrame.height)
        
        if animated {
            self.setFrame(hiddenFrame, display: true)
            alphaValue = 0
            orderFront(nil)
            
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.35
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().setFrame(targetFrame, display: true)
                self.animator().alphaValue = 1
            }
        } else {
            orderFront(nil)
        }
    }

    func hide(animated: Bool = true) {
        guard isVisible else { return }
        
        if animated {
            let screen = NSScreen.main ?? NSScreen.screens[0]
            let hiddenY = screen.frame.minY - frame.height
            let hiddenFrame = NSRect(x: frame.origin.x, y: hiddenY, width: frame.width, height: frame.height)
            
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.30
                ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
                self.animator().setFrame(hiddenFrame, display: true)
                self.animator().alphaValue = 0
            }, completionHandler: {
                self.orderOut(nil)
                self.alphaValue = 1  // reset
                // Restore frame so it's not "trapped" below screen for next show calculation if not animated
                let restoredY = screen.visibleFrame.minY + 20
                let restoredFrame = NSRect(x: self.frame.origin.x, y: restoredY, width: self.frame.width, height: self.frame.height)
                self.setFrame(restoredFrame, display: true)
            })
        } else {
            orderOut(nil)
        }
    }

    // MARK: – Prevent focus hijack

    override var canBecomeKey:  Bool { false }
    override var canBecomeMain: Bool { false }

    // MARK: – Default position (bottom-center of main screen)

    private static func defaultFrame() -> NSRect {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let sf     = screen.visibleFrame
        let w: CGFloat = 920
        let h: CGFloat = 350
        return NSRect(
            x: sf.midX - w / 2,
            y: sf.minY + 20,
            width: w, height: h
        )
    }

    // MARK: – Multi-monitor position validation

    @objc private func screenConfigurationChanged(_ notification: Notification) {
        validatePosition()
    }

    private func validatePosition() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }
        
        let isValid = screens.contains { screen in
            screen.frame.intersects(self.frame)
        }
        
        if !isValid {
            resetToDefaultPosition()
        }
    }

    private func resetToDefaultPosition() {
        self.setFrame(KeyboardPanel.defaultFrame(), display: true, animate: true)
    }

    // MARK: – IME Compatibility

    func adjustLevelForIME() {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return }
        
        var imeWindowFrame: NSRect?
        let imeVisible = windowList.contains { window in
            guard let owner = window[kCGWindowOwnerName as String] as? String else { return false }
            let isIME = owner.contains("InputMethod") || owner.contains("TCIM") || owner.contains("SCIM") || owner.contains("KIM")
            if isIME, let boundsDict = window[kCGWindowBounds as String] as? NSDictionary,
               let rect = CGRect(dictionaryRepresentation: boundsDict) {
                if rect.height > 10 && rect.width > 20 {
                    let screenHeight = NSScreen.screens.first?.frame.height ?? 1080
                    let flippedY = screenHeight - rect.origin.y - rect.height
                    imeWindowFrame = NSRect(x: rect.origin.x, y: flippedY, width: rect.width, height: rect.height)
                    return true
                }
            }
            return false
        }
        
        let targetLevel = imeVisible ? NSWindow.Level(NSWindow.Level.floating.rawValue - 1) : .floating
        if self.level != targetLevel {
            self.level = targetLevel
        }
        
        if let imeFrame = imeWindowFrame, self.frame.intersects(imeFrame) {
            var newFrame = self.frame
            newFrame.origin.y = imeFrame.minY - self.frame.height - 10
            if newFrame.origin.y > 0 {
                self.setFrame(newFrame, display: true, animate: true)
            }
        }
    }

    // MARK: – Tablet Mode Window Management

    // MARK: – Tablet Mode Window Management

    private var previouslyResizedWindow: AXUIElement?
    private var originalWindowFrame: CGRect?
    private var originalDockAutoHideState: Bool?

    private func setDockAutoHide(_ hide: Bool) {
        let script = """
        tell application "System Events"
            tell dock preferences to set autohide to \(hide)
        end tell
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let err = error {
                print("[KeyboardPanel] Error setting dock autohide: \(err)")
            }
        }
    }

    private func readDockAutoHide() -> Bool {
        let script = """
        tell application "System Events"
            get autohide of dock preferences
        end tell
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let resultDescriptor = appleScript.executeAndReturnError(&error)
            return resultDescriptor.booleanValue
        }
        return false
    }

    func showForTabletMode(focusedElement: AXUIElement?) {
        // Save current dock state if not already saved
        if originalDockAutoHideState == nil {
            originalDockAutoHideState = readDockAutoHide()
        }
        
        // Hide the dock for tablet mode
        setDockAutoHide(true)
        
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let sf = screen.frame // use full frame since dock is hidden
        let kbHeight: CGFloat = 350
        
        // Pin keyboard to the very bottom
        self.setFrame(NSRect(x: sf.minX, y: sf.minY, width: sf.width, height: kbHeight), display: true, animate: true)

        guard let element = focusedElement else {
            self.show()
            return
        }
        
        var windowRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXWindowAttribute as CFString, &windowRef)
        
        if let windowRaw = windowRef, CFGetTypeID(windowRaw) == AXUIElementGetTypeID() {
            // swiftlint:disable:next force_cast
            let window = windowRaw as! AXUIElement
            
            if previouslyResizedWindow == nil || !CFEqual(previouslyResizedWindow, window) {
                restorePreviousWindowIfNeeded()
                
                var posRef: CFTypeRef?
                var sizeRef: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef)
                AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
                
                if let posValue = posRef as! AXValue?, let sizeValue = sizeRef as! AXValue? {
                    var point = CGPoint.zero
                    var size = CGSize.zero
                    AXValueGetValue(posValue, .cgPoint, &point)
                    AXValueGetValue(sizeValue, .cgSize, &size)
                    self.originalWindowFrame = CGRect(origin: point, size: size)
                    self.previouslyResizedWindow = window
                    
                    // On macOS, AXPosition is (0,0) at top-left.
                    // If we move the windowUP so it rests exactly on top of the keyboard:
                    // new height should be screen height - kbHeight
                    let newHeight = sf.height - kbHeight
                    
                    // We only want to resize it if it's currently taller than the available space,
                    // or if it's positioned so low that it intersects the keyboard.
                    // But standard behavior for tablet mode is to maximize the app in the space above.
                    var newSize = CGSize(width: size.width, height: min(size.height, newHeight))
                    
                    // Adjust Y position. In AX coordinates, Y = 0 is top.
                    // We want the bottom of the window to be at (Y + Height) = sf.height - kbHeight
                    var newPoint = point
                    let currentBottom = point.y + size.height
                    let availableBottom = sf.height - kbHeight
                    
                    if currentBottom > availableBottom {
                        // Push it up
                        newPoint.y = max(0, availableBottom - newSize.height)
                    }
                    
                    if let newSizeValue = AXValueCreate(.cgSize, &newSize) {
                        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, newSizeValue)
                    }
                    if let newPosValue = AXValueCreate(.cgPoint, &newPoint) {
                        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, newPosValue)
                    }
                }
            }
        }
        
        self.show()
    }

    func restorePreviousWindowIfNeeded() {
        if let origDockState = originalDockAutoHideState {
            setDockAutoHide(origDockState)
            originalDockAutoHideState = nil
        }
        
        guard let window = previouslyResizedWindow, let frame = originalWindowFrame else { return }
        var size = frame.size
        var point = frame.origin
        
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
        if let posValue = AXValueCreate(.cgPoint, &point) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        }
        
        previouslyResizedWindow = nil
        originalWindowFrame = nil
    }
}
