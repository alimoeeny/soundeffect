# Release Guide for SoundEffect

## Prerequisites

1. **Apple Developer Account** (required for notarization)
   - Enrolled in Apple Developer Program ($99/year)
   - Team ID: R9UTM4Y983

2. **App-Specific Password** for notarization
   - Go to https://appleid.apple.com
   - Sign in → App-Specific Passwords → Generate new password
   - Save it securely

3. **Notarization Credentials** stored in Keychain
   ```bash
   xcrun notarytool store-credentials "notarytool-profile" \
     --apple-id "your-apple-id@example.com" \
     --team-id "R9UTM4Y983" \
     --password "your-app-specific-password"
   ```

## Build & Release Process

### 1. Update Version Number

Edit `project.pbxproj` or use Xcode:
- `MARKETING_VERSION`: User-facing version (e.g., "1.0.0")
- `CURRENT_PROJECT_VERSION`: Build number (e.g., "1")

### 2. Build for Release

```bash
# Archive the app
xcodebuild archive \
  -project SoundEffect.xcodeproj \
  -scheme SoundEffect \
  -configuration Release \
  -archivePath ./build/SoundEffect.xcarchive

# Export the app
xcodebuild -exportArchive \
  -archivePath ./build/SoundEffect.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

### 3. Create DMG (Optional but Recommended)

```bash
# Install create-dmg if needed
brew install create-dmg

# Create DMG
create-dmg \
  --volname "SoundEffect" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "SoundEffect.app" 175 120 \
  --hide-extension "SoundEffect.app" \
  --app-drop-link 425 120 \
  "SoundEffect-1.0.0.dmg" \
  "./build/SoundEffect.app"
```

### 4. Sign and Notarize

```bash
# Sign the app (should already be signed from build)
codesign --force --deep --sign "Developer ID Application: Your Name (R9UTM4Y983)" \
  --options runtime \
  ./build/SoundEffect.app

# Verify signature
codesign --verify --verbose ./build/SoundEffect.app
spctl --assess --verbose ./build/SoundEffect.app

# Create ZIP for notarization
ditto -c -k --keepParent ./build/SoundEffect.app SoundEffect.zip

# Submit for notarization
xcrun notarytool submit SoundEffect.zip \
  --keychain-profile "notarytool-profile" \
  --wait

# Check status (if needed)
xcrun notarytool info <submission-id> \
  --keychain-profile "notarytool-profile"

# Staple the notarization ticket
xcrun stapler staple ./build/SoundEffect.app

# If using DMG, staple that too
xcrun stapler staple SoundEffect-1.0.0.dmg
```

### 5. Create GitHub Release

```bash
# Tag the release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Create release on GitHub
gh release create v1.0.0 \
  --title "SoundEffect v1.0.0" \
  --notes "Initial release" \
  SoundEffect-1.0.0.dmg
```

Or manually:
1. Go to https://github.com/your-username/SoundEffect/releases/new
2. Create new tag: `v1.0.0`
3. Release title: `SoundEffect v1.0.0`
4. Upload `SoundEffect-1.0.0.dmg`
5. Publish release

### 6. Update Sparkle Appcast

See `SPARKLE_SETUP.md` for generating the appcast.xml file.

## Automated Release Script

Create `scripts/release.sh`:

```bash
#!/bin/bash
set -e
set -o pipefail
set -u

VERSION=$1

echo "Building SoundEffect v${VERSION}..."

# Build
xcodebuild archive \
  -project SoundEffect.xcodeproj \
  -scheme SoundEffect \
  -configuration Release \
  -archivePath ./build/SoundEffect.xcarchive

xcodebuild -exportArchive \
  -archivePath ./build/SoundEffect.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist

# Create DMG
create-dmg \
  --volname "SoundEffect" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "SoundEffect.app" 175 120 \
  --hide-extension "SoundEffect.app" \
  --app-drop-link 425 120 \
  "SoundEffect-${VERSION}.dmg" \
  "./build/SoundEffect.app"

# Notarize
echo "Notarizing..."
ditto -c -k --keepParent ./build/SoundEffect.app SoundEffect.zip
xcrun notarytool submit SoundEffect.zip \
  --keychain-profile "notarytool-profile" \
  --wait

# Staple
xcrun stapler staple ./build/SoundEffect.app
xcrun stapler staple "SoundEffect-${VERSION}.dmg"

# Clean up
rm SoundEffect.zip

echo "✅ Release ready: SoundEffect-${VERSION}.dmg"
echo "Next steps:"
echo "1. git tag -a v${VERSION} -m 'Release version ${VERSION}'"
echo "2. git push origin v${VERSION}"
echo "3. Create GitHub release and upload DMG"
```

## Troubleshooting

### Notarization Fails
- Check logs: `xcrun notarytool log <submission-id> --keychain-profile "notarytool-profile"`
- Common issues:
  - Missing hardened runtime
  - Missing entitlements
  - Unsigned frameworks

### Gatekeeper Blocks App
- Ensure app is properly signed and notarized
- Users can bypass: Right-click → Open (first time only)

### Sparkle Updates Fail
- Check network entitlements (currently disabled in sandbox)
- May need to enable outgoing connections for updates

## Security Checklist

- [ ] App is code-signed with Developer ID
- [ ] Hardened Runtime is enabled
- [ ] App is notarized by Apple
- [ ] Notarization ticket is stapled
- [ ] DMG is also stapled (if using)
- [ ] Sparkle updates are signed (see SPARKLE_SETUP.md)
- [ ] SUFeedURL points to HTTPS endpoint

## Resources

- [Apple Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
