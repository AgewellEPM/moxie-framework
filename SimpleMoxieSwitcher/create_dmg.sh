#!/bin/bash

# SimpleMoxieSwitcher macOS DMG Creator
# Creates a distributable .dmg file with proper code signing

set -e  # Exit on error

APP_NAME="SimpleMoxieSwitcher"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}"
VOLUME_NAME="${APP_NAME}"
SOURCE_APP="${APP_NAME}.app"
DMG_TEMP="${DMG_NAME}-temp.dmg"
DMG_FINAL="${DMG_NAME}.dmg"

# Your Apple Developer certificate name
# Find it with: security find-identity -v -p codesigning
SIGNING_IDENTITY="Developer ID Application: RollSEO LLC"

echo "🚀 Building SimpleMoxieSwitcher for macOS distribution..."

# Step 1: Build the app
echo "📦 Step 1: Building release version..."
swift build -c release

# Step 2: Create app bundle
echo "📦 Step 2: Creating app bundle..."
./create_app_bundle.sh

# Step 3: Code sign the app
echo "✍️  Step 3: Code signing..."
# Sign all frameworks and libraries first
find "${SOURCE_APP}/Contents" -name "*.dylib" -exec codesign --force --sign "${SIGNING_IDENTITY}" --timestamp {} \;
find "${SOURCE_APP}/Contents" -name "*.framework" -exec codesign --force --sign "${SIGNING_IDENTITY}" --timestamp --deep {} \;

# Sign the main executable
codesign --force --sign "${SIGNING_IDENTITY}" --timestamp --options runtime "${SOURCE_APP}/Contents/MacOS/${APP_NAME}"

# Sign the entire app bundle
codesign --force --sign "${SIGNING_IDENTITY}" --timestamp --options runtime --deep "${SOURCE_APP}"

# Verify signature
echo "🔍 Verifying signature..."
codesign --verify --deep --strict --verbose=2 "${SOURCE_APP}"
spctl --assess --type execute --verbose=4 "${SOURCE_APP}"

# Step 4: Create temporary DMG
echo "💿 Step 4: Creating DMG..."
rm -f "${DMG_TEMP}" "${DMG_FINAL}"

# Create a temporary folder for DMG contents
DMG_FOLDER="dmg_contents"
rm -rf "${DMG_FOLDER}"
mkdir -p "${DMG_FOLDER}"

# Copy app to DMG folder
cp -R "${SOURCE_APP}" "${DMG_FOLDER}/"

# Create Applications symlink
ln -s /Applications "${DMG_FOLDER}/Applications"

# Create temporary DMG
hdiutil create -srcfolder "${DMG_FOLDER}" -volname "${VOLUME_NAME}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW "${DMG_TEMP}"

# Mount the temporary DMG
echo "🔧 Step 5: Customizing DMG appearance..."
MOUNT_DIR="/Volumes/${VOLUME_NAME}"
hdiutil attach "${DMG_TEMP}" -readwrite -noverify -noautoopen

# Wait for mount
sleep 2

# Set background and icon positions (optional)
# You can customize this section to add background image, icon positions, etc.

# Unmount
hdiutil detach "${MOUNT_DIR}"

# Step 5: Convert to final compressed DMG
echo "🗜️  Step 6: Compressing final DMG..."
hdiutil convert "${DMG_TEMP}" -format UDZO -imagekey zlib-level=9 -o "${DMG_FINAL}"

# Clean up
rm -f "${DMG_TEMP}"
rm -rf "${DMG_FOLDER}"

echo "✅ DMG created: ${DMG_FINAL}"
echo ""
echo "📊 DMG Info:"
ls -lh "${DMG_FINAL}"

# Step 6: Notarize with Apple (optional but recommended)
echo ""
echo "⚠️  NEXT STEP: Notarize with Apple"
echo "Run this command:"
echo "  xcrun notarytool submit ${DMG_FINAL} --keychain-profile \"AC_PASSWORD\" --wait"
echo ""
echo "After notarization succeeds, staple the ticket:"
echo "  xcrun stapler staple ${DMG_FINAL}"
echo ""
echo "Then verify:"
echo "  spctl -a -vvv -t install ${DMG_FINAL}"

echo ""
echo "🎉 Done! Upload ${DMG_FINAL} to openmoxie.org/download"
