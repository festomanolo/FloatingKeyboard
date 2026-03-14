# FloatingKeyboard Installation Guide

<div align="center">

![FloatingKeyboard](https://img.shields.io/badge/macOS-15%2B-blue)
![Version](https://img.shields.io/badge/version-1.0.0-green)
![Swift](https://img.shields.io/badge/Swift-6-orange)

**A beautiful, feature-rich floating keyboard for macOS**

Created by [festomanolo](https://github.com/festomanolo)

</div>

---

## 📦 Installation

### Method 1: DMG Installer (Recommended)

1. **Download** `FloatingKeyboard-1.0.0.dmg`
2. **Open** the DMG file
3. **Drag** FloatingKeyboard.app to the Applications folder
4. **Launch** FloatingKeyboard from Applications
5. **Grant** Accessibility permissions when prompted

### Method 2: Build from Source

```bash
git clone https://github.com/festomanolo/FloatingKeyboard.git
cd FloatingKeyboard
open FloatingKeyboard.xcodeproj
# Build and run in Xcode (⌘R)
```

---

## 🔐 Permissions Required

FloatingKeyboard needs **Accessibility** permissions to function:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Click the **🔒** to unlock
3. Click **+** and add FloatingKeyboard
4. Toggle it **ON**

> ⚠️ Without Accessibility permissions, the keyboard cannot send keystrokes to other applications.

---

## ✨ Features

### 🎨 Themes
- **Glass** - Frosted glass with blur effects
- **Dark** - Sleek dark mode
- **Light** - Clean light mode
- **Minimal** - Minimalist design
- **Neon** - Reactive neon with animated grid ⚡
- **Fire** - Live fire animation with flames 🔥

### 🎵 Sound Profiles
- **Clicky (Blue)** - Mechanical blue switch sound
- **Thocky (Cream)** - Deep, satisfying thock
- **Futuristic** - Sci-fi inspired sounds

### 📋 Clipboard History
- Persistent clipboard manager
- Pin important items
- Quick paste with ⌘V
- Source app tracking

### ⚙️ Settings
- Auto-show in text fields
- Tablet mode (bottom dock)
- Internal keyboard suppression
- App exclusion list
- Opacity control

### ⚡ About Section
- Thunder-themed profile
- GitHub link
- Update checker
- App information

---

## 🎮 Usage

### Keyboard Shortcuts
- **Swipe Down** - Hide keyboard
- **Menu Bar Icon** - Show/hide keyboard
- **Long Press** - Show alternate characters (á, é, ñ, etc.)

### Layouts
- **Full** - Complete QWERTY layout with function keys
- **Numpad** - Compact numeric keypad

### Toolbar
- **Layout Switcher** - Toggle between Full/Numpad
- **Opacity Slider** - Adjust window transparency
- **Info Button** - About festomanolo ⚡
- **Clipboard Button** - Access clipboard history
- **Settings Button** - Configure preferences
- **Hide Button** - Minimize keyboard

---

## 🛠️ Troubleshooting

### Keyboard doesn't type
- ✅ Check Accessibility permissions
- ✅ Restart the app
- ✅ Disable App Sandbox (for development builds)

### Auto-show not working
- ✅ Enable "Auto-Show in Text Fields" in Settings
- ✅ Check if the app is in the exclusion list
- ✅ Grant Accessibility permissions

### "App Can't Be Opened" (Gatekeeper)
Because the app is not notarized, macOS may block it on first launch.
- **Solution 1**: Right-click (Control-click) `FloatingKeyboard.app`, hold **Option**, and click **Open**. Click **Open** again in the dialog.
- **Solution 2**: Run `xattr -cr /Applications/FloatingKeyboard.app` in Terminal.
- **Solution 3**: Go to **System Settings** → **Privacy & Security**, scroll down, and click **Open Anyway**.

### Sounds not playing
- ✅ Enable "Click Sounds" in Settings
- ✅ Check system volume
- ✅ Select a sound profile

---

## 🚀 Advanced

### Tablet Mode
Perfect for iPad-style usage:
1. Enable "Tablet Mode" in Settings
2. Keyboard docks at bottom of screen
3. Auto-shows when text fields are focused

### Internal Keyboard Suppression
Disable built-in keyboard when using external keyboard:
1. Enable "Suppress Internal" in Settings
2. Only external keyboards will work
3. Toggle off to re-enable

---

## 📝 System Requirements

- **macOS**: 15 Sequoia or later
- **Xcode**: 16+ (for building from source)
- **Swift**: 6
- **Architecture**: Apple Silicon & Intel

---

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Improve documentation

Visit [github.com/festomanolo](https://github.com/festomanolo) for more projects!

---

## 📄 License

MIT License - See LICENSE file for details

---

## 💙 Credits

**Created with ⚡ and 💙 by festomanolo**

- GitHub: [github.com/festomanolo](https://github.com/festomanolo)
- Built with Swift 6 + SwiftUI
- Powered by macOS Accessibility API

---

<div align="center">

**Enjoy your new floating keyboard!** 🎉

If you find this useful, consider giving it a ⭐ on GitHub!

</div>
