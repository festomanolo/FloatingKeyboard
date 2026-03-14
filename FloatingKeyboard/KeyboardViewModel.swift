// KeyboardViewModel.swift
// FloatingKeyboard — macOS 15+ · Swift 6
//
// @Observable state shared between the KeyboardPanel and every SwiftUI key button.
// Because it is @MainActor the UI and key-event logic run on the main thread.
// ─────────────────────────────────────────────────────────────────────────────

import SwiftUI
import Observation
import AppKit
import IOKit
import IOKit.hidsystem

// MARK: – Layout mode

enum KeyboardLayout: String, CaseIterable, Identifiable {
    case full   = "Full"
    case numpad = "Numpad"
    var id: String { rawValue }
}

// MARK: - Core Data Models

enum ModifierKey: String, CaseIterable, Identifiable {
    case shift = "Shift"
    case control = "Control"
    case option = "Option"
    case command = "Command"
    
    var id: String { rawValue }
    
    var cgEventFlag: CGEventFlags {
        switch self {
        case .shift: return .maskShift
        case .control: return .maskControl
        case .option: return .maskAlternate
        case .command: return .maskCommand
        }
    }
}

enum KeyboardTheme: String, CaseIterable, Identifiable {
    case glass = "Glass"
    case dark = "Dark"
    case light = "Light"
    case manolo = "Manolo"
    case neon = "Neon"
    case fire = "Fire"
    case thunder = "Thunder"
    
    var id: String { rawValue }
    
    var keyBackground: Color? {
        switch self {
        case .glass: return Color.white.opacity(0.15)
        case .dark: return Color(white: 0.15)
        case .light: return Color.white
        case .manolo: return Color.clear
        case .neon: return Color.black.opacity(0.85)
        case .fire: return Color(red: 0.25, green: 0.05, blue: 0).opacity(0.8)
        case .thunder: return Color(red: 0.05, green: 0.05, blue: 0.15).opacity(0.8)
        }
    }
    
    var keyForeground: Color {
        switch self {
        case .glass, .dark: return .white
        case .light: return .black
        case .manolo: return .primary
        case .neon: return Color(red: 0, green: 1, blue: 1) // Vibrant cyan
        case .fire: return Color(red: 1, green: 0.8, blue: 0) // Vibrant gold
        case .thunder: return Color(red: 0.9, green: 0.9, blue: 1) // Off-white/blue
        }
    }
    
    var textShadow: Bool {
        switch self {
        case .dark, .neon, .fire, .thunder, .glass: return true
        default: return false
        }
    }
    
    var adaptiveForeground: Color {
        if self == .dark || self == .neon || self == .fire || self == .thunder {
            return .white
        }
        return .primary
    }
    
    var adaptiveSecondaryForeground: Color {
        if self == .dark || self == .neon || self == .fire || self == .thunder {
            return .white.opacity(0.7)
        }
        return .secondary
    }
    
    var borderStyle: Bool {
        return self == .manolo
    }
}

enum SoundProfile: String, CaseIterable, Identifiable {
    case clicky = "Clicky (Blue)"
    case thocky = "Thocky (Cream)"
    case futuristic = "Futuristic"
    
    var id: String { rawValue }
}

extension UserDefaults {
    enum Keys {
        static let layout = "keyboardLayout"
        static let opacity = "keyboardOpacity"
        static let theme = "keyboardTheme"
        static let soundEnabled = "soundEnabled"
        static let soundProfile = "selectedSoundProfile"
        static let excludedApps = "excludedApps"
        static let autoShowEnabled = "autoShowEnabled"
        static let isTabletModeEnabled = "isTabletModeEnabled"
        static let isInternalKeyboardDisabled = "isInternalKeyboardDisabled"
    }
}

let alternateCharacters: [String: [String]] = [
    "a": ["á", "à", "ä", "â", "ã", "å"],
    "e": ["é", "è", "ë", "ê"],
    "i": ["í", "ì", "ï", "î"],
    "o": ["ó", "ò", "ö", "ô", "õ"],
    "u": ["ú", "ù", "ü", "û"],
    "c": ["ç", "ć", "č"],
    "n": ["ñ", "ń"],
    "s": ["ß", "ś", "š"],
    "y": ["ÿ", "ý"],
    "z": ["ž", "ź", "ż"]
]

