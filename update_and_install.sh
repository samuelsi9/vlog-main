#!/bin/bash
# Update CocoaPods + install all dependencies
# Run this from your terminal: bash update_and_install.sh

set -e

PROJECT="/Users/samuelsi92023icloud.com/Downloads/vlog-main"
cd "$PROJECT" || exit 1

echo "📁 Project: $(pwd)"
echo ""

# 1. Flutter dependencies
echo "📦 flutter pub get..."
if command -v flutter &>/dev/null; then
    flutter pub get
else
    /Users/samuelsi92023icloud.com/flutter/bin/flutter pub get
fi
echo "✅ Flutter dependencies done"
echo ""

# 2. CocoaPods PATH (and fix missing 'pod' -> use pod_old if needed)
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
[ ! -x "$HOME/.gem/ruby/2.6.0/bin/pod" ] && [ -x "$HOME/.gem/ruby/2.6.0/bin/pod_old" ] && ln -sf pod_old "$HOME/.gem/ruby/2.6.0/bin/pod" 2>/dev/null || true

# 3. Update CocoaPods repo
echo "🔄 pod repo update..."
pod repo update || echo "⚠️ repo update skipped (continuing...)"
echo ""

# 4. iOS pods - install/update
echo "🍎 pod install (ios)..."
cd "$PROJECT/ios"
pod install
cd "$PROJECT"
echo "✅ iOS pods done"
echo ""

# 5. macOS pods (optional)
if [ -d "$PROJECT/macos" ]; then
    echo "💻 pod install (macos)..."
    cd "$PROJECT/macos"
    pod install || true
    cd "$PROJECT"
    echo "✅ macOS pods done"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Update & install complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Run your app: cd $PROJECT && flutter run"
echo ""
