// KeyEventSender.swift
// FloatingKeyboard — macOS 15+ · Swift 6
//
// Posts CGEvent key presses to the HID event stream so they reach
// whichever app currently has keyboard focus — Chrome, Notes, Terminal, etc.
//
// Includes a low-latency polyphonic mechanical keyboard audio engine
// with realistic switch profiles (Thocky Holy Panda, Clicky Blue, Tactile Brown).
// ─────────────────────────────────────────────────────────────────────────────

import CoreGraphics
import Foundation
import AppKit
import AVFoundation
import AudioToolbox
import os.log

// MARK: – Mechanical Sound Engine

@MainActor
final class MechanicalSoundEngine {
    static let shared = MechanicalSoundEngine()
    
    private static let logger = Logger(subsystem: "manolo.FloatingKeyboard", category: "MechanicalSoundEngine")
    
    // Multi-tier audio engines for 100% reliable audio output
    private var nsSoundPool: [String: [NSSound]] = [:]
    private var systemSoundIDs: [String: SystemSoundID] = [:]
    private var playerPool: [AVAudioPlayer] = []
    private let poolSize = 18
    private var poolIndex = 0
    
    // Cached sound data by sound key
    private var soundDataCache: [String: Data] = [:]
    
    private init() {
        loadAllSounds()
    }
    
    private func loadAllSounds() {
        let filenames: [String] = [
            // Thocky (Holy Panda / NK Cream)
            "thock_0.mp3", "thock_1.mp3", "thock_2.mp3", "thock_3.mp3", "thock_4.mp3", "thock_space.mp3", "thocky.wav",
            // Clicky (Cherry MX Blue)
            "clicky_0.mp3", "clicky_1.mp3", "clicky_2.mp3", "clicky_3.mp3", "clicky_4.mp3", "clicky.wav",
            // Tactile (Cherry MX Brown)
            "tactile_0.mp3", "tactile_1.mp3", "tactile_2.mp3", "tactile_3.mp3", "tactile_4.mp3",
            "tactile_enter.mp3", "tactile_backspace.mp3",
            // Futuristic
            "futuristic.wav"
        ]
        
        for name in filenames {
            let parts = name.split(separator: ".")
            guard parts.count == 2 else { continue }
            let base = String(parts[0])
            let ext = String(parts[1])
            
            if let url = findAudioURL(name: base, ext: ext) {
                // 1. Register SystemSoundID (ultra-low latency CoreAudio)
                var sID: SystemSoundID = 0
                if AudioServicesCreateSystemSoundID(url as CFURL, &sID) == noErr {
                    systemSoundIDs[name] = sID
                }
                
                // 2. Pre-create a pool of NSSounds for this sound key
                var soundsForKey: [NSSound] = []
                for _ in 0..<5 {
                    if let sound = NSSound(contentsOf: url, byReference: true) {
                        soundsForKey.append(sound)
                    }
                }
                if !soundsForKey.isEmpty {
                    nsSoundPool[name] = soundsForKey
                }
                
                // 3. Cache raw Data for AVAudioPlayer
                if let data = try? Data(contentsOf: url) {
                    soundDataCache[name] = data
                }
            }
        }
        
        Self.logger.info("Initialized MechanicalSoundEngine with \(self.systemSoundIDs.count) system sounds and \(self.nsSoundPool.count) NSSound pools")
    }
    
    private func findAudioURL(name: String, ext: String) -> URL? {
        // 1. Root of app bundle resources
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        // 2. Sounds subfolder in bundle
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Sounds") {
            return url
        }
        // 3. Project file direct fallback (for local development/testing)
        let localPaths = [
            "/Users/festomanolo/Desktop/projects/Floatingkeyboard/FloatingKeyboard/FloatingKeyboard/Sounds/\(name).\(ext)",
            "/Users/festomanolo/Desktop/projects/Floatingkeyboard/FloatingKeyboard/FloatingKeyboard/FloatingKeyboard/Sounds/\(name).\(ext)"
        ]
        for path in localPaths {
            let fileURL = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
        }
        return nil
    }
    
    func playKeystroke(keyCode: CGKeyCode, profile: SoundProfile, userVolume: Double = 0.85) {
        let soundKey: String
        
        switch profile {
        case .thocky:
            if keyCode == 49 { // Spacebar
                soundKey = "thock_space.mp3"
            } else {
                let index = Int.random(in: 0...4)
                soundKey = "thock_\(index).mp3"
            }
            
        case .clicky:
            if keyCode == 49 { // Spacebar
                soundKey = soundDataCache["clicky_0.mp3"] != nil ? "clicky_0.mp3" : "clicky.wav"
            } else {
                let index = Int.random(in: 0...4)
                soundKey = "clicky_\(index).mp3"
            }
            
        case .tactile:
            if keyCode == 49 { // Spacebar
                soundKey = soundDataCache["tactile_0.mp3"] != nil ? "tactile_0.mp3" : "tactile_1.mp3"
            } else if keyCode == 36 || keyCode == 76 { // Enter
                soundKey = "tactile_enter.mp3"
            } else if keyCode == 51 { // Backspace
                soundKey = "tactile_backspace.mp3"
            } else {
                let index = Int.random(in: 0...4)
                soundKey = "tactile_\(index).mp3"
            }
            
        case .futuristic:
            soundKey = "futuristic.wav"
        }
        
        let targetVolume = Float(max(0.15, min(1.0, userVolume)))
        
        // Priority 1: Native AppKit NSSound (respects volume and zero latency)
        if let soundList = nsSoundPool[soundKey] ?? nsSoundPool.values.first, !soundList.isEmpty {
            let sound = soundList[poolIndex % soundList.count]
            sound.volume = targetVolume
            if sound.isPlaying {
                sound.stop()
                sound.currentTime = 0
            }
            if sound.play() {
                poolIndex = (poolIndex + 1) % 1000
                return
            }
        }
        
        // Priority 2: SystemSoundID (CoreAudio guaranteed playback)
        if let sID = systemSoundIDs[soundKey] ?? systemSoundIDs.values.first {
            AudioServicesPlaySystemSound(sID)
            poolIndex = (poolIndex + 1) % 1000
            return
        }
        
        // Priority 3: AVAudioPlayer from memory data
        if let data = soundDataCache[soundKey] ?? soundDataCache.values.first {
            if let player = try? AVAudioPlayer(data: data) {
                player.volume = targetVolume
                player.prepareToPlay()
                player.play()
                if playerPool.count < poolSize {
                    playerPool.append(player)
                } else {
                    playerPool[poolIndex % poolSize] = player
                }
                poolIndex = (poolIndex + 1) % 1000
                return
            }
        }
        
        // Priority 4: Ultimate fail-safe system click
        AudioServicesPlaySystemSound(1104)
    }
}

