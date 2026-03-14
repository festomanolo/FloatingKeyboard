// ClipboardService.swift
// FloatingKeyboard — macOS 15+ · Swift 6
//
// Monitors the system pasteboard and maintains a list of recent copies.
// ─────────────────────────────────────────────────────────────────────────────

import AppKit
import Foundation
import Observation

@MainActor
final class ClipboardService {
    static let shared = ClipboardService()
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount = -1
    private var timer: Timer?
    
    // Reference to the view model to update history
    weak var viewModel: KeyboardViewModel?
    
    private init() {
        lastChangeCount = pasteboard.changeCount
    }
    
    func startMonitoring(with vm: KeyboardViewModel) {
        self.viewModel = vm
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPasteboard()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkPasteboard() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount
        
        if let newString = pasteboard.string(forType: .string), !newString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let frontmost = NSWorkspace.shared.frontmostApplication
            let appName = frontmost?.localizedName
            let bundleId = frontmost?.bundleIdentifier
            viewModel?.addClipboardContent(newString, sourceApp: appName, sourceBundleId: bundleId)
        }
    }
    
    
    func copyToPasteboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
