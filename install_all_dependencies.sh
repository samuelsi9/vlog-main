#!/bin/bash

# Comprehensive dependency installation script for Flutter vlog project
# This script installs all required dependencies

set -e  # Exit on error

echo "🚀 Starting complete dependency installation for VLog Flutter project..."
echo ""

PROJECT_DIR="/Users/samuelsi92023icloud.com/Downloads/vlog-main"
cd "$PROJECT_DIR"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Check and setup Homebrew
echo "📦 Step 1: Checking Homebrew installation..."
if ! command_exists brew; then
    echo -e "${YELLOW}Homebrew not found. Checking if installation is in progress...${NC}"
    
    # Check if Homebrew directories exist (installation might be in progress)
    if [ -d "/opt/homebrew" ] || [ -d "/usr/local/Homebrew" ]; then
        echo -e "${YELLOW}Homebrew directories found. Adding to PATH...${NC}"
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        elif [ -f "/usr/local/bin/brew" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
        fi
    else
        echo -e "${RED}Homebrew not installed. Please complete the Homebrew installation first.${NC}"
        echo "Run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
else
    echo -e "${GREEN}✅ Homebrew is installed${NC}"
    brew --version
fi

# Step 2: Install CocoaPods
echo ""
echo "📱 Step 2: Installing CocoaPods..."
if command_exists pod; then
    echo -e "${GREEN}✅ CocoaPods is already installed${NC}"
    pod --version
else
    if command_exists brew; then
        echo "Installing CocoaPods via Homebrew..."
        brew install cocoapods
        echo -e "${GREEN}✅ CocoaPods installed successfully${NC}"
        pod --version
    else
        echo -e "${YELLOW}Attempting to install CocoaPods via gem (may require newer Ruby)...${NC}"
        gem install cocoapods --user-install || {
            echo -e "${RED}Failed to install CocoaPods. Please install Homebrew first.${NC}"
            exit 1
        }
        export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
        echo 'export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"' >> ~/.zshrc
    fi
fi

# Step 3: Install Flutter dependencies
echo ""
echo "📦 Step 3: Installing Flutter dependencies (flutter pub get)..."
# Try to find Flutter in common locations
FLUTTER_PATH=""
if command_exists flutter; then
    FLUTTER_PATH="flutter"
elif [ -f "/Users/samuelsi92023icloud.com/flutter/bin/flutter" ]; then
    FLUTTER_PATH="/Users/samuelsi92023icloud.com/flutter/bin/flutter"
    export PATH="/Users/samuelsi92023icloud.com/flutter/bin:$PATH"
elif [ -f "$HOME/flutter/bin/flutter" ]; then
    FLUTTER_PATH="$HOME/flutter/bin/flutter"
    export PATH="$HOME/flutter/bin:$PATH"
fi

if [ -n "$FLUTTER_PATH" ]; then
    echo "Using Flutter at: $FLUTTER_PATH"
    $FLUTTER_PATH pub get
    echo -e "${GREEN}✅ Flutter dependencies installed${NC}"
else
    echo -e "${RED}Flutter not found. Please ensure Flutter is installed.${NC}"
    exit 1
fi

# Step 4: Install iOS pods
echo ""
echo "🍎 Step 4: Installing iOS CocoaPods dependencies..."
if [ -d "ios" ]; then
    cd ios
    if command_exists pod; then
        pod install
        echo -e "${GREEN}✅ iOS pods installed successfully${NC}"
    else
        echo -e "${RED}CocoaPods not found. Cannot install iOS dependencies.${NC}"
        exit 1
    fi
    cd ..
else
    echo -e "${YELLOW}⚠️  iOS directory not found. Skipping iOS pod installation.${NC}"
fi

# Step 5: Install macOS pods (if exists)
echo ""
echo "💻 Step 5: Installing macOS CocoaPods dependencies..."
if [ -d "macos" ]; then
    cd macos
    if command_exists pod; then
        pod install
        echo -e "${GREEN}✅ macOS pods installed successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  CocoaPods not found. Skipping macOS pod installation.${NC}"
    fi
    cd ..
else
    echo -e "${YELLOW}⚠️  macOS directory not found. Skipping macOS pod installation.${NC}"
fi

# Step 6: Verify Flutter setup
echo ""
echo "🔍 Step 6: Verifying Flutter setup..."
if [ -n "$FLUTTER_PATH" ]; then
    echo "Running flutter doctor..."
    $FLUTTER_PATH doctor || true  # Don't fail if doctor has warnings
    echo ""
    echo -e "${GREEN}✅ Flutter setup verification complete${NC}"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 All dependencies installation complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Summary:"
echo "  ✅ Homebrew: $(command_exists brew && echo 'Installed' || echo 'Not found')"
echo "  ✅ CocoaPods: $(command_exists pod && echo 'Installed' || echo 'Not found')"
echo "  ✅ Flutter dependencies: Installed"
echo "  ✅ iOS pods: $( [ -d "ios/Pods" ] && echo 'Installed' || echo 'Not installed' )"
echo ""
echo "🚀 You can now run your Flutter app with:"
echo "   flutter run"
echo ""
