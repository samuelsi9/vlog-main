#!/bin/bash

# Complete setup script - Install all remaining dependencies
# Run this after CocoaPods is installed

set -e

echo "🚀 Completing VLog Flutter project setup..."
echo ""

PROJECT_DIR="/Users/samuelsi92023icloud.com/Downloads/vlog-main"
cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Install Flutter dependencies
echo "📦 Step 1: Installing Flutter dependencies..."
FLUTTER_PATH="/Users/samuelsi92023icloud.com/flutter/bin/flutter"
if [ -f "$FLUTTER_PATH" ]; then
    $FLUTTER_PATH pub get
    echo -e "${GREEN}✅ Flutter dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠️  Flutter not found at expected path${NC}"
    if command -v flutter &> /dev/null; then
        flutter pub get
        echo -e "${GREEN}✅ Flutter dependencies installed${NC}"
    else
        echo "❌ Flutter not found. Please ensure Flutter is installed."
        exit 1
    fi
fi

# Step 2: Setup CocoaPods PATH
echo ""
echo "🍎 Step 2: Setting up CocoaPods..."
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"

# Verify CocoaPods
if command -v pod &> /dev/null; then
    echo "CocoaPods version: $(pod --version)"
else
    echo -e "${YELLOW}⚠️  CocoaPods not in PATH. Adding...${NC}"
    if [ -f "$HOME/.gem/ruby/2.6.0/bin/pod" ]; then
        export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
        echo "✅ CocoaPods found"
    else
        echo "❌ CocoaPods not found. Please run install_cocoapods_no_homebrew.sh first."
        exit 1
    fi
fi

# Step 3: Install iOS pods
echo ""
echo "📱 Step 3: Installing iOS CocoaPods dependencies..."
if [ -d "ios" ]; then
    cd ios
    pod install
    echo -e "${GREEN}✅ iOS pods installed successfully${NC}"
    cd ..
else
    echo -e "${YELLOW}⚠️  iOS directory not found${NC}"
fi

# Step 4: Install macOS pods (optional)
echo ""
echo "💻 Step 4: Installing macOS CocoaPods dependencies (if needed)..."
if [ -d "macos" ]; then
    cd macos
    pod install || echo -e "${YELLOW}⚠️  macOS pod install had issues (this is okay if you're not building for macOS)${NC}"
    cd ..
else
    echo -e "${YELLOW}⚠️  macOS directory not found (this is okay)${NC}"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Summary:"
echo "  ✅ Flutter dependencies: Installed"
echo "  ✅ CocoaPods: $(pod --version)"
echo "  ✅ iOS pods: $([ -d "ios/Pods" ] && echo 'Installed' || echo 'Not installed')"
echo ""
echo "🚀 You can now run your app:"
echo "   cd $PROJECT_DIR"
echo "   flutter run"
echo ""
echo "💡 Note: If you see Android SDK or Chrome warnings, those are optional."
echo "   You can develop for iOS without them."
echo ""
