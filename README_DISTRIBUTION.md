# ⚡ FloatingKeyboard

<div align="center">

![macOS](https://img.shields.io/badge/macOS-15%2B-blue?style=for-the-badge&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6-orange?style=for-the-badge&logo=swift)
![Version](https://img.shields.io/badge/version-1.0.0-green?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-purple?style=for-the-badge)

**The most beautiful floating keyboard for macOS**

*Created with ⚡ and 💙 by [festomanolo](https://github.com/festomanolo)*

[Download DMG](https://github.com/festomanolo/FloatingKeyboard/releases) • [Installation Guide](INSTALLATION.md) • [Report Bug](https://github.com/festomanolo/FloatingKeyboard/issues)

</div>

---

## 🌟 Features

### 🎨 **6 Stunning Themes**
- **Glass** - Frosted glass with blur effects
- **Dark** - Sleek dark mode
- **Light** - Clean light mode  
- **Minimal** - Minimalist design
- **Neon** - Reactive neon with animated grid ⚡
- **Fire** - Live fire animation with flames 🔥

### 🎵 **3 Sound Profiles**
- **Clicky (Blue)** - Mechanical blue switch sound
- **Thocky (Cream)** - Deep, satisfying thock
- **Futuristic** - Sci-fi inspired sounds

### 📋 **Smart Clipboard**
- Persistent history across sessions
- Pin important items
- Source app tracking
- Quick paste integration

### ⚙️ **Powerful Settings**
- Auto-show in text fields
- Tablet mode (bottom dock)
- Internal keyboard suppression
- Per-app exclusion list
- Opacity control

### ⚡ **About Section**
- Thunder-themed developer profile
- Direct GitHub link
- Built-in update checker
- App information

---

## 📸 Screenshots

### Glass Theme
*Frosted glass effect with blur and transparency*

### Fire Theme 🔥
*Live animated flames with realistic movement*

### Neon Theme ⚡
*Reactive neon grid with pulsing effects*

### About Section
*Thunder-themed profile with electric effects*

---

## 🚀 Quick Start

### Installation

1. **Download** the latest DMG from [Releases](https://github.com/festomanolo/FloatingKeyboard/releases)
2. **Open** `FloatingKeyboard-1.0.0.dmg`
3. **Drag** the app to Applications
4. **Launch** and grant Accessibility permissions

### First Use

1. Click the keyboard icon in your menu bar
2. The floating keyboard appears
3. Click the ⚙️ icon to customize
4. Click the ⚡ icon to learn about the creator

---

## 💡 Usage Tips

### Keyboard Shortcuts
- **Swipe Down** - Hide keyboard
- **Long Press** - Show alternate characters (á, é, ñ)
- **⌘V** - Paste from clipboard history

### Layouts
- **Full** - Complete QWERTY with function keys
- **Numpad** - Compact numeric keypad

### Pro Tips
- Enable Tablet Mode for iPad-like experience
- Use opacity slider for perfect transparency
- Pin frequently used clipboard items
- Exclude apps where you don't need the keyboard

---

## 🛠️ Building from Source

### Requirements
- macOS 15+ (Sequoia or Tahoe)
- Xcode 16+
- Swift 6

### Build Steps

```bash
# Clone the repository
git clone https://github.com/festomanolo/FloatingKeyboard.git
cd FloatingKeyboard

# Open in Xcode
open FloatingKeyboard.xcodeproj

# Build and run (⌘R)
```

### Create DMG

```bash
# Build release version
xcodebuild -project FloatingKeyboard.xcodeproj \
  -scheme FloatingKeyboard \
  -configuration Release \
  clean build

# Create DMG installer
./create-dmg.sh
```

---

## 🏗️ Architecture

```
FloatingKeyboardApp (@main)
│
├── AppDelegate (NSApplicationDelegate)
│   ├── KeyboardPanel (NSPanel)
│   │   └── KeyboardContainerView (SwiftUI)
│   │       ├── FullKeyboardView (5 rows)
│   │       ├── NumpadView
│   │       ├── InlineSettingsView
│   │       ├── InlineClipboardView
│   │       └── InlineAboutView ⚡
│   │
│   ├── AccessibilityObserver (Auto-show)
│   └── NSStatusItem (Menu bar)
│
├── KeyboardViewModel (@Observable)
│   ├── Theme management
│   ├── Sound profiles
│   ├── Clipboard history
│   └── Settings persistence
│
└── KeyEventSender
    └── CGEvent injection
```

---

## 🎯 Technical Highlights

### Swift 6 Features
- `@Observable` macro for state management
- `@MainActor` isolation for UI safety
- Strict concurrency checking
- Modern async/await patterns

### SwiftUI Components
- `TimelineView` for animations
- `Canvas` for custom drawing
- `GeometryReader` for responsive layouts
- Custom `ButtonStyle` implementations

### macOS Integration
- Accessibility API for auto-detection
- CGEvent for keystroke injection
- NSPanel for non-activating windows
- UserDefaults for persistence

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Bug Reports
- Use the [issue tracker](https://github.com/festomanolo/FloatingKeyboard/issues)
- Include macOS version and steps to reproduce
- Attach screenshots if applicable

### Feature Requests
- Open an issue with the `enhancement` label
- Describe the feature and use case
- Explain why it would be useful

### Pull Requests
- Fork the repository
- Create a feature branch
- Write clean, documented code
- Test thoroughly
- Submit PR with description

---

## 📋 Roadmap

### v1.1.0 (Planned)
- [ ] Custom key mappings
- [ ] Keyboard shortcuts customization
- [ ] More sound profiles
- [ ] Additional themes
- [ ] Haptic feedback support

### v1.2.0 (Future)
- [ ] Multi-language layouts
- [ ] Gesture typing
- [ ] Text expansion
- [ ] Emoji search
- [ ] Cloud sync for settings

---

## 🐛 Troubleshooting

### "App Can't Be Opened" (Gatekeeper)
Because the app is not notarized, macOS may block it on first launch.
- **Solution 1**: Right-click (Control-click) `FloatingKeyboard.app`, hold **Option**, and click **Open**. Click **Open** again in the dialog.
- **Solution 2**: Run `xattr -cr /Applications/FloatingKeyboard.app` in Terminal.
- **Solution 3**: Go to **System Settings** → **Privacy & Security**, scroll down, and click **Open Anyway**.

### Keyboard doesn't type
- ✅ Check **Accessibility** permissions in System Settings.
- ✅ Ensure "Enable Click Sounds" is ON if you want audio feedback.

## 🐛 Known Issues

- **No Mac App Store**: Requires disabled sandbox for CGEvent injection
- **Emoji Picker**: Uses system picker, not custom implementation
- **IME Support**: Limited support for input method editors

---

## 📄 License

MIT License

Copyright (c) 2026 festomanolo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## 💙 About the Creator

**festomanolo** - Passionate developer creating beautiful macOS applications

- 🌐 GitHub: [github.com/festomanolo](https://github.com/festomanolo)
- ⚡ Check out the About section in the app for the full thunder experience!
- 💼 Open to collaborations and interesting projects

---

## 🙏 Acknowledgments

- Built with Swift 6 and SwiftUI
- Inspired by iOS keyboard design
- Thanks to the macOS developer community
- Special thanks to all contributors

---

<div align="center">

**Made with ⚡ and 💙**

If you find this project useful, please consider giving it a ⭐!

[⬆ Back to Top](#-floatingkeyboard)

</div>
