// KeyEventSender.swift
// FloatingKeyboard — macOS 15+ · Swift 6
//
// Posts CGEvent key presses to the HID event stream so they reach
// whichever app currently has keyboard focus — Chrome, Notes, Terminal, etc.
//
// Requirements:
//   • The app must be trusted for Accessibility (System Settings →
//     Privacy & Security → Accessibility).
//   • Posting to .cghidEventTap requires that permission.
// ─────────────────────────────────────────────────────────────────────────────

import CoreGraphics
import Foundation
import AppKit
import AVFoundation
import AudioToolbox
import os.log

// MARK: –

@MainActor
final class KeyEventSender {

    /// Shared singleton – one CGEventSource is reused for all key events.
    static let shared = KeyEventSender()
    
    private var soundPlayers: [SoundProfile: AVAudioPlayer] = [:]
    
    private static let logger = Logger(subsystem: "manolo.FloatingKeyboard", category: "KeyEventSender")

    private init() {
        // Load custom sound files
        loadSounds()
    }
    
    private func loadSounds() {
        let soundFiles: [(SoundProfile, String)] = [
            (.clicky, "clicky.wav"),
            (.thocky, "thocky.wav"),
            (.futuristic, "futuristic.wav")
        ]
        
        for (profile, filename) in soundFiles {
            if let soundURL = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".wav", with: ""), withExtension: "wav", subdirectory: "Sounds") {
                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL)
                    player.prepareToPlay()
                    player.volume = 0.6
                    soundPlayers[profile] = player
                    Self.logger.info("✅ Loaded sound: \(filename)")
                } catch {
                    Self.logger.error("❌ Failed to load \(filename): \(error.localizedDescription)")
                }
            } else {
                Self.logger.warning("⚠️ Sound file not found: \(filename)")
            }
        }
    }

    // A private event source to avoid being affected by or affecting other system states.
    private let source = CGEventSource(stateID: .privateState)

    // MARK: – Public

    /// Opens the macOS emoji picker using NSApp.sendAction – more reliable
    /// than posting Cmd+Ctrl+Space via CGEvent.
    func openEmojiPicker() {
        NSApp.sendAction(#selector(NSApplication.orderFrontCharacterPalette(_:)), to: nil, from: nil)
    }

    func sendKey(keyCode: CGKeyCode, modifiers: Set<ModifierKey> = [], profile: SoundProfile? = .clicky) {
        var flags: CGEventFlags = []
        for modifier in modifiers {
            flags.insert(modifier.cgEventFlag)
        }
        
        // Post to .cghidEventTap for lowest-level injection
        postEvent(keyCode: keyCode, keyDown: true,  flags: flags)
        postEvent(keyCode: keyCode, keyDown: false, flags: flags)
        
        // Play sound if enabled
        let soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        if soundEnabled, let actualProfile = profile {
            playSound(for: actualProfile)
        }
    }
    
    private func playSound(for profile: SoundProfile) {
        if let player = soundPlayers[profile] {
            player.currentTime = 0
            player.play()
        } else {
            // Fallback to system sounds
            let soundID: SystemSoundID
            switch profile {
            case .clicky: soundID = 1104
            case .thocky: soundID = 1057
            case .futuristic: soundID = 1115
            }
            AudioServicesPlaySystemSound(soundID)
        }
    }

    // MARK: – Private

    private func postEvent(keyCode: CGKeyCode, keyDown: Bool, flags: CGEventFlags) {
        guard let event = CGEvent(
            keyboardEventSource: source,
            virtualKey: keyCode,
            keyDown: keyDown
        ) else {
            return
        }
        event.flags = flags
        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(keyCode))
        
        // .cghidEventTap is more robust for system-wide injection as it bypasses session restrictions.
        event.post(tap: .cghidEventTap)
    }
}
