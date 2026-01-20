#!/bin/bash

# Build script for SimpleMoxieSwitcherApp

echo "Building SimpleMoxieSwitcherApp..."

# Create build directory
mkdir -p build

# Compile all Swift files
swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
    -target x86_64-apple-macos13.0 \
    -swift-version 5 \
    -emit-executable \
    -o build/SimpleMoxieSwitcherApp \
    SimpleMoxieSwitcherApp/*.swift \
    SimpleMoxieSwitcherApp/Views/*.swift \
    SimpleMoxieSwitcherApp/ViewModels/*.swift \
    SimpleMoxieSwitcherApp/Models/*.swift

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Executable created at: build/SimpleMoxieSwitcherApp"
else
    echo "Build failed!"
    exit 1
fi