#!/bin/bash

# Install CocoaPods without Homebrew - using older version compatible with Ruby 2.6
# This script installs CocoaPods directly via gem, avoiding Homebrew dependency

set -e  # Exit on error

echo "🚀 Installing CocoaPods without Homebrew..."
echo "📱 Using older version compatible with Ruby 2.6"
echo ""

# Check Ruby version
RUBY_VERSION=$(ruby -v | grep -oE '[0-9]+\.[0-9]+' | head -1)
echo "Current Ruby version: $RUBY_VERSION"

# Set gem installation directory
GEM_HOME="$HOME/.gem/ruby/2.6.0"
GEM_BIN="$GEM_HOME/bin"

# Create directory if it doesn't exist
mkdir -p "$GEM_HOME"
mkdir -p "$GEM_BIN"

# Add to PATH for this session
export PATH="$GEM_BIN:$PATH"
export GEM_HOME="$GEM_HOME"

echo ""
echo "📦 Step 1: Installing older ffi gem (compatible with Ruby 2.6)..."
echo "   This is required for CocoaPods to work with Ruby 2.6..."
echo ""

# Install older ffi version that works with Ruby 2.6
if gem install ffi -v 1.15.5 --user-install --no-document; then
    echo "✅ ffi 1.15.5 installed successfully!"
elif gem install ffi -v 1.14.2 --user-install --no-document; then
    echo "✅ ffi 1.14.2 installed successfully!"
elif gem install ffi -v 1.13.1 --user-install --no-document; then
    echo "✅ ffi 1.13.1 installed successfully!"
else
    echo "⚠️  Could not install ffi, but continuing anyway..."
fi

echo ""
echo "📦 Step 2: Installing CocoaPods (compatible with Ruby 2.6)..."
echo "   This may take a few minutes depending on your connection..."
echo ""

# Try installing older CocoaPods versions that work with Ruby 2.6
SUCCESS=false

# Try CocoaPods 1.11.3 (known to work with Ruby 2.6)
if [ "$SUCCESS" = false ]; then
    echo "   Trying CocoaPods 1.11.3..."
    if gem install cocoapods -v 1.11.3 --user-install --no-document; then
        echo ""
        echo "✅ CocoaPods 1.11.3 installed successfully!"
        SUCCESS=true
    fi
fi

# Try CocoaPods 1.10.2
if [ "$SUCCESS" = false ]; then
    echo ""
    echo "   Trying CocoaPods 1.10.2..."
    if gem install cocoapods -v 1.10.2 --user-install --no-document; then
        echo ""
        echo "✅ CocoaPods 1.10.2 installed successfully!"
        SUCCESS=true
    fi
fi

# Try CocoaPods 1.9.3 (older, more compatible)
if [ "$SUCCESS" = false ]; then
    echo ""
    echo "   Trying CocoaPods 1.9.3..."
    if gem install cocoapods -v 1.9.3 --user-install --no-document; then
        echo ""
        echo "✅ CocoaPods 1.9.3 installed successfully!"
        SUCCESS=true
    fi
fi

if [ "$SUCCESS" = false ]; then
    echo ""
    echo "❌ Failed to install CocoaPods."
    echo ""
    echo "💡 Alternative solutions:"
    echo "   1. Try when your connection is better"
    echo "   2. Use a different network/VPN"
    echo "   3. Download CocoaPods gem file manually from rubygems.org"
    echo "   4. Consider upgrading Ruby to 3.0+ (requires Homebrew or rbenv)"
    exit 1
fi

# Verify installation
echo ""
echo "🔍 Verifying installation..."
if [ -f "$GEM_BIN/pod" ]; then
    "$GEM_BIN/pod" --version
    echo ""
    echo "✅ CocoaPods is installed at: $GEM_BIN/pod"
else
    echo "❌ CocoaPods executable not found"
    exit 1
fi

# Make it permanent by adding to .zshrc
echo ""
echo "📝 Adding CocoaPods to your PATH permanently..."
if ! grep -q "\.gem/ruby/2.6.0/bin" ~/.zshrc 2>/dev/null; then
    echo '' >> ~/.zshrc
    echo '# CocoaPods (installed via gem)' >> ~/.zshrc
    echo 'export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"' >> ~/.zshrc
    echo "✅ Added to ~/.zshrc"
else
    echo "✅ Already in ~/.zshrc"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 CocoaPods installation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Reload your shell configuration:"
echo "   source ~/.zshrc"
echo ""
echo "2. Verify CocoaPods is accessible:"
echo "   pod --version"
echo ""
echo "3. Install iOS dependencies:"
echo "   cd /Users/samuelsi92023icloud.com/Downloads/vlog-main/ios"
echo "   pod install"
echo ""
echo "💡 Note: If 'pod' command is not found, run:"
echo "   export PATH=\"\$HOME/.gem/ruby/2.6.0/bin:\$PATH\""
echo ""
