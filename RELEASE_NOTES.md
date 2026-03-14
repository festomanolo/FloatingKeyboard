# FloatingKeyboard v1.0.0 - Release Notes

## 🎉 Initial Release - March 12, 2026

We're thrilled to announce the first official release of FloatingKeyboard - the most beautiful floating keyboard for macOS!

---

## ✨ What's New

### 🎨 Themes
- **Glass** - Frosted glass with blur effects
- **Dark** - Sleek dark mode
- **Light** - Clean light mode
- **Minimal** - Minimalist design
- **Neon** - Reactive neon with animated grid ⚡
- **Fire** - Live fire animation with realistic flames 🔥

### 🎵 Sound Profiles
- **Clicky (Blue)** - Mechanical blue switch sound
- **Thocky (Cream)** - Deep, satisfying thock
- **Futuristic** - Sci-fi inspired sounds

### 📋 Clipboard Manager
- Persistent clipboard history
- Pin important items
- Source app tracking
- Quick paste with ⌘V
- Stores up to 25 items

### ⚙️ Settings
- Theme selection
- Sound toggle and profile selection
- Auto-show in text fields
- Tablet mode (bottom dock)
- Internal keyboard suppression
- Per-app exclusion list
- Opacity control

### ⚡ About Section (NEW!)
- Thunder-themed developer profile
- Animated lightning effects
- Pulsing glow animations
- Direct GitHub link to [github.com/festomanolo](https://github.com/festomanolo)
- Built-in update checker
- App version and platform info

### ⌨️ Keyboard Features
- Full QWERTY layout with function keys
- Compact numpad layout
- Long-press for alternate characters (á, é, ñ, etc.)
- Modifier keys (Shift, Ctrl, Opt, Cmd)
- Caps Lock support
- Emoji picker integration
- Context menu on keys

### 🎯 User Experience
- Swipe down to hide
- Menu bar icon for quick access
- Non-focus-stealing window
- Resizable and draggable
- Smooth animations
- Responsive layout

---

## 🛠️ Technical Details

### Built With
- **Swift 6** - Latest Swift features
- **SwiftUI** - Modern declarative UI
- **macOS 15+** - Sequoia and Tahoe support
- **Xcode 16+** - Latest toolchain

### Architecture
- `@Observable` macro for state management
- `@MainActor` isolation for thread safety
- CGEvent API for keystroke injection
- Accessibility API for auto-detection
- UserDefaults for persistence
- TimelineView for animations
- Canvas for custom drawing

### Performance
- Lightweight (~422KB DMG)
- Minimal memory footprint
- Smooth 60fps animations
- Efficient event handling
- Optimized rendering

---

## 📦 Installation

### DMG Installer
1. Download `FloatingKeyboard-1.0.0.dmg`
2. Open the DMG file
3. Drag FloatingKeyboard.app to Applications
4. Launch and grant Accessibility permissions

### Build from Source
```bash
git clone https://github.com/festomanolo/FloatingKeyboard.git
cd FloatingKeyboard
open FloatingKeyboard.xcodeproj
# Build and run (⌘R)
```

---

## 🔐 Permissions

FloatingKeyboard requires **Accessibility** permissions to function:
- System Settings → Privacy & Security → Accessibility
- Add FloatingKeyboard and toggle ON

---

## 📋 System Requirements

- **macOS**: 15 Sequoia or later (macOS 26 Tahoe supported)
- **Architecture**: Apple Silicon & Intel
- **Xcode**: 16+ (for building from source)
- **Swift**: 6

---

## 🐛 Known Issues

- No Mac App Store distribution (requires disabled sandbox)
- Emoji picker uses system implementation
- Limited IME support for non-Latin languages

---

## 🚀 What's Next

### v1.1.0 (Planned)
- Custom key mappings
- More sound profiles
- Additional themes
- Haptic feedback support
- Keyboard shortcuts customization

### v1.2.0 (Future)
- Multi-language layouts
- Gesture typing
- Text expansion
- Cloud sync for settings

---

## 🤝 Contributing

We welcome contributions! Visit [github.com/festomanolo](https://github.com/festomanolo) to:
- Report bugs
- Request features
- Submit pull requests
- Improve documentation

---

## 💙 Credits

**Created with ⚡ and 💙 by festomanolo**

Special thanks to:
- The Swift community
- macOS developer community
- All beta testers
- Everyone who provided feedback

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🔗 Links

- **GitHub**: [github.com/festomanolo](https://github.com/festomanolo)
- **Issues**: [Report a bug](https://github.com/festomanolo/FloatingKeyboard/issues)
- **Releases**: [Download latest](https://github.com/festomanolo/FloatingKeyboard/releases)
- **Documentation**: [Installation Guide](INSTALLATION.md)

---

<div align="center">

**Thank you for using FloatingKeyboard!** 🎉

If you enjoy this app, please consider giving it a ⭐ on GitHub!

Made with ⚡ and 💙 by [festomanolo](https://github.com/festomanolo)

</div>
