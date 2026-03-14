// FloatingKeyboardApp.swift
// FloatingKeyboard — macOS 15+ · Swift 6
//
// Entry point + AppDelegate.
// Sets up the NSPanel, status-bar icon, and accessibility watcher.
// ─────────────────────────────────────────────────────────────────────────────

import SwiftUI
import AppKit
import ApplicationServices

// MARK: – App

@main
struct FloatingKeyboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // NSApp.setActivationPolicy(.accessory) makes Window scenes unreliable,
        // so we use SettingsWindowManager to manually create the settings window.
        Settings { EmptyView() }
    }
}

// MARK: – SettingsWindowManager

@MainActor
final class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    private var window: NSWindow?

    func show(viewModel: KeyboardViewModel) {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = SettingsWindow(viewModel: viewModel)
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.title = "FloatingKeyboard Settings"
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: view)
        w.center()
        w.level = .floating
        window = w
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: – AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    /// Weak back-reference used by SwiftUI hide-button actions.
    static weak var shared: AppDelegate?

    private(set) var keyboardPanel: KeyboardPanel?
    private var accessibilityObserver: AccessibilityObserver?
    private var statusItem: NSStatusItem?

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Utility / background app – no Dock icon, no menu bar.
        NSApp.setActivationPolicy(.accessory)

        // Prompt the user for Accessibility access (needed for AX API + CGEvent).
        requestAccessibilityPermission()

        // Build the floating glass panel.
        let panel = KeyboardPanel()
        keyboardPanel = panel
        panel.show()

        // Status-bar icon so the user can show / hide / quit.
        buildStatusBar()

        // Watch for text-field focus changes to auto-show/hide.
        let obs = AccessibilityObserver(panel: panel)
        accessibilityObserver = obs
        obs.startObserving()
        
        // Setup suppression and clipboard using the shared view model
        KeyboardSuppressor.shared.setEnabled(panel.viewModel.isInternalKeyboardDisabled)
        ClipboardService.shared.startMonitoring(with: panel.viewModel)
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("InternalKeyboardToggleChanged"),
            object: nil, queue: .main
        ) { _ in
            KeyboardSuppressor.shared.setEnabled(panel.viewModel.isInternalKeyboardDisabled)
        }

        print("DEBUG: FloatingKeyboardApp started and services initialized")
    }

    // MARK: Accessibility Permission

    private func requestAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        print("DEBUG: AXIsProcessTrusted initially = \(trusted)")
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [promptKey: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }

    // MARK: Status Bar

    private func buildStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(
            systemSymbolName: "keyboard.fill",
            accessibilityDescription: "Floating Keyboard"
        )

        let menu = NSMenu()
        menu.addItem(withTitle: "Show Keyboard",
                     action: #selector(showKeyboard), keyEquivalent: "")
        menu.addItem(withTitle: "Hide Keyboard",
                     action: #selector(hideKeyboard), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit",
                     action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem?.menu = menu
    }

    @objc private func showKeyboard() { keyboardPanel?.show() }
    @objc private func hideKeyboard() { keyboardPanel?.hide() }
}
