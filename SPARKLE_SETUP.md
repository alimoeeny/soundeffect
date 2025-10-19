# Sparkle Auto-Update Setup

## Step 1: Add Sparkle Package

1. Open Xcode project
2. Go to **File → Add Package Dependencies...**
3. Enter URL: `https://github.com/sparkle-project/Sparkle`
4. Select version: **2.6.0** or later
5. Add to target: **SoundEffect**

## Step 2: Configure Info.plist Keys

Add these keys to your build settings (or create Info.plist):

```xml
<key>SUFeedURL</key>
<string>https://yourdomain.com/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>
<key>SUEnableAutomaticChecks</key>
<true/>
```

## Step 3: Generate Signing Keys

Run in Terminal:
```bash
./Pods/Sparkle/bin/generate_keys
```

Or if using SPM:
```bash
# Download Sparkle tools
curl -L https://github.com/sparkle-project/Sparkle/releases/latest/download/Sparkle-for-Swift-Package-Manager.zip -o Sparkle.zip
unzip Sparkle.zip
./generate_keys
```

This generates:
- **Public key** → Add to Info.plist as `SUPublicEDKey`
- **Private key** → Keep secure, use for signing releases

## Step 4: Create Appcast

Host an `appcast.xml` file at your `SUFeedURL`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>BadApple Updates</title>
    <link>https://yourdomain.com/appcast.xml</link>
    <description>Most recent updates to BadApple</description>
    <language>en</language>
    <item>
      <title>Version 1.0.0</title>
      <sparkle:version>1.0.0</sparkle:version>
      <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
      <pubDate>Sat, 19 Oct 2024 10:00:00 +0000</pubDate>
      <sparkle:releaseNotesLink>https://yourdomain.com/releasenotes/1.0.0.html</sparkle:releaseNotesLink>
      <enclosure 
        url="https://yourdomain.com/downloads/BadApple-1.0.0.zip"
        sparkle:edSignature="SIGNATURE_HERE"
        length="FILE_SIZE_IN_BYTES"
        type="application/octet-stream"
      />
    </item>
  </channel>
</rss>
```

## Step 5: Sign Releases

When releasing a new version:

```bash
./sign_update BadApple-1.0.0.zip
```

This outputs the signature to add to your appcast.

## Hosting Options

### Option A: GitHub Releases (Recommended)
- Free hosting
- Automatic with GitHub Actions
- Use `sparkle-project/generate-appcast` tool

### Option B: Your Own Server
- Full control
- Need HTTPS
- Host appcast.xml and .zip files

## Testing

1. Set a test feed URL
2. Build and run app
3. Click "Check for Updates" in menu
4. Sparkle will check the feed and show update UI

## Next Steps

1. Add Sparkle package in Xcode
2. Generate keys
3. Add public key to Info.plist
4. Set up hosting (GitHub or your server)
5. Test with a dummy update

## Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [GitHub Releases Guide](https://sparkle-project.org/documentation/publishing/#github-releases)
