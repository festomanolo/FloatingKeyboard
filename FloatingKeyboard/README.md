# FloatingKeyboard

A beautiful, resizable, auto-popping on-screen keyboard for macOS 15+ (and macOS 26 Tahoe).  
Built in **Swift 6 + SwiftUI**, with `NSPanel` for the window and the **Accessibility API** for auto-detection.

---

## Features

| Feature | Implementation |
|---|---|
| 🪟 Floating, non-focus-stealing window | `NSPanel` with `.nonactivatingPanel` |
| 🔍 Auto-show when a text field is focused | `AXUIElementCreateSystemWide()` + timer poll |
| 📐 Resizable — layout scales proportionally | `GeometryReader` flex-key math in `KeyRowView` |
| 🪟 Frosted glass background | SwiftUI `.ultraThinMaterial` |
| ⌨️ Types in any app | `CGEvent.post(tap: .cghidEventTap)` |
| 🌙 Dark / Light mode | SwiftUI adaptive colors + system materials |
| 🔢 Layout switcher (Full / Numpad) | `Picker` + `@Observable` `KeyboardViewModel` |
| 💧 Opacity slider | Top-bar `Slider` bound to `viewModel.opacity` |
| 👆 Swipe down to hide | `DragGesture` on the container view |
| 🍎 Status-bar icon | `NSStatusItem` menu |

---

## Requirements

- macOS 15 Sequoia or macOS 26 Tahoe
- Xcode 16+ (Swift 6 toolchain)
- **Accessibility permission** (prompted on first launch)
- App Sandbox **disabled** (see Entitlements section)

---

## Xcode Project Setup

### 1. Create the project

1. Open Xcode → **File › New › Project**
2. Choose **macOS › App**
3. Set **Language** to Swift, **Interface** to SwiftUI
4. Name it `FloatingKeyboard`

### 2. Add the source files

Drag all `.swift` files from this folder into your Xcode project target:

```
FloatingKeyboardApp.swift
KeyboardPanel.swift
KeyboardViewModel.swift
KeyboardView.swift
KeyEventSender.swift
AccessibilityObserver.swift
```

Delete the auto-generated `ContentView.swift` (it's replaced by `KeyboardContainerView`).

### 3. Replace Info.plist

Copy `Info.plist` to the project root and in **Build Settings → Info.plist File** point to it.  
The critical key is `NSAccessibilityUsageDescription`.

### 4. Apply Entitlements

In **Signing & Capabilities**:

- Remove the **App Sandbox** capability entirely  
  *(or set `com.apple.security.app-sandbox` to `false` in the `.entitlements` file)*
- Point **Code Signing Entitlements** at `FloatingKeyboard.entitlements`

> ⚠️ Without disabling the sandbox `CGEvent` injection and cross-process AX
> queries will silently fail.

### 5. Build & Run

`⌘R` — the app will appear in the menu bar (keyboard icon) and a floating
keyboard will slide up from the bottom of your screen.

---

## Granting Accessibility Permission

On first launch macOS prompts you automatically.  
If you dismissed the prompt:

1. **System Settings › Privacy & Security › Accessibility**
2. Click **＋** and add `FloatingKeyboard.app`
3. Toggle it **on**

---

## Architecture

```
FloatingKeyboardApp (@main)
│
├── AppDelegate (NSApplicationDelegate)
│   ├── KeyboardPanel           ← NSPanel subclass
│   │   └── KeyboardContainerView ← SwiftUI root (glass shell)
│   │       ├── FullKeyboardView   (5 key rows)
│   │       │   └── KeyRowView × 5
│   │       │       └── KeyButtonView × N
│   │       │           └── GlassKeyButtonStyle
│   │       └── NumpadView
│   │
│   ├── AccessibilityObserver   ← AX focus watcher → show/hide panel
│   └── NSStatusItem            ← menu-bar icon
│
├── KeyboardViewModel (@Observable, @MainActor)
│   └── pressCharacter / pressRaw / pressModifier
│       └── KeyEventSender.shared.sendKey(keyCode:shift:)
│           └── CGEvent.post(tap: .cghidEventTap)
```

---

## Customization

### Add more layouts

1. Add a new case to `KeyboardLayout` enum in `KeyboardViewModel.swift`
2. Create a new SwiftUI view (e.g. `FunctionRowView`)
3. Add it to the `switch` in `KeyboardContainerView.layoutContent`

### Change key colours

Edit `GlassKeyButtonStyle.keyBackground(pressed:)` in `KeyboardView.swift`.

### Change auto-popup behaviour

In `AccessibilityObserver.swift`:

- **Add roles** to `textRoles` to trigger on more element types
- **Disable auto-hide** by removing the `false` branch in `transitionIfNeeded`
- **Change poll interval** by editing the `0.4` seconds in `startPollingTimer`

### Adjust key height

Change the `.frame(height: 42)` in `KeyRowView` — the rest scales automatically.

### Keep keyboard always visible (no auto-hide)

In `AccessibilityObserver.transitionIfNeeded`, comment out the `panel?.hide()` call.

---

## Known Limitations

- **No Mac App Store distribution** – sandbox must be disabled for `CGEvent` injection.
- **Function keys (F1–F12)** are not included by default; add them to `kRow1` using
  key codes 122 (F1) through 111 (F12).
- **Emoji / IME input** is not supported; the keyboard sends raw HID key codes only.
- **Gesture typing / swipe** is not implemented; keys are discrete taps.

---

## Virtual Key Code Reference

Key codes are stable since Mac OS X 10.0 (Carbon era):

| Key | Code | | Key | Code |
|-----|------|-|-----|------|
| A | 0 | | Return | 36 |
| S | 1 | | Tab | 48 |
| D | 2 | | Space | 49 |
| Z | 6 | | Delete (⌫) | 51 |
| Q | 12 | | Escape | 53 |
| W | 13 | | Shift | 56 |
| E | 14 | | Caps Lock | 57 |
| ← | 123 | | Cmd | 55 |
| → | 124 | | Opt | 58 |
| ↓ | 125 | | Ctrl | 59 |
| ↑ | 126 | | | |

Full list: `<Carbon/Carbon.h>` → search `kVK_`

---

## License

MIT — use freely, attribution appreciated.
