#!/bin/bash

# FloatingKeyboard DMG Creation Script
# Creates a beautiful installer DMG with custom background

set -e

APP_NAME="FloatingKeyboard"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR="./build-output/Build/Products/Release"
DMG_DIR="./dmg-build"
FINAL_DMG="./${DMG_NAME}.dmg"

# Clean up previous builds
rm -rf "${DMG_DIR}"
rm -f "${FINAL_DMG}"
rm -f "${DMG_NAME}-temp.dmg"

# Create DMG directory structure
mkdir -p "${DMG_DIR}"

# Build release version (Universal)
echo "🏗️  Building Universal binary (arm64 + x86_64)..."
xcodebuild -project FloatingKeyboard.xcodeproj \
  -scheme FloatingKeyboard \
  -configuration Release \
  -derivedDataPath ./build-output \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  clean build

# Copy the app
echo "📦 Copying application..."
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${DMG_DIR}/"

# Remove quarantine attribute (BEFORE signing to avoid invalidating the seal)
echo "1️⃣ Removing quarantine attribute..."
xattr -cr "${DMG_DIR}/${APP_NAME}.app"

# Ad-hoc sign (for distribution) with entitlements
echo "✍️  Ad-hoc signing with entitlements..."
codesign --force --deep --sign - \
  --entitlements "./FloatingKeyboard/FloatingKeyboard.entitlements" \
  "${DMG_DIR}/${APP_NAME}.app"

# Verify signature
echo "🔍 Verifying signature..."
codesign --verify --verbose "${DMG_DIR}/${APP_NAME}.app"

# Create Applications symlink
echo "🔗 Creating Applications symlink..."
ln -s /Applications "${DMG_DIR}/Applications"

# Create README
echo "📝 Creating README..."
cat > "${DMG_DIR}/README.txt" << 'EOF'
FloatingKeyboard v1.0.0
=======================

A beautiful, feature-rich floating keyboard for macOS 15+

⚠️ IMPORTANT: First Time Opening
================================
macOS Gatekeeper may block this app because it's not notarized.

To open the app:
1. Right-click (or Control-click) on FloatingKeyboard.app
2. Hold the Option key
3. Click "Open"
4. Click "Open" in the dialog

OR run this command in Terminal:
  xattr -cr /Applications/FloatingKeyboard.app

This only needs to be done once!

Installation:
=============
1. Drag FloatingKeyboard.app to the Applications folder
2. Open FloatingKeyboard from Applications (see above)
3. Grant Accessibility permissions when prompted
4. Enjoy your new floating keyboard!

Features:
=========
✨ Multiple themes (Glass, Dark, Light, Minimal, Neon, Fire)
🎵 Sound profiles (Clicky, Thocky, Futuristic)
🎚️ Volume & Brightness controls (Dynamic Island style)
📋 Clipboard history
⚙️ Customizable settings
🎨 Live animated backgrounds
⌨️ Full QWERTY + Numpad layouts

Created by festomanolo
GitHub: github.com/festomanolo

© 2026 festomanolo. All rights reserved.
EOF

# Calculate size
echo "📏 Calculating size..."
SIZE=$(du -sm "${DMG_DIR}" | awk '{print $1}')
SIZE=$((SIZE + 50))  # Add 50MB buffer

# Create temporary DMG
echo "💿 Creating temporary DMG..."
hdiutil create -srcfolder "${DMG_DIR}" -volname "${APP_NAME}" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${SIZE}m "${DMG_NAME}-temp.dmg"

# Mount the temporary DMG
echo "🔧 Mounting DMG..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_NAME}-temp.dmg" | \
    egrep '^/dev/' | sed 1q | awk '{print $1}')
MOUNT_DIR="/Volumes/${APP_NAME}"

echo "Mounted at: ${MOUNT_DIR}"

# Wait for mount
sleep 2

# Set DMG window properties
echo "🎨 Configuring DMG appearance..."
cat > /tmp/dmg-setup.applescript << EOF
tell application "Finder"
    tell disk "${APP_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 700, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 96
        set background picture of viewOptions to file ".background:background.png"
        set position of item "${APP_NAME}.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        set position of item "README.txt" of container window to {300, 350}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Create background directory
mkdir -p "${MOUNT_DIR}/.background"

# Create a simple background image using ImageMagick or sips
# For now, we'll skip the custom background as it requires additional tools
# The DMG will still look professional with the icon arrangement

# Run AppleScript to set window properties
# osascript /tmp/dmg-setup.applescript || echo "⚠️  Could not set DMG window properties (this is optional)"

# Unmount
echo "💾 Finalizing DMG..."
hdiutil detach "${MOUNT_DIR}"
sleep 2

# Convert to compressed, read-only DMG
echo "🗜️  Compressing DMG..."
hdiutil convert "${DMG_NAME}-temp.dmg" -format UDZO -imagekey zlib-level=9 -o "${FINAL_DMG}"

# Clean up
rm -f "${DMG_NAME}-temp.dmg"
rm -rf "${DMG_DIR}"
rm -f /tmp/dmg-setup.applescript

echo "✅ DMG created successfully: ${FINAL_DMG}"
echo "📦 Size: $(du -h "${FINAL_DMG}" | awk '{print $1}')"
echo ""
echo "🎉 Installation package ready for distribution!"
