#!/bin/bash

# Add sound files to Xcode project
echo "🎵 Adding sound files to Xcode project..."

# The sound files are already in FloatingKeyboard/FloatingKeyboard/Sounds/
# We need to add them to the Copy Bundle Resources build phase

PROJECT_FILE="FloatingKeyboard.xcodeproj/project.pbxproj"

# Backup the project file
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"

echo "✅ Sound files are in: FloatingKeyboard/FloatingKeyboard/Sounds/"
echo "📝 To add them to Xcode:"
echo "   1. Open FloatingKeyboard.xcodeproj in Xcode"
echo "   2. Drag the Sounds folder into the project navigator"
echo "   3. Check 'Copy items if needed' and 'Create folder references'"
echo "   4. Ensure 'FloatingKeyboard' target is selected"
echo "   5. Build and run!"
echo ""
echo "Or run this command to add them automatically:"
echo "   open FloatingKeyboard.xcodeproj"

