# Auto-Update Setup - Lessons Learned

## Overview

Successfully implemented Sparkle auto-updates for SoundEffect. This document captures the key learnings and gotchas encountered during setup.

## Critical Requirements

### 1. Network Permissions (THE BIG ONE!)

**Problem**: App showed DNS errors when checking for updates:
```
Error: A server with the specified hostname could not be found.
DNS Error: ServiceNotRunning
```

**Solution**: Enable outgoing network connections in project settings:
```
ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES
```

**Why**: Sandboxed macOS apps need explicit permission for network access. Without this, the app cannot resolve DNS or make HTTP requests, even though the system DNS works fine.

### 2. Info.plist Configuration

**Problem**: Using `INFOPLIST_KEY_*` prefix in build settings doesn't work for custom Sparkle keys.

**Solution**: Create a proper `Info.plist` file with:
```xml
<key>SUFeedURL</key>
<string>https://ali.moeeny.com/soundeffect/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>XKgGKVApq/5CtJcdYv47pC9nsqn+KwUPyRb/r3H9hyQ=</string>
<key>SUEnableAutomaticChecks</key>
<true/>
```

And set in project:
```
GENERATE_INFOPLIST_FILE = NO
INFOPLIST_FILE = SoundEffect/Info.plist
```

### 3. Appcast XML Formatting

**Problem**: Shell escaping added backslashes to XML tags:
```xml
<link>https://ali.moeeny.com/soundeffect/appcast.xml\</link\>
```

**Solution**: Create XML file manually in text editor, not via shell heredoc. The backslashes break XML parsing in Sparkle.

### 4. Custom Domain Redirects

**Problem**: GitHub Pages redirects `alimoeeny.github.io` → `ali.moeeny.com`

**Solution**: Use the final custom domain URL in `SUFeedURL`, not the github.io URL.

## Setup Steps (Correct Order)

1. **Generate Sparkle Keys**
   ```bash
   ~/Downloads/Sparkle-for-Swift-Package-Manager/bin/generate_keys
   ```
   Save private key securely (1Password, etc.)

2. **Create Info.plist**
   - Add all required bundle keys (`CFBundleIdentifier`, etc.)
   - Add Sparkle keys (`SUFeedURL`, `SUPublicEDKey`, `SUEnableAutomaticChecks`)
   - Use custom domain URL

3. **Enable Network Access**
   - Set `ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES` in both Debug and Release configs

4. **Set Up GitHub Pages**
   ```bash
   git checkout --orphan gh-pages
   git rm -rf .
   echo "<html><body>Updates</body></html>" > index.html
   git add index.html
   git commit -m "Initial gh-pages"
   git push origin gh-pages
   ```

5. **Enable GitHub Pages in Repo Settings**
   - Settings → Pages → Source: gh-pages branch

## Release Process (CRITICAL ORDER!)

**⚠️ IMPORTANT**: You MUST sign the release files BEFORE uploading to GitHub. The signature is cryptographically tied to the exact file contents!

6. **Build, Notarize, and Sign Release**
   ```bash
   rm -rf build/
   ./scripts/release.sh 1.0.x
   ```
   This automatically:
   - Builds and notarizes the app
   - Creates `SoundEffect.zip` and signs it with Sparkle
   - Creates `SoundEffect-1.0.x.dmg` for manual downloads
   - Displays the Sparkle signature at the end
   
   **IMPORTANT**: Copy the signature output! You'll need it for the appcast.

7. **Create GitHub Release and Upload Files**
   ```bash
   git tag -a v1.0.x -m 'Release version 1.0.x'
   git push origin v1.0.x
   ```
   Then on GitHub:
   - Create release for tag v1.0.x
   - Upload `SoundEffect.zip` from `./build/` (already signed!)
   - Upload `SoundEffect-1.0.x.dmg` for manual downloads
   - **DO NOT modify files after uploading!**

8. **Create Appcast XML**
   - Create manually in text editor (avoid shell heredoc)
   - Use **ZIP file** URL (not DMG) for the enclosure
   - Include signature from step 6 output
   - Verify no backslashes in tags
   
   Example:
   ```xml
   <enclosure 
     url="https://github.com/alimoeeny/soundeffect/releases/download/v1.0.x/SoundEffect.zip"
     sparkle:edSignature="SIGNATURE_FROM_BUILD_OUTPUT"
     length="LENGTH_FROM_BUILD_OUTPUT"
     type="application/octet-stream"
   />
   ```

9. **Deploy Appcast to GitHub Pages**
    ```bash
    git checkout gh-pages
    cp appcast.xml .
    git add appcast.xml
    git commit -m "Update appcast for v1.0.x"
    git push origin gh-pages
    git checkout develop
    ```

10. **Test**
    - Install app
    - Click "Check for Updates"
    - Should detect new version and install successfully!

## Common Errors and Solutions

### "An error occurred while launching the installer"

**Cause**: Signature mismatch! You uploaded files to GitHub BEFORE signing them with `sign_update`.

