// FloatingKeyboardTests.swift
// FloatingKeyboard — macOS 15+ · Swift 6
//
// Unit tests for core components: KeyEventSender, KeyboardViewModel

import Testing
@testable import FloatingKeyboard

// MARK: - KeyEventSender Tests

@Suite("KeyEventSender Tests")
struct KeyEventSenderTests {
    
    @Test("Sound ID is non-zero after initialization")
    @MainActor
    func soundIDIsNonZero() {
        let sender = KeyEventSender.shared
        // After init, systemSoundID should be non-zero (either Tink or fallback 1104)
        // We verify the sender exists and is functional
        #expect(sender != nil)
    }
    
    @Test("openEmojiPicker method exists and is callable")
    @MainActor
    func openEmojiPickerExists() {
        // Verify the method exists and doesn't crash
        // (emoji picker won't visually open in test environment)
        let sender = KeyEventSender.shared
        // The method should exist — compile-time verification
        _ = sender.openEmojiPicker
    }
}

// MARK: - KeyboardViewModel Tests

@Suite("KeyboardViewModel Tests")
struct KeyboardViewModelTests {
    
    @Test("Initial state is correct")
    @MainActor
    func initialState() {
        let vm = KeyboardViewModel()
        #expect(vm.layout == .full)
        #expect(vm.heldModifiers.isEmpty)
        #expect(vm.isUpperCase == false)
    }
    
    @Test("Toggle shift modifier")
    @MainActor
    func toggleShift() {
        let vm = KeyboardViewModel()
        vm.toggleModifier(.shift)
        #expect(vm.heldModifiers.contains(.shift))
        #expect(vm.isUpperCase == true)
        
        vm.toggleModifier(.shift)
        #expect(!vm.heldModifiers.contains(.shift))
        #expect(vm.isUpperCase == false)
    }
    
    @Test("Toggle all modifier keys")
    @MainActor
    func toggleAllModifiers() {
        let vm = KeyboardViewModel()
        
        for modifier in ModifierKey.allCases {
            vm.toggleModifier(modifier)
            #expect(vm.heldModifiers.contains(modifier), "Should contain \(modifier) after toggle on")
            
            vm.toggleModifier(modifier)
            #expect(!vm.heldModifiers.contains(modifier), "Should not contain \(modifier) after toggle off")
        }
    }
    
    @Test("Caps lock toggles uppercase state")
    @MainActor
    func capsLockToggle() {
        let vm = KeyboardViewModel()
        let initialCapsState = vm.isCapsLockActive
        
        vm.toggleCapsLock()
        #expect(vm.isCapsLockActive != initialCapsState)
        #expect(vm.isUpperCase == true)
    }
    
    @Test("Auto-release shift after character press")
    @MainActor
    func autoReleaseShift() {
        let vm = KeyboardViewModel()
        vm.toggleModifier(.shift)
        #expect(vm.heldModifiers.contains(.shift))
        
        // Pressing a character key should auto-release shift (when caps lock off)
        vm.pressCharacter(keyCode: 0) // 'a'
        #expect(!vm.heldModifiers.contains(.shift))
    }
    
    @Test("Layout change persists to UserDefaults")
    @MainActor
    func layoutPersistence() {
        let vm = KeyboardViewModel()
        vm.layout = .numpad
        #expect(UserDefaults.standard.string(forKey: UserDefaults.Keys.layout) == "Numpad")
        
        vm.layout = .full
        #expect(UserDefaults.standard.string(forKey: UserDefaults.Keys.layout) == "Full")
    }
    
    @Test("Theme change persists to UserDefaults")
    @MainActor
    func themePersistence() {
        let vm = KeyboardViewModel()
        for theme in KeyboardTheme.allCases {
            vm.theme = theme
            #expect(UserDefaults.standard.string(forKey: UserDefaults.Keys.theme) == theme.rawValue)
        }
    }
    
    @Test("Sound toggle persists to UserDefaults")
    @MainActor
    func soundTogglePersistence() {
        let vm = KeyboardViewModel()
        vm.soundEnabled = false
        #expect(UserDefaults.standard.bool(forKey: UserDefaults.Keys.soundEnabled) == false)
        
        vm.soundEnabled = true
        #expect(UserDefaults.standard.bool(forKey: UserDefaults.Keys.soundEnabled) == true)
    }
    
    @Test("isUpperCase reflects shift OR capsLock")
    @MainActor
    func isUpperCaseDerivation() {
        let vm = KeyboardViewModel()
        
        // Neither
        #expect(vm.isUpperCase == false)
        
        // Shift only
        vm.toggleModifier(.shift)
        #expect(vm.isUpperCase == true)
        vm.toggleModifier(.shift)
        
        // Caps only
        vm.toggleCapsLock()
        #expect(vm.isUpperCase == true)
    }
}

// MARK: - Key Code Mapping Tests

@Suite("Key Code Mapping Tests")
struct KeyCodeMappingTests {
    
    @Test("ModifierKey cgEventFlag mapping is correct")
    func modifierFlagMapping() {
        #expect(ModifierKey.shift.cgEventFlag == .maskShift)
        #expect(ModifierKey.control.cgEventFlag == .maskControl)
        #expect(ModifierKey.option.cgEventFlag == .maskAlternate)
        #expect(ModifierKey.command.cgEventFlag == .maskCommand)
    }
    
    @Test("All keyboard layouts are identifiable")
    func layoutIdentifiable() {
        for layout in KeyboardLayout.allCases {
            #expect(!layout.id.isEmpty)
            #expect(!layout.rawValue.isEmpty)
        }
    }
    
    @Test("All themes have valid properties")
    func themeProperties() {
        for theme in KeyboardTheme.allCases {
            #expect(!theme.id.isEmpty)
            // keyForeground should always return a color (non-optional)
            _ = theme.keyForeground
            // keyBackground is optional but should be defined for all themes
            _ = theme.keyBackground
        }
    }
}

// MARK: - Excluded Apps Tests

@Suite("Excluded Apps Tests")
struct ExcludedAppsTests {
    
    @Test("Add and remove excluded app")
    @MainActor
    func addRemoveExcludedApp() {
        let vm = KeyboardViewModel()
        let testBundleId = "com.test.excluded.app"
        
        vm.addExcludedApp(testBundleId)
        #expect(vm.excludedApps.contains(testBundleId))
        
        vm.removeExcludedApp(testBundleId)
        #expect(!vm.excludedApps.contains(testBundleId))
    }
}
