#!/bin/bash

echo "🎨 Refreshing App Icon..."

# Clean build
echo "1️⃣ Cleaning build..."
xcodebuild -project FloatingKeyboard.xcodeproj -scheme FloatingKeyboard clean

# Clear icon cache
echo "2️⃣ Clearing icon cache..."
rm -rf ~/Library/Caches/com.apple.iconservices.store
sudo rm -rf /Library/Caches/com.apple.iconservices.store 2>/dev/null || true

# Touch Assets to force rebuild
echo "3️⃣ Touching assets..."
touch FloatingKeyboard/FloatingKeyboard/Assets.xcassets/AppIcon.appiconset/*

# Rebuild
echo "4️⃣ Rebuilding..."
xcodebuild -project FloatingKeyboard.xcodeproj \
  -scheme FloatingKeyboard \
  -configuration Release \
  build

# Restart Dock to refresh icons
echo "5️⃣ Restarting Dock..."
killall Dock

echo "✅ Icon refreshed! The new icon should appear now."
