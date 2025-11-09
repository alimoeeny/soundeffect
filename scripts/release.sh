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

PBX="SoundEffect.xcodeproj/project.pbxproj"
PLIST="SoundEffect/Info.plist"
echo "🔎 Verifying project version settings..."
MV_LINES=$(grep -E 'MARKETING_VERSION = ' "$PBX" | sed -E 's/.*MARKETING_VERSION = ([^;]+);/\1/' | sort -u)
if [ "$(echo "$MV_LINES" | wc -l | tr -d ' ')" -ne 1 ] || [ "$MV_LINES" != "$VERSION" ]; then
    echo "❌ MARKETING_VERSION mismatch. Found: [$MV_LINES] Expected: [$VERSION]"
    exit 1
fi
BV_LINES=$(grep -E 'CURRENT_PROJECT_VERSION = ' "$PBX" | sed -E 's/.*CURRENT_PROJECT_VERSION = ([^;]+);/\1/' | sort -u)
if [ "$(echo "$BV_LINES" | wc -l | tr -d ' ')" -ne 1 ] || ! [[ "$BV_LINES" =~ ^[0-9]+$ ]]; then
    echo "❌ CURRENT_PROJECT_VERSION invalid or inconsistent. Found: [$BV_LINES]"
    exit 1
fi
if ! grep -Fq '$(MARKETING_VERSION)' "$PLIST"; then
    echo "❌ Info.plist CFBundleShortVersionString is not using $(MARKETING_VERSION)"
    exit 1
fi
if ! grep -Fq '$(CURRENT_PROJECT_VERSION)' "$PLIST"; then
    echo "❌ Info.plist CFBundleVersion is not using $(CURRENT_PROJECT_VERSION)"
    exit 1
fi
echo "✅ Version checks passed."

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
ditto -c -k --keepParent --norsrc ./build/SoundEffect.app ./build/SoundEffect.zip

# Notarize
echo "📝 Submitting for notarization..."
echo "   (This may take a few minutes...)"
xcrun notarytool submit ./build/SoundEffect.zip \
  --keychain-profile "notarytool-profile" \
  --wait

# Staple the notarization ticket
echo "📎 Stapling notarization ticket..."
xcrun stapler staple ./build/SoundEffect.app

# Sign the ZIP for Sparkle BEFORE creating DMG
echo "🔐 Signing ZIP for Sparkle..."
SPARKLE_SIGNATURE=$(~/Downloads/Sparkle-for-Swift-Package-Manager/bin/sign_update ./build/SoundEffect.zip)
echo "✅ Sparkle signature: $SPARKLE_SIGNATURE"

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
echo "📦 Files ready for release:"
echo "   - ./build/SoundEffect.zip (SIGNED for auto-updates)"
echo "   - ./build/SoundEffect-${VERSION}.dmg (for manual downloads)"
echo ""
echo "🔐 Sparkle signature (already applied):"
echo "$SPARKLE_SIGNATURE"
echo ""
echo "📋 Next steps:"
echo ""
echo "   1. Create and push git tag:"
echo "      git tag -a v${VERSION} -m 'Release version ${VERSION}'"
echo "      git push origin v${VERSION}"
echo ""
echo "   2. Create GitHub release and upload files:"
echo "      - Upload ./build/SoundEffect.zip (for auto-updates)"
echo "      - Upload ./build/SoundEffect-${VERSION}.dmg (for manual downloads)"
echo ""
echo "   3. Update appcast.xml with the signature shown above"
echo ""
echo "   4. Deploy appcast to gh-pages:"
echo "      git checkout gh-pages"
echo "      cp appcast.xml ."
echo "      git add appcast.xml"
echo "      git commit -m 'Update appcast for v${VERSION}'"
echo "      git push origin gh-pages"
echo "      git checkout develop"
echo ""
