#!/bin/bash

# Clean reinstall script - Removes old dependencies and reinstalls everything fresh
# This should fix performance issues and ensure everything works properly

set -e

echo "🧹 Starting clean reinstall of all dependencies..."
echo "   This will remove old files and reinstall everything fresh"
echo ""

PROJECT_DIR="/Users/samuelsi92023icloud.com/Downloads/vlog-main"
cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Step 1: Clean Flutter
echo "📦 Step 1: Cleaning Flutter cache and build files..."
FLUTTER_PATH="/Users/samuelsi92023icloud.com/flutter/bin/flutter"

if [ -f "$FLUTTER_PATH" ]; then
    echo "   Cleaning Flutter..."
    $FLUTTER_PATH clean
    echo -e "${GREEN}✅ Flutter cleaned${NC}"
else
    echo -e "${YELLOW}⚠️  Flutter not found at expected path${NC}"
fi

# Step 2: Clean iOS pods
echo ""
echo "🍎 Step 2: Cleaning iOS CocoaPods..."
if [ -d "ios" ]; then
    cd ios
    echo "   Removing old Pods..."
    rm -rf Pods Podfile.lock .symlinks
    echo -e "${GREEN}✅ iOS pods cleaned${NC}"
    cd ..
else
    echo -e "${YELLOW}⚠️  iOS directory not found${NC}"
fi

# Step 3: Clean macOS pods
echo ""
echo "💻 Step 3: Cleaning macOS CocoaPods..."
if [ -d "macos" ]; then
    cd macos
    rm -rf Pods Podfile.lock .symlinks 2>/dev/null || true
    echo -e "${GREEN}✅ macOS pods cleaned${NC}"
    cd ..
fi

# Step 4: Clean build directories
echo ""
echo "🗑️  Step 4: Removing build directories..."
rm -rf build ios/build macos/build android/build 2>/dev/null || true
echo -e "${GREEN}✅ Build directories cleaned${NC}"

# Step 5: Reinstall Flutter dependencies
echo ""
echo "📦 Step 5: Reinstalling Flutter dependencies..."
if [ -f "$FLUTTER_PATH" ]; then
    $FLUTTER_PATH pub get
    echo -e "${GREEN}✅ Flutter dependencies reinstalled${NC}"
else
    if command -v flutter &> /dev/null; then
        flutter pub get
        echo -e "${GREEN}✅ Flutter dependencies reinstalled${NC}"
    else
        echo -e "${RED}❌ Flutter not found${NC}"
        exit 1
    fi
fi

# Step 6: Setup CocoaPods PATH
echo ""
echo "🍎 Step 6: Setting up CocoaPods..."
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"

# Verify CocoaPods
if command -v pod &> /dev/null || [ -f "$HOME/.gem/ruby/2.6.0/bin/pod" ]; then
    POD_VERSION=$(pod --version 2>/dev/null || "$HOME/.gem/ruby/2.6.0/bin/pod" --version 2>/dev/null)
    echo "   CocoaPods version: $POD_VERSION"
else
    echo -e "${RED}❌ CocoaPods not found. Please run install_cocoapods_no_homebrew.sh first${NC}"
    exit 1
fi

# Step 7: Reinstall iOS pods
echo ""
echo "📱 Step 7: Reinstalling iOS CocoaPods dependencies..."
echo "   This may take 5-15 minutes depending on your connection..."
if [ -d "ios" ]; then
    cd ios
    pod install --repo-update
    echo -e "${GREEN}✅ iOS pods reinstalled${NC}"
    cd ..
else
    echo -e "${YELLOW}⚠️  iOS directory not found${NC}"
fi

# Step 8: Reinstall macOS pods (optional)
echo ""
echo "💻 Step 8: Reinstalling macOS CocoaPods dependencies..."
if [ -d "macos" ]; then
    cd macos
    pod install --repo-update 2>/dev/null || echo -e "${YELLOW}⚠️  macOS pod install skipped (optional)${NC}"
    cd ..
fi

# Step 9: Verify installation
echo ""
echo "🔍 Step 9: Verifying installation..."
if [ -d "ios/Pods" ]; then
    POD_COUNT=$(find ios/Pods -maxdepth 1 -type d | wc -l)
    echo -e "${GREEN}✅ iOS Pods installed: $((POD_COUNT - 1)) pods${NC}"
else
    echo -e "${YELLOW}⚠️  iOS Pods directory not found${NC}"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Clean reinstall complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 What was done:"
echo "  ✅ Cleaned Flutter cache and build files"
echo "  ✅ Removed old iOS/macOS pods"
echo "  ✅ Reinstalled Flutter dependencies"
echo "  ✅ Reinstalled iOS CocoaPods dependencies"
echo ""
echo "🚀 Your app should now run faster and smoother!"
echo ""
echo "💡 Next steps:"
echo "   1. Run your app: flutter run"
echo "   2. Or open in Xcode: open ios/Runner.xcworkspace"
echo ""
