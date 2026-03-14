// AccessibilityObserver.swift
// FloatingKeyboard — macOS 15+ · Swift 6
//
// Watches for text-field/text-area focus using the macOS Accessibility API and
// automatically shows or hides the floating keyboard panel.
//
// Strategy (two complementary mechanisms):
//   1. NSWorkspace / NSNotificationCenter notifications  → instant response to
//      app-switch and window-focus changes.
//   2. A 0.4 s repeating timer                           → catches field-to-field
//      navigation inside the same app (which doesn't always fire a notification).
//
// The observer tracks the previous focus state so it only triggers show/hide
// on actual transitions (not on every timer tick).
//
// ─────────────────────────────────────────────────────────────────────────────
// Accessibility permission setup:
//   • Add NSAccessibilityUsageDescription to Info.plist.
//   • Disable the App Sandbox (or add com.apple.security.accessibility).
//   • The first launch will show the system prompt; subsequent launches check
//     AXIsProcessTrusted() silently.
// ─────────────────────────────────────────────────────────────────────────────

import AppKit
import ApplicationServices
import Foundation
import os.log

@MainActor
final class AccessibilityObserver {

    // Reference to the panel so we can call show() / hide().
    weak var panel: KeyboardPanel?

    private var timer    : Timer?
    private var observers: [NSObjectProtocol] = []
    private var hideWorkItem: DispatchWorkItem?

    private let instanceID = UUID().uuidString.prefix(4)

    /// Remembers the last focus state to avoid redundant show/hide calls.
    private var lastWasTextField = false

    /// AX roles that should trigger the keyboard.
    private static let textRoles: Set<String> = [
        kAXTextFieldRole   as String,
        kAXTextAreaRole    as String,
        kAXComboBoxRole    as String,
        "AXSearchField",
        "AXTextField",      // fallback string form
        "AXTextArea",
    ]

    // MARK: – Init / Deinit

    init(panel: KeyboardPanel) {
        self.panel = panel
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        timer?.invalidate()
    }

    private var axObserver: AXObserver?
    private var runLoopSource: CFRunLoopSource?
    private var isAXObserverSetup = false

    // MARK: – Start

    func startObserving() {
        registerNotifications()
        startPollingTimer()
        if AXIsProcessTrusted() {
            setupAXObserver()
        }
    }

    // MARK: – Notifications

