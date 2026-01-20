#!/bin/bash

APP_NAME="SimpleMoxieSwitcherApp"
APP_DIR="build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Creating app bundle for $APP_NAME..."

# Clean previous build
rm -rf "$APP_DIR"

# Create app bundle structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy Info.plist
cp SimpleMoxieSwitcherApp/Info.plist "$CONTENTS_DIR/"

# Build the executable
echo "Compiling Swift files..."
swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
    -target x86_64-apple-macos13.0 \
    -swift-version 5 \
    -emit-executable \
    -o "$MACOS_DIR/$APP_NAME" \
    SimpleMoxieSwitcherApp/*.swift \
    SimpleMoxieSwitcherApp/Views/*.swift \
    SimpleMoxieSwitcherApp/ViewModels/*.swift \
    SimpleMoxieSwitcherApp/Models/*.swift 2>&1 | grep -v warning

if [ $? -eq 0 ]; then
    # Copy assets if they exist
    if [ -d "SimpleMoxieSwitcherApp/Assets.xcassets" ]; then
        cp -r SimpleMoxieSwitcherApp/Assets.xcassets "$RESOURCES_DIR/"
    fi

    # Make executable
    chmod +x "$MACOS_DIR/$APP_NAME"

    echo "App bundle created successfully!"
    echo "Location: $APP_DIR"
    echo ""
    echo "To run the app:"
    echo "  open $APP_DIR"
else
    echo "Build failed!"
    exit 1
fi