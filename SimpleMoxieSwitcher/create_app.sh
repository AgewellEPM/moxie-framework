#!/bin/bash

# Build the app
swift build -c release

# Create app bundle structure
APP_NAME="SimpleMoxieSwitcher"
APP_BUNDLE="$APP_NAME.app"
rm -rf "$APP_BUNDLE"

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp .build/release/SimpleMoxieSwitcher "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
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
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>SimpleMoxieSwitcher needs access to speech recognition to allow voice input for conversations with Moxie.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>SimpleMoxieSwitcher needs access to the microphone to enable voice commands and conversations with Moxie.</string>
    <key>NSCameraUsageDescription</key>
    <string>SimpleMoxieSwitcher needs camera access for live preview and snapshots.</string>
</dict>
</plist>
EOF

echo "App bundle created: $APP_BUNDLE"
echo "Launching..."

# Launch the app bundle
open "$APP_BUNDLE"
