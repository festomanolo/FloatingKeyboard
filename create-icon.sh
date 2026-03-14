#!/bin/bash

# Create App Icon for FloatingKeyboard
# Generates a beautiful keyboard icon with gradient

ICONSET="FloatingKeyboard.iconset"
OUTPUT_ICON="FloatingKeyboard/FloatingKeyboard/Assets.xcassets/AppIcon.appiconset"

echo "🎨 Creating FloatingKeyboard app icon..."

# Create iconset directory
mkdir -p "$ICONSET"

# Create a simple SVG icon
cat > icon.svg << 'SVGEOF'
<svg width="1024" height="1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#764ba2;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#f093fb;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="grad2" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#ffd89b;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#19547b;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- Background rounded square -->
  <rect x="50" y="50" width="924" height="924" rx="200" fill="url(#grad1)"/>
  
  <!-- Keyboard base -->
  <rect x="150" y="350" width="724" height="450" rx="40" fill="rgba(255,255,255,0.2)"/>
  
  <!-- Keys row 1 -->
  <rect x="200" y="400" width="80" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  <rect x="300" y="400" width="80" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  <rect x="400" y="400" width="80" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  <rect x="500" y="400" width="80" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  <rect x="600" y="400" width="80" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  <rect x="700" y="400" width="80" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  
  <!-- Keys row 2 -->
  <rect x="200" y="500" width="80" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  <rect x="300" y="500" width="80" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  <rect x="400" y="500" width="80" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  <rect x="500" y="500" width="80" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  <rect x="600" y="500" width="80" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  <rect x="700" y="500" width="80" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  
  <!-- Keys row 3 (spacebar) -->
  <rect x="300" y="600" width="380" height="80" rx="12" fill="rgba(255,255,255,0.9)"/>
  
  <!-- Lightning bolt accent -->
  <path d="M 512 150 L 450 350 L 550 350 L 480 550 L 600 350 L 500 350 Z" 
        fill="#ffd700" stroke="#ff8c00" stroke-width="4"/>
</svg>
SVGEOF

# Check if we have the tools to convert
if command -v sips &> /dev/null; then
    echo "✅ Using sips to generate icons..."
    
    # Convert SVG to PNG at different sizes
    SIZES=(16 32 64 128 256 512 1024)
    
    for size in "${SIZES[@]}"; do
        # For retina displays, we need @2x versions
        if [ $size -le 512 ]; then
            double=$((size * 2))
            echo "  Creating ${size}x${size} and ${size}x${size}@2x..."
            
            # Create base size
            qlmanage -t -s $size -o . icon.svg 2>/dev/null
            mv icon.svg.png "$ICONSET/icon_${size}x${size}.png" 2>/dev/null || \
                sips -z $size $size icon.svg --out "$ICONSET/icon_${size}x${size}.png" 2>/dev/null
            
            # Create @2x size
            qlmanage -t -s $double -o . icon.svg 2>/dev/null
            mv icon.svg.png "$ICONSET/icon_${size}x${size}@2x.png" 2>/dev/null || \
                sips -z $double $double icon.svg --out "$ICONSET/icon_${size}x${size}@2x.png" 2>/dev/null
        else
            echo "  Creating ${size}x${size}..."
            qlmanage -t -s $size -o . icon.svg 2>/dev/null
            mv icon.svg.png "$ICONSET/icon_${size}x${size}.png" 2>/dev/null || \
                sips -z $size $size icon.svg --out "$ICONSET/icon_${size}x${size}.png" 2>/dev/null
        fi
    done
    
    # Generate .icns file
    echo "📦 Generating .icns file..."
    iconutil -c icns "$ICONSET" -o AppIcon.icns
    
    # Update Contents.json
    cat > "$OUTPUT_ICON/Contents.json" << 'JSONEOF'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "festomanolo",
    "version" : 1
  }
}
JSONEOF
    
    # Copy icons to asset catalog
    cp "$ICONSET"/*.png "$OUTPUT_ICON/"
    
    echo "✅ App icon created successfully!"
    echo "📁 Icons saved to: $OUTPUT_ICON"
    
    # Cleanup
    rm -rf "$ICONSET" icon.svg AppIcon.icns
else
    echo "⚠️  sips not found. Please install Xcode Command Line Tools."
    exit 1
fi

echo "🎉 Done!"
