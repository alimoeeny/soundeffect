#!/bin/bash
set -e
set -o pipefail
set -u

VERSION=${1:-}

if [ -z "$VERSION" ]; then
    echo "Usage: ./scripts/verify_release.sh <version>"
    echo "Example: ./scripts/verify_release.sh 1.0.13"
    exit 1
fi

echo "🔍 Verifying release v${VERSION}..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

# Function to print success
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
error() {
    echo -e "${RED}❌ $1${NC}"
    ERRORS=$((ERRORS + 1))
}

# Function to print warning
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Checking GitHub Release"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if release exists
RELEASE_URL="https://api.github.com/repos/alimoeeny/soundeffect/releases/tags/v${VERSION}"
if curl -s -f -I "$RELEASE_URL" > /dev/null 2>&1; then
    success "GitHub release v${VERSION} exists"
    
    # Check for ZIP file
    ZIP_URL="https://github.com/alimoeeny/soundeffect/releases/download/v${VERSION}/SoundEffect.zip"
    if curl -s -f -I "$ZIP_URL" > /dev/null 2>&1; then
        success "SoundEffect.zip found in release"
    else
        error "SoundEffect.zip NOT found in release"
    fi
    
    # Check for DMG file
    DMG_URL="https://github.com/alimoeeny/soundeffect/releases/download/v${VERSION}/SoundEffect-${VERSION}.dmg"
    if curl -s -f -I "$DMG_URL" > /dev/null 2>&1; then
        success "SoundEffect-${VERSION}.dmg found in release"
    else
        warning "SoundEffect-${VERSION}.dmg NOT found (optional for auto-updates)"
    fi
else
    error "GitHub release v${VERSION} NOT found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Checking Appcast Feed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

APPCAST_URL="https://ali.moeeny.com/soundeffect/appcast.xml"
APPCAST_CONTENT=$(curl -s "$APPCAST_URL")

