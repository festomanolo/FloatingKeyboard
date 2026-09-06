#!/bin/bash

# FloatingKeyboard DMG Creator - Release Version
# Creates a professional, distributable DMG package ready for sale

set -e

VERSION="2.0.0"
APP_NAME="FloatingKeyboard"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
VOLUME_NAME="${APP_NAME} ${VERSION}"
TEMP_DMG="temp.dmg"

echo "🔨 Building FloatingKeyboard (Release)..."
xcodebuild -project FloatingKeyboard.xcodeproj \
           -scheme FloatingKeyboard \
           -configuration Release \
           clean build \
           CODE_SIGN_IDENTITY="-" \
           CODE_SIGN_STYLE=Manual

# Find the Release build
BUILD_DIR="$HOME/Library/Developer/Xcode/DerivedData/FloatingKeyboard-gznzvvrwyuzwwhehvcaapmusnepf/Build/Products/Release"

# Check if build succeeded
if [ ! -d "${BUILD_DIR}/${APP_NAME}.app" ]; then
    echo "❌ Build failed - app not found at ${BUILD_DIR}"
    exit 1
fi

echo "✅ Build successful!"
echo ""
echo "📦 Creating professional DMG package..."

# Remove old DMG if exists
rm -f "${DMG_NAME}" "${TEMP_DMG}"

# Create temporary DMG (larger size for professional package)
hdiutil create -size 100m -fs HFS+ -volname "${VOLUME_NAME}" "${TEMP_DMG}"

# Mount it
echo "📂 Mounting DMG..."
MOUNT_DIR=$(hdiutil attach "${TEMP_DMG}" | grep "/Volumes/${VOLUME_NAME}" | awk '{print $3}')

if [ -z "$MOUNT_DIR" ]; then
    echo "❌ Failed to mount DMG"
    exit 1
fi

echo "📋 Copying files to DMG..."

# Copy app
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${MOUNT_DIR}/"

# Create Applications symlink for easy installation
ln -s /Applications "${MOUNT_DIR}/Applications"

# Copy README
cp README.md "${MOUNT_DIR}/README.md"

# Copy LICENSE
cp LICENSE "${MOUNT_DIR}/LICENSE.txt"

# Create professional installation instructions
cat > "${MOUNT_DIR}/INSTALL.txt" << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║          FloatingKeyboard v2.0.0 - Installation              ║
╚══════════════════════════════════════════════════════════════╝

Thank you for purchasing FloatingKeyboard!

INSTALLATION STEPS:
═══════════════════

1. Drag "FloatingKeyboard.app" to the "Applications" folder
2. Launch FloatingKeyboard from Applications
3. Grant Accessibility permissions when prompted:
   → System Settings → Privacy & Security → Accessibility
   → Enable FloatingKeyboard
4. Click the keyboard icon (⌨️) in the menu bar
5. Select "Show Keyboard"

WHAT'S NEW IN v2.0.0:
═══════════════════════

✨ Display Rotation Button (🔄)
   • Toggle 180° rotation on supported displays
   • Located on bottom row between ⌘ and 😊

✨ Improved Ergonomics
   • 26% taller keys for better comfort
   • Enhanced spacing (20% horizontal, 50% vertical)
   • Larger, more readable fonts (11-24pt)

✨ Enhanced Sound System
   • All sound profiles working perfectly
   • Clicky, Thocky, and Futuristic sounds
   • Improved volume and clarity

✨ Smoother Experience
   • Spring-based animations
   • Better visual feedback
   • Enhanced performance

FEATURES:
═════════

• Full QWERTY keyboard + numpad layout
• 5 beautiful themes (Glass, Neon, Fire, Thunder, Manolo)
• Sound profiles with realistic keyboard sounds
• Clipboard history with search
• System controls (volume, brightness, dock)
• Auto-show in text fields
• Tablet mode for bottom positioning
• Internal keyboard suppression

SUPPORT:
════════

For help and documentation, see README.md

Display Rotation Note:
• Works on external displays that support rotation
• Internal laptop displays typically don't support rotation
  (this is a hardware limitation, not a software issue)

SYSTEM REQUIREMENTS:
════════════════════

• macOS 15.0 or later
• Apple Silicon or Intel Mac
• Accessibility permissions required

═══════════════════════════════════════════════════════════════

Enjoy your FloatingKeyboard!

For questions or support, please refer to the documentation.

═══════════════════════════════════════════════════════════════
EOF

# Create a quick start guide
cat > "${MOUNT_DIR}/QUICK_START.txt" << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║              FloatingKeyboard - Quick Start                  ║
╚══════════════════════════════════════════════════════════════╝

FIRST TIME SETUP:
═════════════════

1. Install the app (drag to Applications)
2. Launch FloatingKeyboard
3. Grant Accessibility permissions
4. Done! Click the menu bar icon to show keyboard

KEYBOARD SHORTCUTS:
═══════════════════

Show/Hide:  Click menu bar icon (⌨️)
Swipe Down: Hide keyboard
Emoji:      Click 😊 button
Rotate:     Click 🔄 button (on supported displays)

KEYBOARD LAYOUT:
════════════════

Bottom Row Special Buttons:
[esc] [ctrl] [opt] [⌘] [space] [⌘] [🔄] [😊] [←] [↓] [↑] [→]
                                    ↑    ↑
                              Rotate  Emoji

THEMES:
═══════

• Glass - Classic frosted glass (default)
• Neon - Cyberpunk neon glow
• Fire - Animated flames
• Thunder - Lightning effects
• Manolo - Special shockwave effects

Access themes via Settings (⚙️ icon)

SOUND PROFILES:
═══════════════

• Clicky - Sharp, tactile clicks
• Thocky - Deep, satisfying thocks
• Futuristic - Sci-fi beeps
• Silent - No sound

TIPS:
═════

• Adjust opacity with the slider in toolbar
• Use tablet mode for bottom positioning
• Enable auto-show for automatic appearance
• Suppress internal keyboard if using as primary

═══════════════════════════════════════════════════════════════

For complete documentation, see README.md

═══════════════════════════════════════════════════════════════
EOF

echo "🎨 Finalizing DMG..."

# Set custom icon positions (if possible)
# This would require AppleScript or additional tools

# Unmount
hdiutil detach "${MOUNT_DIR}" -quiet

echo "🗜️  Compressing DMG..."

# Convert to compressed, read-only DMG
hdiutil convert "${TEMP_DMG}" -format UDZO -o "${DMG_NAME}" -quiet

# Remove temp DMG
rm -f "${TEMP_DMG}"

# Get DMG info
DMG_SIZE=$(du -h "${DMG_NAME}" | awk '{print $1}')
DMG_PATH=$(pwd)/${DMG_NAME}

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  ✅ DMG CREATED SUCCESSFULLY!                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 File: ${DMG_NAME}"
echo "💾 Size: ${DMG_SIZE}"
echo "📍 Path: ${DMG_PATH}"
echo ""
echo "🚀 READY FOR DISTRIBUTION!"
echo ""
echo "This DMG includes:"
echo "  ✓ Release build (optimized)"
echo "  ✓ Installation instructions"
echo "  ✓ Quick start guide"
echo "  ✓ Complete documentation"
echo "  ✓ License file"
echo "  ✓ Applications folder shortcut"
echo ""
echo "Next steps for selling:"
echo "  1. Test the DMG on a clean Mac"
echo "  2. Consider code signing for distribution"
echo "  3. Notarize with Apple (for Gatekeeper)"
echo "  4. Upload to your sales platform"
echo ""