struct ClipboardItem: Codable, Identifiable, Equatable {
    let id: UUID
    let content: String
    var isPinned: Bool
    let timestamp: Date
    let sourceApp: String?
    let sourceBundleId: String?
    
    init(content: String, isPinned: Bool = false, sourceApp: String? = nil, sourceBundleId: String? = nil) {
        self.id = UUID()
        self.content = content
        self.isPinned = isPinned
        self.timestamp = Date()
        self.sourceApp = sourceApp
        self.sourceBundleId = sourceBundleId
    }
}


// MARK: – ViewModel

@Observable
@MainActor
final class KeyboardViewModel {

    // ── Init ────────────────────────────────────────────────────────────────
    init() {
        loadPreferences()
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCapsLockState()
            }
        }
    }

    // ── UI state ────────────────────────────────────────────────────────────
    
    var layout: KeyboardLayout = .full {
        didSet { UserDefaults.standard.set(layout.rawValue, forKey: UserDefaults.Keys.layout) }
    }
    
    var theme: KeyboardTheme = .glass {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: UserDefaults.Keys.theme) }
    }
    
    var soundEnabled: Bool = true {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: UserDefaults.Keys.soundEnabled) }
    }
    
    var selectedSoundProfile: SoundProfile = .clicky {
        didSet { UserDefaults.standard.set(selectedSoundProfile.rawValue, forKey: UserDefaults.Keys.soundProfile) }
    }
    
    var heldModifiers: Set<ModifierKey> = []
    var isCapsLockActive: Bool = false
    
    var excludedApps: Set<String> = []
    
    var isLightningActive: Bool = false
    var shockwaveOrigin: CGPoint = .zero
    var shockwaveActive: Bool = false
    var shockwaveStartTime: Double = 0
    
    /// Window opacity controlled by the top-bar slider.
    var opacity: Double = 0.92 {
        didSet { debouncedSaveOpacity() }
    }
    
    var isAutoShowEnabled: Bool = true {
        didSet { UserDefaults.standard.set(isAutoShowEnabled, forKey: UserDefaults.Keys.autoShowEnabled) }
    }
    
    var isTabletModeEnabled: Bool = false {
        didSet { 
            UserDefaults.standard.set(isTabletModeEnabled, forKey: UserDefaults.Keys.isTabletModeEnabled) 
            if isTabletModeEnabled {
                isAutoShowEnabled = true // Force auto-show on when Tablet mode is enabled
                setSystemDockAutoHide(true) // Auto-hide dock in tablet mode
            }
            NotificationCenter.default.post(name: NSNotification.Name("TabletModeToggled"), object: nil)
        }
    }

    var isInternalKeyboardDisabled: Bool = false {
        didSet { 
            UserDefaults.standard.set(isInternalKeyboardDisabled, forKey: UserDefaults.Keys.isInternalKeyboardDisabled)
            NotificationCenter.default.post(name: NSNotification.Name("InternalKeyboardToggleChanged"), object: nil)
        }
    }

    var isSettingsVisible: Bool = false {
        didSet {
            if isSettingsVisible {
                isClipboardVisible = false
                isAboutVisible = false
            }
        }
    }
    
    var isClipboardVisible: Bool = false {
        didSet {
            if isClipboardVisible {
                isSettingsVisible = false
                isAboutVisible = false
            }
        }
    }
    
    var isAboutVisible: Bool = false {
        didSet {
            if isAboutVisible {
                isSettingsVisible = false
                isClipboardVisible = false
            }
        }
    }
    
    func triggerShockwave(at location: CGPoint) {
        shockwaveOrigin = location
        shockwaveActive = true
        // Set exactly to slightly in the past just to make it instantly visible or use now
        shockwaveStartTime = Date().timeIntervalSinceReferenceDate
        
        // Reset state after a sufficient simulation time (matched to 1.8s animation + buffer)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.shockwaveActive = false
        }
    }
    
    var clipboardItems: [ClipboardItem] = [] {
        didSet { saveClipboardItems() }
    }
    
    private var opacitySaveWorkItem: DispatchWorkItem?

    // ── Preferences Management ──────────────────────────────────────────────
    
    func loadPreferences() {
        if let layoutString = UserDefaults.standard.string(forKey: UserDefaults.Keys.layout),
           let savedLayout = KeyboardLayout(rawValue: layoutString) {
            layout = savedLayout
        }
        
        if let themeString = UserDefaults.standard.string(forKey: UserDefaults.Keys.theme),
           let savedTheme = KeyboardTheme(rawValue: themeString) {
            theme = savedTheme
        }
        
        if UserDefaults.standard.object(forKey: UserDefaults.Keys.soundEnabled) != nil {
            soundEnabled = UserDefaults.standard.bool(forKey: UserDefaults.Keys.soundEnabled)
        }
        
        if let soundProfileString = UserDefaults.standard.string(forKey: UserDefaults.Keys.soundProfile),
           let savedProfile = SoundProfile(rawValue: soundProfileString) {
            selectedSoundProfile = savedProfile
        }
        
        if UserDefaults.standard.object(forKey: UserDefaults.Keys.opacity) != nil {
            opacity = UserDefaults.standard.double(forKey: UserDefaults.Keys.opacity)
        }
        
        if UserDefaults.standard.object(forKey: UserDefaults.Keys.autoShowEnabled) != nil {
            isAutoShowEnabled = UserDefaults.standard.bool(forKey: UserDefaults.Keys.autoShowEnabled)
        }
        
        if UserDefaults.standard.object(forKey: UserDefaults.Keys.isTabletModeEnabled) != nil {
            isTabletModeEnabled = UserDefaults.standard.bool(forKey: UserDefaults.Keys.isTabletModeEnabled)
        }

        if UserDefaults.standard.object(forKey: UserDefaults.Keys.isInternalKeyboardDisabled) != nil {
            isInternalKeyboardDisabled = UserDefaults.standard.bool(forKey: UserDefaults.Keys.isInternalKeyboardDisabled)
        }
        
        loadExcludedApps()
        loadClipboardItems()
    }
    
    private func debouncedSaveOpacity() {
        opacitySaveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            UserDefaults.standard.set(self.opacity, forKey: UserDefaults.Keys.opacity)
        }
        opacitySaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    private func loadExcludedApps() {
        if let array = UserDefaults.standard.stringArray(forKey: UserDefaults.Keys.excludedApps) {
            excludedApps = Set(array)
        }
    }

    private func saveExcludedApps() {
        UserDefaults.standard.set(Array(excludedApps), forKey: UserDefaults.Keys.excludedApps)
    }

    func addExcludedApp(_ bundleId: String) {
        excludedApps.insert(bundleId)
        saveExcludedApps()
    }

    func removeExcludedApp(_ bundleId: String) {
        excludedApps.remove(bundleId)
        saveExcludedApps()
    }

    // ── Clipboard Management ────────────────────────────────────────────────
    
    private func loadClipboardItems() {
        if let data = UserDefaults.standard.data(forKey: "clipboardItems"),
           let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            clipboardItems = items
        }
    }
    
    private func saveClipboardItems() {
        if let data = try? JSONEncoder().encode(clipboardItems) {
            UserDefaults.standard.set(data, forKey: "clipboardItems")
        }
    }
    
    func addClipboardContent(_ content: String, sourceApp: String? = nil, sourceBundleId: String? = nil) {
        // If it's already there (unpinned), move to top. If pinned, leave it.
        if let index = clipboardItems.firstIndex(where: { $0.content == content }) {
            if !clipboardItems[index].isPinned {
                let item = clipboardItems.remove(at: index)
                clipboardItems.insert(item, at: 0)
            }
            return
        }
        
        let newItem = ClipboardItem(content: content, sourceApp: sourceApp, sourceBundleId: sourceBundleId)
        // Insert after pinned items
        let firstUnpinnedIndex = clipboardItems.firstIndex(where: { !$0.isPinned }) ?? clipboardItems.count
        clipboardItems.insert(newItem, at: firstUnpinnedIndex)
        
        // Keep max 25 items
        if clipboardItems.count > 25 {
            clipboardItems.removeLast()
        }
    }
    
    func togglePin(item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems[index].isPinned.toggle()
            // Re-sort: pinned items at top
            clipboardItems.sort { (a, b) -> Bool in
                if a.isPinned != b.isPinned {
                    return a.isPinned
                }
                return a.timestamp > b.timestamp
            }
        }
    }
    
    func removeClipboardItem(item: ClipboardItem) {
        clipboardItems.removeAll(where: { $0.id == item.id })
    }

    // ── Derived ─────────────────────────────────────────────────────────────
    var isUpperCase: Bool { heldModifiers.contains(.shift) || isCapsLockActive }

    // ── Modifier toggles ────────────────────────────────────────────────────

    func toggleModifier(_ modifier: ModifierKey) {
        if heldModifiers.contains(modifier) {
            heldModifiers.remove(modifier)
        } else {
            heldModifiers.insert(modifier)
        }
    }

    func toggleCapsLock() {
        toggleSystemCapsLock()
        // No need to manually toggle isCapsLockActive here; updateCapsLockState() 
        // will detect the CGEvent we just posted via the system's flags state.
    }

    func updateCapsLockState() {
        let isSysCapsActive = NSEvent.modifierFlags.contains(.capsLock)
        if isCapsLockActive != isSysCapsActive {
            isCapsLockActive = isSysCapsActive
        }
    }

    private func toggleSystemCapsLock() {
        // CGEvent posted with .cghidEventTap for key code 57 correctly toggles the Caps Lock hardware state
        KeyEventSender.shared.sendKey(keyCode: 57, modifiers: [], profile: selectedSoundProfile)
    }

    func shouldAutoReleaseModifier(_ modifier: ModifierKey) -> Bool {
        return modifier == .shift && !isCapsLockActive
    }

    // ── Key press actions ───────────────────────────────────────────────────

    /// Press a character key, applying the current shift/caps-lock state.
    /// One-shot shift: Shift releases automatically after each character
    /// (unless Caps Lock is also on).
    func pressCharacter(keyCode: CGKeyCode) {
        KeyEventSender.shared.sendKey(
            keyCode: keyCode,
            modifiers: isCapsLockActive ? heldModifiers.union([.shift]) : heldModifiers,
            profile: selectedSoundProfile
        )
        if shouldAutoReleaseModifier(.shift) {
            heldModifiers.remove(.shift)
        }
    }

    /// Press a key with no modifier (backspace, enter, tab, arrows, etc.).
    func pressRaw(keyCode: CGKeyCode) {
        KeyEventSender.shared.sendKey(keyCode: keyCode, modifiers: heldModifiers, profile: selectedSoundProfile)
    }

    /// Press a modifier key tap (Cmd, Opt, Ctrl) — stateless, no toggle.
    func pressModifier(keyCode: CGKeyCode) {
        KeyEventSender.shared.sendKey(keyCode: keyCode, modifiers: heldModifiers, profile: selectedSoundProfile)
    }
    
    // ── System Utilities ────────────────────────────────────────────────────
    
    func toggleSystemDock() {
        let script = "tell application \"System Events\" to set autohide of dock preferences to not (autohide of dock preferences)"
        _ = runShellCommand("/usr/bin/osascript", arguments: ["-e", script])
    }
    
    func setSystemDockAutoHide(_ enabled: Bool) {
        let script = "tell application \"System Events\" to set autohide of dock preferences to \(enabled)"
        _ = runShellCommand("/usr/bin/osascript", arguments: ["-e", script])
    }
    
    @discardableResult
    func runAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil {
                return output.stringValue
            }
        }
        return nil
    }

    @discardableResult
    func runShellCommand(_ command: String, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    // MARK: – Native Brightness Control
    
    func setBrightness(_ level: Float) {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)
        
        if result == kIOReturnSuccess {
            var service = IOIteratorNext(iterator)
            while service != 0 {
                IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, level)
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
    }
    
    func getBrightness() -> Float {
        var level: Float = 0.7
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)
        
        if result == kIOReturnSuccess {
            let service = IOIteratorNext(iterator)
            if service != 0 {
                IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &level)
                IOObjectRelease(service)
            }
            IOObjectRelease(iterator)
        }
        return level
    }
}
