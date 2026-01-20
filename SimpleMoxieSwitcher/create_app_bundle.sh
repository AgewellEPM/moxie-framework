#!/bin/bash

# Build the app with Swift Package Manager
echo "🔨 Building SimpleMoxieSwitcher..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# Create app bundle structure
APP_NAME="SimpleMoxieSwitcher"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

# Remove old bundle if exists
rm -rf "$APP_BUNDLE"

# Create directories
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy executable from Swift build directory
BINARY_PATH=".build/release/SimpleMoxieSwitcher"

if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Could not find built binary at $BINARY_PATH"
    exit 1
fi

echo "📦 Using binary: $BINARY_PATH"
cp "$BINARY_PATH" "$MACOS/"

# Create Info.plist
cat > "${CONTENTS}/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SimpleMoxieSwitcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.moxie.SimpleMoxieSwitcher</string>
    <key>CFBundleName</key>
    <string>SimpleMoxieSwitcher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Moxie uses speech recognition to enable voice input during story time, allowing you to speak your story ideas instead of typing them.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Moxie needs access to your microphone to enable voice input during story time.</string>
    <key>NSCameraUsageDescription</key>
    <string>Moxie may access the camera for live preview and snapshots.</string>
    <key>NSLocalNetworkUsageDescription</key>
    <string>SimpleMoxieSwitcher needs local network access to communicate with Moxie robot via MQTT.</string>
</dict>
</plist>
EOF

# Copy app icon if exists
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES/"
    # Add icon reference to Info.plist
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "${CONTENTS}/Info.plist" 2>/dev/null || true
fi

echo "✅ App bundle created: $APP_BUNDLE"
echo ""
echo "To run the app:"
echo "  open $APP_BUNDLE"
echo ""
echo "To create a DMG for distribution:"
echo "  ./create_dmg.sh"