**Solution**: 
1. Delete the release assets from GitHub
2. Sign the files in `./build/` with `sign_update`
3. Upload the SIGNED files to GitHub
4. Update appcast with the new signature
5. Never modify files after signing!

### "An error occurred in retrieving update information"

**Causes**:
1. Missing network permissions → Enable `ENABLE_OUTGOING_NETWORK_CONNECTIONS`
2. Invalid XML (backslashes) → Create XML manually
3. Wrong URL in `SUFeedURL` → Use final custom domain
4. Missing Sparkle keys in Info.plist → Create proper Info.plist file

### "Archive Missing Bundle Identifier"

**Cause**: Info.plist missing required keys

**Solution**: Add all standard bundle keys:
- `CFBundleIdentifier`
- `CFBundleName`
- `CFBundleVersion`
- `CFBundleShortVersionString`
- `CFBundleExecutable`
- `CFBundlePackageType`

### DNS Resolution Fails

**Cause**: Sandbox blocking network access

**Solution**: Enable outgoing network connections in entitlements

## File Structure

```
SoundEffect/
├── SoundEffect/
│   └── Info.plist          # Contains Sparkle config
├── SoundEffect.xcodeproj/
│   └── project.pbxproj     # ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES
├── appcast.xml             # Gitignored, for local testing
└── scripts/
    └── release.sh          # Build, sign, notarize
```

## GitHub Pages Structure

```
gh-pages branch:
├── index.html
└── appcast.xml             # The actual feed file
```

## Appcast XML Template

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>SoundEffect Updates</title>
    <link>https://ali.moeeny.com/soundeffect/appcast.xml</link>
    <description>SoundEffect app updates</description>
    <language>en</language>
    <item>
      <title>Version X.Y.Z</title>
      <sparkle:version>X.Y.Z</sparkle:version>
      <sparkle:shortVersionString>X.Y.Z</sparkle:shortVersionString>
      <pubDate>Day, DD Mon YYYY HH:MM:SS -0400</pubDate>
      <description><![CDATA[
        <h2>SoundEffect vX.Y.Z</h2>
        <ul>
          <li>Feature 1</li>
          <li>Feature 2</li>
        </ul>
      ]]></description>
      <enclosure 
        url="https://github.com/alimoeeny/soundeffect/releases/download/vX.Y.Z/SoundEffect-X.Y.Z.dmg"
        sparkle:edSignature="SIGNATURE_FROM_SIGN_UPDATE"
        length="FILE_SIZE_IN_BYTES"
        type="application/octet-stream"
      />
    </item>
  </channel>
</rss>
```

## Testing Checklist

### Pre-Release Verification
- [ ] Run `./scripts/verify_release.sh <version>` to validate:
  - [ ] GitHub release exists with ZIP and DMG files
  - [ ] Appcast XML is live and contains the new version
  - [ ] ZIP signature matches between GitHub and appcast
  - [ ] File size matches the `length` attribute
  - [ ] No resource fork files in ZIP
  - [ ] Info.plist has correct Sparkle configuration

### Manual Testing
- [ ] Build app with network permissions enabled
- [ ] Install app from DMG
- [ ] Check "About" shows correct version
- [ ] Click "Check for Updates"
- [ ] Verify no DNS errors in Console
- [ ] Confirm update dialog appears
- [ ] Test update installation
- [ ] Verify app restarts with new version

## Key Takeaways

1. **Network permissions are mandatory** for sandboxed apps doing HTTP requests
2. **Info.plist must be explicit** - build setting keys don't work for custom frameworks
3. **XML formatting matters** - shell escaping can break parsers
4. **Test with Console.app** - shows exact Sparkle errors
5. **Custom domains need final URL** - not the redirect source
6. **Always verify before testing** - Use `verify_release.sh` script to catch issues before manual testing
7. **Signature must match exactly** - Download the uploaded ZIP and verify signature matches appcast
8. **File size matters** - The `length` attribute in appcast must match the actual ZIP file size

## Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sandboxing Guide](https://developer.apple.com/documentation/security/app_sandbox)
- [Info.plist Keys](https://developer.apple.com/documentation/bundleresources/information_property_list)

## Version History

- **v1.0.2**: Initial Sparkle integration (broken - no network access)
- **v1.0.3**: Added Info.plist (broken - still no network)
- **v1.0.4**: Updated feed URL to custom domain (broken - still no network)
- **v1.0.5**: Dynamic version in About (broken - still no network)
- **v1.0.6**: ✅ **WORKING** - Enabled network permissions!
- **v1.0.7-1.0.11**: Various attempts to fix installer errors (signature issues, resource forks, sandboxing)
- **v1.0.12**: ✅ **Auto-updates fully working** - Disabled sandbox in project settings
- **v1.0.13**: ✅ **First successful auto-update** - Updated from v1.0.12 via Sparkle!

## Tools

- **`scripts/release.sh`** - Automated build, notarize, sign, and package script
- **`scripts/verify_release.sh`** - Pre-release verification to catch issues before testing

---

**Last Updated**: November 2, 2024