if echo "$APPCAST_CONTENT" | grep -q "<title>Version ${VERSION}</title>"; then
    success "Appcast contains version ${VERSION}"
    
    # Extract build (sparkle:version) and short version
    APPCAST_BUILD=$(echo "$APPCAST_CONTENT" | grep -A 5 "Version ${VERSION}" | grep "<sparkle:version>" | sed -E 's/.*<sparkle:version>([^<]+)<\/sparkle:version>.*/\1/')
    APPCAST_SHORT=$(echo "$APPCAST_CONTENT" | grep -A 5 "Version ${VERSION}" | grep "<sparkle:shortVersionString>" | sed -E 's/.*<sparkle:shortVersionString>([^<]+)<\/sparkle:shortVersionString>.*/\1/')

    # Extract signature and length from appcast (needed for header checks below)
    APPCAST_SIGNATURE=$(echo "$APPCAST_CONTENT" | grep -A 5 "Version ${VERSION}" | grep "sparkle:edSignature" | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')
    APPCAST_LENGTH=$(echo "$APPCAST_CONTENT" | grep -A 5 "Version ${VERSION}" | grep "length=" | sed 's/.*length="\([^"]*\)".*/\1/')

    # Load current project build number (should be a single numeric value)
    PBX="SoundEffect.xcodeproj/project.pbxproj"
    BV_LINES=$(grep -E 'CURRENT_PROJECT_VERSION = ' "$PBX" | sed -E 's/.*CURRENT_PROJECT_VERSION = ([^;]+);/\1/' | sort -u)

    # Validate appcast build is numeric and matches CURRENT_PROJECT_VERSION
    if [[ "$APPCAST_BUILD" =~ ^[0-9]+$ ]]; then
        success "Appcast sparkle:version is numeric: ${APPCAST_BUILD}"
    else
        error "Appcast sparkle:version is NOT numeric: [${APPCAST_BUILD}]"
    fi

    if [ "$(echo "$BV_LINES" | wc -l | tr -d ' ')" -eq 1 ]; then
        if [ "$APPCAST_BUILD" = "$BV_LINES" ]; then
            success "Appcast sparkle:version matches CURRENT_PROJECT_VERSION (${APPCAST_BUILD})"
        else
            error "Appcast sparkle:version (${APPCAST_BUILD}) does NOT match CURRENT_PROJECT_VERSION (${BV_LINES})"
        fi
    else
        error "CURRENT_PROJECT_VERSION invalid or inconsistent in project: [${BV_LINES}]"
    fi

    # Validate shortVersionString matches the requested version
    if [ "$APPCAST_SHORT" = "$VERSION" ]; then
        success "Appcast shortVersionString matches ${VERSION}"
    else
        error "Appcast shortVersionString (${APPCAST_SHORT}) does NOT match ${VERSION}"
    fi

    # Optional: HEAD check ZIP Content-Length vs appcast length (no download)
    if curl -s -I -L "$ZIP_URL" > /tmp/se_zip_headers.$$; then
        HEAD_LEN=$(awk 'tolower($1)=="content-length:" {print $2}' /tmp/se_zip_headers.$$ | tr -d '\r')
        if [ -n "$HEAD_LEN" ] && [ -n "$APPCAST_LENGTH" ]; then
            if [ "$HEAD_LEN" = "$APPCAST_LENGTH" ]; then
                success "ZIP Content-Length matches appcast (${HEAD_LEN})"
            else
                warning "ZIP Content-Length (${HEAD_LEN}) differs from appcast (${APPCAST_LENGTH})"
            fi
        else
            warning "Unable to determine Content-Length from headers"
        fi
        rm -f /tmp/se_zip_headers.$$ || true
    else
        warning "HEAD request to ZIP_URL failed"
    fi

    # Extract signature and length from appcast
    APPCAST_SIGNATURE=$(echo "$APPCAST_CONTENT" | grep -A 5 "Version ${VERSION}" | grep "sparkle:edSignature" | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')
    APPCAST_LENGTH=$(echo "$APPCAST_CONTENT" | grep -A 5 "Version ${VERSION}" | grep "length=" | sed 's/.*length="\([^"]*\)".*/\1/')
    
    if [ -n "$APPCAST_SIGNATURE" ]; then
        success "Appcast has signature: ${APPCAST_SIGNATURE:0:40}..."
    else
        error "Appcast signature NOT found"
    fi
    
    if [ -n "$APPCAST_LENGTH" ]; then
        success "Appcast has length: ${APPCAST_LENGTH}"
    else
        error "Appcast length NOT found"
    fi
    
    # Check URL in appcast
    if echo "$APPCAST_CONTENT" | grep -q "v${VERSION}/SoundEffect.zip"; then
        success "Appcast URL points to correct ZIP file"
    else
        error "Appcast URL does NOT point to SoundEffect.zip"
    fi
else
    error "Appcast does NOT contain version ${VERSION}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Verifying ZIP File Signature"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Download ZIP
TMP_ZIP="/tmp/soundeffect-v${VERSION}.zip"
echo "Downloading ZIP from GitHub..."
if curl -L -s "$ZIP_URL" -o "$TMP_ZIP"; then
    success "ZIP downloaded successfully"
    
    # Get actual file size
    ACTUAL_SIZE=$(stat -f%z "$TMP_ZIP" 2>/dev/null || stat -c%s "$TMP_ZIP" 2>/dev/null)
    
    if [ "$ACTUAL_SIZE" = "$APPCAST_LENGTH" ]; then
        success "ZIP file size matches appcast ($ACTUAL_SIZE bytes)"
    else
        error "ZIP file size mismatch! Actual: $ACTUAL_SIZE, Appcast: $APPCAST_LENGTH"
    fi
    
    # Verify signature
    SPARKLE_BIN="$HOME/Downloads/Sparkle-for-Swift-Package-Manager/bin/sign_update"
    if [ -f "$SPARKLE_BIN" ]; then
        echo "Computing signature..."
        ACTUAL_SIGNATURE=$("$SPARKLE_BIN" "$TMP_ZIP" | awk '{print $1}')
        
        if [ "$ACTUAL_SIGNATURE" = "$APPCAST_SIGNATURE" ]; then
            success "Signature matches appcast!"
        else
            error "Signature MISMATCH!"
            echo "  Expected: $APPCAST_SIGNATURE"
            echo "  Actual:   $ACTUAL_SIGNATURE"
        fi
    else
        warning "Sparkle sign_update tool not found at $SPARKLE_BIN"
        echo "  Cannot verify signature"
    fi
    
    # Check for resource forks
    echo "Checking for resource forks..."
    if unzip -l "$TMP_ZIP" | grep -q "^\._"; then
        error "Resource fork files (._*) found in ZIP!"
        unzip -l "$TMP_ZIP" | grep "^\._"
    else
        success "No resource fork files in ZIP"
    fi
    
    # Clean up
    rm -f "$TMP_ZIP"
else
    error "Failed to download ZIP file"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Checking Info.plist Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

INFO_PLIST="SoundEffect/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    # Check SUFeedURL
    if grep -q "https://ali.moeeny.com/soundeffect/appcast.xml" "$INFO_PLIST"; then
        success "SUFeedURL is correct in Info.plist"
    else
        error "SUFeedURL is incorrect or missing in Info.plist"
    fi
    
    # Check SUPublicEDKey
    if grep -q "SUPublicEDKey" "$INFO_PLIST"; then
        success "SUPublicEDKey is present in Info.plist"
    else
        error "SUPublicEDKey is missing in Info.plist"
    fi
    
    # Check SUEnableAutomaticChecks
    if grep -q "SUEnableAutomaticChecks" "$INFO_PLIST"; then
        success "SUEnableAutomaticChecks is present in Info.plist"
    else
        warning "SUEnableAutomaticChecks is missing in Info.plist"
    fi
else
    error "Info.plist not found at $INFO_PLIST"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║  ✅  ALL CHECKS PASSED!                                        ║"
    echo "║                                                                ║"
    echo "║  Release v${VERSION} is ready for auto-update testing!        ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Install v1.0.12 (or earlier) from DMG"
    echo "  2. Click 'Check for Updates' in menu"
    echo "  3. Verify it detects v${VERSION} and installs successfully"
    exit 0
else
    echo -e "${RED}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║  ❌  FOUND $ERRORS ERROR(S)                                       ║"
    echo "║                                                                ║"
    echo "║  Please fix the issues above before testing auto-updates      ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    exit 1
fi