    private func registerNotifications() {
        let ws  = NSWorkspace.shared.notificationCenter
        let nc  = NotificationCenter.default

        // App switch
        let a = ws.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkFocus() }
        }

        // Window focus
        let b = nc.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkFocus() }
        }
        
        // Tablet Mode Toggled
        let c = nc.addObserver(
            forName: NSNotification.Name("TabletModeToggled"),
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in 
                guard let self = self, let isTablet = self.panel?.viewModel.isTabletModeEnabled else { return }
                if isTablet && !self.lastWasTextField {
                    // Hide immediately when tablet mode turns on, if not in a text field
                    self.hideWorkItem?.cancel()
                    self.panel?.restorePreviousWindowIfNeeded()
                    self.panel?.hide()
                } else {
                    self.checkFocus()
                }
            }
        }

        observers = [a, b, c]
    }

    // MARK: – Polling timer

    private func startPollingTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkFocus() }
        }
        timer?.tolerance = 0.1
    }

    // MARK: – AXObserver setup

    private func setupAXObserver() {
        print("[AXObserver:\(instanceID)] Attempting to create AXObserver...")
        var observerRaw: AXObserver?
        let err = AXObserverCreate(0, axObserverCallback, &observerRaw)
        if err != .success {
            print("[AXObserver:\(instanceID)] AXObserverCreate failed with error: \(err.rawValue)")
            isAXObserverSetup = false
            return
        }
        guard let observer = observerRaw else { 
            print("[AXObserver:\(instanceID)] AXObserverCreate succeeded but observer is nil")
            isAXObserverSetup = false
            return 
        }
        
        axObserver = observer
        let systemWide = AXUIElementCreateSystemWide()
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        let addErr = AXObserverAddNotification(
            observer,
            systemWide,
            kAXFocusedUIElementChangedNotification as CFString,
            selfPtr
        )
        if addErr != .success {
            print("[AXObserver:\(instanceID)] AXObserverAddNotification failed: \(addErr.rawValue)")
        }
        
        let rls = AXObserverGetRunLoopSource(observer)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, .defaultMode)
        runLoopSource = rls
        isAXObserverSetup = true
        print("[AXObserver:\(instanceID)] AXObserver setup successfully.")
    }

    // MARK: – Focus check

    private var lastFocusedElement: AXUIElement?

    /// Query the system-wide focused UI element and show/hide the keyboard
    /// only when the focus state actually changes.
    func checkFocus() {
        if !isAXObserverSetup && AXIsProcessTrusted() {
            print("[AXObserver:\(instanceID)] Setup triggered inside checkFocus")
            setupAXObserver()
        }
        guard AXIsProcessTrusted() else {
            print("[AXObserver:\(instanceID)] Not trusted in checkFocus, ignoring")
            return
        }
        
        panel?.adjustLevelForIME()
        
        let systemWide = AXUIElementCreateSystemWide()

        var rawValue: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &rawValue
        )

        guard err == .success, let raw = rawValue else {
            if err != .success {
                print("[AXObserver:\(instanceID)] Error copying focused element attribute: \(err.rawValue)")
            } else {
                // This is normal if no element is focused or if switching apps
            }
            lastFocusedElement = nil
            transitionIfNeeded(inTextField: false, element: nil)
            return
        }

        guard CFGetTypeID(raw) == AXUIElementGetTypeID() else {
            print("[AXObserver:\(instanceID)] Focused attribute value is not an AXUIElement")
            lastFocusedElement = nil
            transitionIfNeeded(inTextField: false, element: nil)
            return
        }

        // swiftlint:disable:next force_cast
        let element = raw as! AXUIElement
        
        if let last = lastFocusedElement, CFEqual(last, element) {
            return // Deduplicate the exact same element
        }
        lastFocusedElement = element

        // Read the role attribute.
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(
            element,
            kAXRoleAttribute as CFString,
            &roleRef
        )
        let role = (roleRef as? String) ?? ""
        print("[AXObserver:\(instanceID)] Found role: \(role)")

        transitionIfNeeded(inTextField: Self.textRoles.contains(role), element: element)
    }

    // MARK: – State transition

    private func transitionIfNeeded(inTextField: Bool, element: AXUIElement?) {
        print("[AXObserver:\(instanceID)] transitionIfNeeded inTextField=\(inTextField), hasElement=\(element != nil)")
        var shouldShow = inTextField
        let viewModel = panel?.viewModel
        
        if shouldShow {
            if viewModel?.isAutoShowEnabled == false {
                print("[AXObserver:\(instanceID)] Auto-Show is disabled, setting shouldShow to false")
                shouldShow = false
            }
            if let frontmostId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
               viewModel?.excludedApps.contains(frontmostId) == true {
                shouldShow = false
            }
        }

        // If we are moving between different text fields, we still want to 
        // trigger the 'show' logic because Tablet Mode needs to know about the new target window. 
        // However, if we are moving from a text field to a non-text field (or vice versa), 
        // we definitely want to trigger it.
        
        let stateChanged = shouldShow != lastWasTextField
        lastWasTextField = shouldShow

        if shouldShow {
            let tabletEnabled = viewModel?.isTabletModeEnabled == true
            print("[AXObserver:\(instanceID)] Triggering show logic. Tablet Mode: \(tabletEnabled), StateChanged: \(stateChanged)")
            if tabletEnabled {
                panel?.showForTabletMode(focusedElement: element)
            } else if stateChanged {
                panel?.show()
            }
        } else if stateChanged {
            print("[AXObserver:\(instanceID)] Triggering hide logic.")
            hideWorkItem?.cancel()
            let item = DispatchWorkItem { [weak self] in
                self?.panel?.restorePreviousWindowIfNeeded()
                self?.panel?.hide()
            }
            hideWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: item)
        }
    }
}

private let axObserverCallback: AXObserverCallback = { observer, element, notification, refcon in
    guard let refcon = refcon else { return }
    let observerSelf = Unmanaged<AccessibilityObserver>.fromOpaque(refcon).takeUnretainedValue()
    Task { @MainActor in
        observerSelf.checkFocus()
    }
}
