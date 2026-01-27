#!/bin/bash

# Script to install CocoaPods on macOS
# Tries multiple methods to work around Ruby version issues

echo "🚀 Starting CocoaPods installation..."
echo ""

# Method 1: Try installing older CocoaPods version compatible with Ruby 2.6
echo "📱 Attempting Method 1: Installing older CocoaPods version (compatible with Ruby 2.6)..."
if gem install cocoapods -v 1.10.2 --user-install 2>/dev/null; then
    echo "✅ Successfully installed CocoaPods 1.10.2"
    # Add to PATH
    export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
    echo 'export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"' >> ~/.zshrc
    
    if command -v pod &> /dev/null || [ -f "$HOME/.gem/ruby/2.6.0/bin/pod" ]; then
        echo "✅ CocoaPods is ready!"
        "$HOME/.gem/ruby/2.6.0/bin/pod" --version 2>/dev/null || echo "Run: export PATH=\"\$HOME/.gem/ruby/2.6.0/bin:\$PATH\""
        echo ""
        echo "🎉 Installation complete! Now run:"
        echo "   export PATH=\"\$HOME/.gem/ruby/2.6.0/bin:\$PATH\""
        echo "   cd ios && pod install"
        exit 0
    fi
else
    echo "❌ Method 1 failed (this is okay, trying next method...)"
    echo ""
fi

# Method 2: Check if Homebrew is installed
if command -v brew &> /dev/null; then
    echo "✅ Homebrew is already installed"
    echo "📱 Installing CocoaPods via Homebrew..."
    brew install cocoapods
    
    if command -v pod &> /dev/null; then
        echo "✅ CocoaPods installed successfully!"
        pod --version
        echo ""
        echo "🎉 Installation complete! Now run:"
        echo "   cd ios && pod install"
        exit 0
    fi
else
    echo "📦 Homebrew not found. Installing Homebrew..."
    echo "   (You'll need to enter your Mac password when prompted)"
    echo ""
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH
    if [ -f "/opt/homebrew/bin/brew" ]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
        brew install cocoapods
    elif [ -f "/usr/local/bin/brew" ]; then
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/usr/local/bin/brew shellenv)"
        brew install cocoapods
    fi
fi

# Verify installation
if command -v pod &> /dev/null; then
    echo "✅ CocoaPods installed successfully!"
    pod --version
    echo ""
    echo "🎉 Installation complete! Now run:"
    echo "   cd ios && pod install"
else
    echo "❌ Installation failed. Please try manually:"
    echo "   1. Enter your Mac password for Homebrew installation"
    echo "   2. Or try: gem install cocoapods -v 1.10.2 --user-install"
    exit 1
fi
