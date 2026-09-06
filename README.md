# FloatingKeyboard v2.0.0

A floating, customizable on-screen keyboard for macOS with advanced features and beautiful glass design.

## Features

### Core Features
- 🎹 **Full QWERTY keyboard** with function keys and numpad layout
- 🪟 **Floating glass panel** with customizable opacity
- 🎨 **Multiple themes**: Glass, Neon, Fire, Thunder, Manolo
- 🔊 **Sound profiles**: Clicky, Thocky, Futuristic
- 📋 **Clipboard history** with search and management
- ⚙️ **Extensive settings** for customization

### v2.0.0 New Features
- 🔄 **Display rotation button** (works on supported external displays)
- 📏 **Improved ergonomics**: 26% taller keys, better spacing
- 🔤 **Larger fonts**: More readable key labels
- 🎵 **Fixed sound system**: All sound profiles working
- ✨ **Smoother animations**: Spring-based key presses

### System Integration
- 🖱️ **Auto-show** in text fields (optional)
- 💻 **Tablet mode** with bottom dock positioning
- 🎛️ **System controls**: Volume, brightness, dock toggle
- ⌨️ **Internal keyboard suppression** (optional)
- ♿ **Accessibility support** required for key events

## Installation

1. **Download** the DMG file
2. **Open** the DMG
3. **Drag** FloatingKeyboard.app to Applications folder
4. **Launch** the app
5. **Grant Accessibility permissions** when prompted:
   - System Settings → Privacy & Security → Accessibility
   - Enable FloatingKeyboard

## Usage

### Show/Hide Keyboard
- Click the **keyboard icon** (⌨️) in the menu bar
- Select "Show Keyboard" or "Hide Keyboard"
- Or swipe down on the keyboard to hide

### Keyboard Layouts
- **Full**: Complete QWERTY layout with all keys
- **Numpad**: Compact numeric keypad

### Display Rotation
- Click the **🔄 button** on the bottom row (between ⌘ and 😊)
- Rotates display 180° (works on supported displays)
- **Note**: Internal laptop displays typically don't support rotation
- External monitors with rotation capability work best

### Themes
Choose from 5 beautiful themes:
- **Glass**: Classic frosted glass (default)
- **Neon**: Cyberpunk neon glow
- **Fire**: Animated flames
- **Thunder**: Lightning and rain effects
- **Manolo**: Special shockwave effects

### Sound Profiles
- **Clicky**: Sharp, tactile clicks
- **Thocky**: Deep, satisfying thocks
- **Futuristic**: Sci-fi beeps and boops
- **Silent**: No sound

### Clipboard History
- Access via the clipboard icon in the toolbar
- Stores last 50 clipboard items
- Search and filter
- Click to paste any item

## Keyboard Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  F1   F2   F3   F4   F5   F6   F7   F8   F9   F10  F11  F12    │
├─────────────────────────────────────────────────────────────────┤
│  `  1  2  3  4  5  6  7  8  9  0  -  =  [backspace]            │
├─────────────────────────────────────────────────────────────────┤
│  [tab]  Q  W  E  R  T  Y  U  I  O  P  [  ]  \                  │
├─────────────────────────────────────────────────────────────────┤
│  [caps]  A  S  D  F  G  H  J  K  L  ;  '  [return]             │
├─────────────────────────────────────────────────────────────────┤
│  [shift]  Z  X  C  V  B  N  M  ,  .  /  [shift]                │
├─────────────────────────────────────────────────────────────────┤
│  [esc] [ctrl] [opt] [⌘] [space] [⌘] [🔄] [😊] [←] [↓] [↑] [→]  │
└─────────────────────────────────────────────────────────────────┘
```

**Special buttons on bottom row:**
- 🔄 = Display rotation (180°)
- 😊 = Emoji picker

## Settings

Access settings via the gear icon (⚙️) in the toolbar:

- **Theme**: Choose visual style
- **Sound Profile**: Select keyboard sounds
- **Opacity**: Adjust transparency (25-100%)
- **Auto-Show**: Show keyboard in text fields
- **Tablet Mode**: Position at bottom of screen
- **Suppress Internal Keyboard**: Disable built-in keyboard

## System Requirements

- macOS 15.0 or later
- Apple Silicon or Intel Mac
- Accessibility permissions required

## Display Rotation Notes

The display rotation feature uses the same method as the proven fb-rotate utility:
- ✅ Works on external displays that support rotation
- ✅ 180° rotation is most reliable
- ❌ Internal laptop displays typically don't support rotation (hardware limitation)
- ❌ Some monitors don't expose rotation APIs

This is a hardware/driver limitation, not a software issue. If your display doesn't support rotation through System Settings → Displays → Rotation, it won't work programmatically either.

## Troubleshooting

### Keyboard doesn't show
- Check the menu bar icon and click "Show Keyboard"
- The keyboard may be off-screen - try moving your mouse around

### Keys don't work
- Grant Accessibility permissions in System Settings
- Restart the app after granting permissions

### Sounds don't play
- Check sound profile is not set to "Silent"
- Adjust system volume
- Check app isn't muted in Sound settings

### Rotation doesn't work
- This is normal for internal laptop displays
- Try with an external monitor that supports rotation
- Check System Settings → Displays to see if rotation is available

## Building from Source

Requirements:
- Xcode 15.0 or later
- macOS 15.0 SDK

```bash
# Clone the repository
git clone <repository-url>
cd FloatingKeyboard

# Open in Xcode
open FloatingKeyboard.xcodeproj

# Build and run
# Product → Run (⌘R)
```

## Technical Details

### Architecture
- **Language**: Swift 6
- **UI Framework**: SwiftUI
- **Minimum Target**: macOS 15.0
- **Key Events**: CGEvent API
- **Display Rotation**: IOKit + CoreGraphics APIs

### Key Components
- `FloatingKeyboardApp.swift`: App entry point and delegate
- `KeyboardView.swift`: Main keyboard UI and layout
- `KeyboardViewModel.swift`: State management
- `KeyEventSender.swift`: Key event generation and sounds
- `DisplayRotationManager.swift`: Display rotation logic
- `ClipboardService.swift`: Clipboard monitoring
- `KeyboardSuppressor.swift`: Internal keyboard suppression

## Version History

### v2.0.0 (2026-04-01)
- Added display rotation button (🔄)
- Improved ergonomics: 26% taller keys
- Increased spacing: +20% horizontal, +50% vertical
- Larger fonts: 11-24pt (up from 9-22pt)
- Fixed sound system with better path detection
- Enhanced error messages for rotation
- Smoother spring-based animations

### v1.0.0
- Initial release
- Full QWERTY keyboard
- Multiple themes
- Sound profiles
- Clipboard history
- System controls

## Credits

- Display rotation implementation based on [fb-rotate](https://github.com/CdLbB/fb-rotate) by Eric Nitardy
- Original fb-rotate code from "Mac OS X Internals" by Amit Singh
- Inspired by BetterDisplay and other display management tools

## License

This project is available under the GNU General Public License (GPL) v3.0.

The display rotation code is derived from fb-rotate, which is licensed under GPL.

## Support

For issues, questions, or feature requests, please check:
- The troubleshooting section above
- System Settings → Privacy & Security → Accessibility
- Console.app for error messages (filter by "FloatingKeyboard")

---

**FloatingKeyboard v2.0.0** - A powerful, beautiful on-screen keyboard for macOS