// MARK: – KeyEventSender

@MainActor
final class KeyEventSender {

    /// Shared singleton – one CGEventSource is reused for all key events.
    static let shared = KeyEventSender()
    
    private let soundEngine = MechanicalSoundEngine.shared
    private static let logger = Logger(subsystem: "manolo.FloatingKeyboard", category: "KeyEventSender")

    // A private event source to avoid being affected by or affecting other system states.
    private let source = CGEventSource(stateID: .privateState)

    private init() {}

    // MARK: – Public

    /// Plays tactile mechanical switch sound for any UI button interaction (tabs, presets, actions, etc.)
    func playClickSound(profile: SoundProfile? = nil, volume: Double? = nil) {
        let soundEnabled: Bool
        if let val = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool {
            soundEnabled = val
        } else if let num = UserDefaults.standard.object(forKey: "soundEnabled") as? NSNumber {
            soundEnabled = num.boolValue
        } else {
            soundEnabled = true
        }
        guard soundEnabled else { return }
        
        let prof: SoundProfile
        if let explicit = profile {
            prof = explicit
        } else if let saved = UserDefaults.standard.string(forKey: UserDefaults.Keys.soundProfile),
                  let p = SoundProfile(rawValue: saved) {
            prof = p
        } else {
            prof = .clicky
        }
        
        let vol = volume ?? (UserDefaults.standard.object(forKey: "soundVolume") as? Double ?? 0.85)
        soundEngine.playKeystroke(keyCode: 0xFFFF, profile: prof, userVolume: vol)
    }

    /// Opens the macOS emoji picker using NSApp.sendAction – more reliable
    /// than posting Cmd+Ctrl+Space via CGEvent.
    func openEmojiPicker() {
        playClickSound()
        NSApp.sendAction(#selector(NSApplication.orderFrontCharacterPalette(_:)), to: nil, from: nil)
    }

    /// Sends a keyboard press with active modifier flags.
    /// Handles sticky and combined shortcuts (Cmd+C, Cmd+V, Cmd+Shift+4, Ctrl+C, etc.)
    func sendKey(
        keyCode: CGKeyCode,
        modifiers: Set<ModifierKey> = [],
        profile: SoundProfile? = .thocky,
        userVolume: Double = 0.8
    ) {
        var flags: CGEventFlags = []
        for modifier in modifiers {
            flags.insert(modifier.cgEventFlag)
        }
        
        // If modifiers are active, broadcast flagsChanged first so target application
        // updates its modifier state before processing the key down event.
        if !flags.isEmpty {
            let flagsEvent = CGEvent(source: source)
            flagsEvent?.type = .flagsChanged
            flagsEvent?.flags = flags
            flagsEvent?.post(tap: .cghidEventTap)
        }
        
        // Post keyDown and keyUp with exact modifier flags
        postEvent(keyCode: keyCode, keyDown: true,  flags: flags)
        postEvent(keyCode: keyCode, keyDown: false, flags: flags)
        
        // Clear flagsChanged after keyUp if modifiers were armed, ensuring system-level state resets cleanly
        if !flags.isEmpty {
            let clearFlagsEvent = CGEvent(source: source)
            clearFlagsEvent?.type = .flagsChanged
            clearFlagsEvent?.flags = []
            clearFlagsEvent?.post(tap: .cghidEventTap)
        }
        
        // Play mechanical switch sound
        let soundEnabled: Bool
        if let val = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool {
            soundEnabled = val
        } else if let num = UserDefaults.standard.object(forKey: "soundEnabled") as? NSNumber {
            soundEnabled = num.boolValue
        } else {
            soundEnabled = true
        }
        
        if soundEnabled, let actualProfile = profile {
            soundEngine.playKeystroke(keyCode: keyCode, profile: actualProfile, userVolume: userVolume)
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
        
        // .cghidEventTap is most robust for system-wide injection across all apps
        event.post(tap: .cghidEventTap)
    }
}
