# FloatingKeyboard - Feature Testing Checklist

## ✅ Testing Guide

### 1. App Icon 🎨
- [ ] Check Dock icon shows keyboard with gradient
- [ ] Check menu bar icon is visible
- [ ] Verify icon looks good at different sizes

### 2. About Section ⚡
- [ ] Click the ⚡ info button in toolbar
- [ ] Verify your profile image (festomanolo.jpeg) displays
- [ ] Check lightning border animation around avatar
- [ ] Verify thunder background effects
- [ ] Click GitHub link - should open github.com/festomanolo
- [ ] Click "Check for Updates" - should show loading then success message
- [ ] Verify all app info displays correctly

### 3. Sound Profiles 🎵
**Setup:**
1. Open Settings (gear icon)
2. Enable "Click Sounds"
3. Select each sound profile

**Test Each Profile:**
- [ ] **Clicky (Blue)** - Sharp, high-pitched mechanical sound
- [ ] **Thocky (Cream)** - Deep, satisfying thock sound
- [ ] **Futuristic** - Sci-fi inspired sound with frequency sweep

**Test:**
- [ ] Type on keyboard - sound should play for each key
- [ ] Toggle sound off - no sound should play
- [ ] Switch profiles - sound should change immediately

### 4. Themes 🎨
Test each theme by selecting from Settings:
- [ ] **Glass** - Frosted glass with blur
- [ ] **Dark** - Sleek dark mode
- [ ] **Light** - Clean light mode
- [ ] **Minimal** - Minimalist design
- [ ] **Neon** - Reactive neon with animated grid ⚡
- [ ] **Fire** - Live fire animation with flames 🔥

### 5. Live Backgrounds
- [ ] **Fire Theme** - Verify animated flames moving
- [ ] **Neon Theme** - Verify pulsing grid and gradients

### 6. Keyboard Functionality
- [ ] Type letters - should appear in focused app
- [ ] Test Shift key - capitals work
- [ ] Test Caps Lock - indicator shows active state
- [ ] Test modifiers (Cmd, Opt, Ctrl)
- [ ] Long press letters - alternate characters appear (á, é, ñ)
- [ ] Test function keys (F1-F12)
- [ ] Test arrow keys
- [ ] Test backspace and enter
- [ ] Switch to Numpad layout - verify it works

### 7. Clipboard History 📋
- [ ] Copy text from another app
- [ ] Open clipboard panel
- [ ] Verify copied text appears
- [ ] Click item to paste
- [ ] Pin an item - verify pin icon
- [ ] Remove an item
- [ ] Clear unpinned items

### 8. Settings ⚙️
- [ ] Theme selection works
- [ ] Sound toggle works
- [ ] Sound profile selection works
- [ ] Auto-show toggle works
- [ ] Tablet mode toggle works
- [ ] Suppress internal keyboard toggle works
- [ ] Add excluded app
- [ ] Remove excluded app
- [ ] Opacity slider adjusts transparency

### 9. UI/UX
- [ ] Swipe down to hide keyboard
- [ ] Menu bar icon shows/hides keyboard
- [ ] Drag keyboard to move position
- [ ] Settings panel slides in smoothly
- [ ] Clipboard panel slides in smoothly
- [ ] About panel slides in smoothly
- [ ] Animations are smooth (60fps)
- [ ] No lag when typing

### 10. Accessibility
- [ ] App requests Accessibility permissions on first launch
- [ ] Warning banner shows if permissions not granted
- [ ] Click warning banner opens System Settings
- [ ] Keyboard works after granting permissions

### 11. Installation (DMG)
- [ ] Open FloatingKeyboard-1.0.0.dmg
- [ ] Verify app icon looks good in DMG
- [ ] Drag to Applications folder
- [ ] Launch from Applications
- [ ] README.txt is readable

## 🐛 Known Issues to Verify

1. **Sounds**: If sounds don't play, check:
   - Sound files are in app bundle: `FloatingKeyboard.app/Contents/Resources/Sounds/`
   - Files: clicky.wav, thocky.wav, futuristic.wav
   - Fallback to system sounds if custom sounds missing

2. **Profile Image**: If image doesn't show:
   - Check Assets.xcassets/ProfileImage.imageset/festomanolo.jpeg exists
   - Fallback to person icon if image missing

3. **App Icon**: If icon doesn't show:
   - Check all icon files in Assets.xcassets/AppIcon.appiconset/
   - Rebuild app to refresh icon cache

## 🎯 Performance Checks

- [ ] Memory usage < 100MB
- [ ] CPU usage < 5% when idle
- [ ] No memory leaks after extended use
- [ ] Animations run at 60fps
- [ ] App launches in < 2 seconds

## 📝 Notes

**Sound Files Location:**
```
FloatingKeyboard.app/Contents/Resources/Sounds/
├── clicky.wav (7KB)
├── thocky.wav (10KB)
└── futuristic.wav (8KB)
```

**Profile Image Location:**
```
Assets.xcassets/ProfileImage.imageset/
└── festomanolo.jpeg (17KB)
```

**App Icon Location:**
```
Assets.xcassets/AppIcon.appiconset/
├── icon_16x16.png
├── icon_16x16@2x.png
├── icon_32x32.png
├── icon_32x32@2x.png
├── icon_128x128.png
├── icon_128x128@2x.png
├── icon_256x256.png
├── icon_256x256@2x.png
├── icon_512x512.png
└── icon_512x512@2x.png
```

---

## ✅ Sign-off

- [ ] All features tested and working
- [ ] No critical bugs found
- [ ] Performance is acceptable
- [ ] Ready for distribution

**Tested by:** _______________  
**Date:** _______________  
**Version:** 1.0.0  
**Build:** Release

---

**Created with ⚡ and 💙 by festomanolo**
