#!/bin/bash

echo "🔧 Fixing FloatingKeyboard for distribution..."

APP_PATH="$HOME/Library/Developer/Xcode/DerivedData/FloatingKeyboard-gznzvvrwyuzwwhehvcaapmusnepf/Build/Products/Release/FloatingKeyboard.app"

# Remove quarantine attribute
echo "1️⃣ Removing quarantine attribute..."
xattr -cr "$APP_PATH"

# Ad-hoc sign (for local distribution)
echo "2️⃣ Ad-hoc signing..."
codesign --force --deep --sign - "$APP_PATH"

echo "✅ App fixed for local distribution!"
echo ""
echo "📝 To distribute to other Macs:"
echo "   Option 1: Recipients run: xattr -cr FloatingKeyboard.app"
echo "   Option 2: Right-click app, hold Option, click 'Open'"
echo "   Option 3: System Settings → Privacy & Security → Allow"
echo ""
echo "🔐 For proper distribution, you need:"
echo "   - Apple Developer Account (\$99/year)"
echo "   - Developer ID certificate"
echo "   - Notarization"

