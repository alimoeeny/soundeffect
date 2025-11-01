#!/bin/bash
set -e
set -o pipefail
set -u

VERSION=${1:-}

if [ -z "$VERSION" ]; then
    echo "Usage: ./scripts/release.sh <version>"
    echo "Example: ./scripts/release.sh 1.0.0"
    exit 1
fi

echo "🚀 Building SoundEffect v${VERSION}..."

# Clean previous builds
rm -rf ./build
mkdir -p ./build

# Archive the app
echo "📦 Archiving..."
xcodebuild archive \
  -project SoundEffect.xcodeproj \
  -scheme SoundEffect \
  -configuration Release \
  -archivePath ./build/SoundEffect.xcarchive \
  | xcpretty || true

# Export the app
echo "📤 Exporting..."
xcodebuild -exportArchive \
  -archivePath ./build/SoundEffect.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist \
  | xcpretty || true

# Verify signing
echo "🔐 Verifying code signature..."
codesign --verify --verbose ./build/SoundEffect.app
spctl --assess --verbose ./build/SoundEffect.app

# Create ZIP for notarization
echo "🗜️  Creating ZIP..."
ditto -c -k --keepParent ./build/SoundEffect.app ./build/SoundEffect.zip

# Notarize
echo "📝 Submitting for notarization..."
echo "   (This may take a few minutes...)"
xcrun notarytool submit ./build/SoundEffect.zip \
  --keychain-profile "notarytool-profile" \
  --wait

# Staple the notarization ticket
echo "📎 Stapling notarization ticket..."
xcrun stapler staple ./build/SoundEffect.app

# Create DMG (if create-dmg is installed)
if command -v create-dmg &> /dev/null; then
    echo "💿 Creating DMG..."
    create-dmg \
      --volname "SoundEffect" \
      --window-pos 200 120 \
      --window-size 600 400 \
      --icon-size 100 \
      --icon "SoundEffect.app" 175 120 \
      --hide-extension "SoundEffect.app" \
      --app-drop-link 425 120 \
      "./build/SoundEffect-${VERSION}.dmg" \
      "./build/SoundEffect.app" || true

    # Notarize and staple DMG
    if [ -f "./build/SoundEffect-${VERSION}.dmg" ]; then
        echo "📝 Notarizing DMG..."
        xcrun notarytool submit "./build/SoundEffect-${VERSION}.dmg" \
          --keychain-profile "notarytool-profile" \
          --wait
        
        echo "📎 Stapling DMG..."
        xcrun stapler staple "./build/SoundEffect-${VERSION}.dmg" || echo "⚠️  DMG stapling failed (app is still notarized)"
        echo "✅ DMG created: ./build/SoundEffect-${VERSION}.dmg"
    fi
else
    echo "⚠️  create-dmg not found. Install with: brew install create-dmg"
    echo "   Creating ZIP instead..."
    cd ./build
    ditto -c -k --keepParent SoundEffect.app "SoundEffect-${VERSION}.zip"
    cd ..
    echo "✅ ZIP created: ./build/SoundEffect-${VERSION}.zip"
fi

echo ""
echo "✅ Release build complete!"
echo ""
echo "📋 Next steps (IN THIS ORDER!):"
echo ""
echo "   1. Sign the ZIP for Sparkle:"
echo "      ~/Downloads/Sparkle-for-Swift-Package-Manager/bin/sign_update ./build/SoundEffect.zip"
echo "      (Save the signature and length output!)"
echo ""
echo "   2. Create and push git tag:"
echo "      git tag -a v${VERSION} -m 'Release version ${VERSION}'"
echo "      git push origin v${VERSION}"
echo ""
echo "   3. Create GitHub release and upload SIGNED files:"
echo "      - Upload ./build/SoundEffect.zip (for auto-updates)"
echo "      - Upload ./build/SoundEffect-${VERSION}.dmg (for manual downloads)"
echo ""
echo "   4. Update appcast.xml with:"
echo "      - URL: https://github.com/alimoeeny/soundeffect/releases/download/v${VERSION}/SoundEffect.zip"
echo "      - Signature from step 1"
echo "      - Length from step 1"
echo ""
echo "   5. Deploy appcast to gh-pages:"
echo "      git checkout gh-pages"
echo "      cp appcast.xml ."
echo "      git add appcast.xml"
echo "      git commit -m 'Update appcast for v${VERSION}'"
echo "      git push origin gh-pages"
echo "      git checkout develop"
echo ""
echo "⚠️  CRITICAL: Sign files BEFORE uploading to GitHub!"
echo ""
