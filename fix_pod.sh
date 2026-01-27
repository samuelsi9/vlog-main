#!/bin/bash
# Fix "pod not found" - create pod symlink from pod_old
# Run in your terminal: bash fix_pod.sh

GEM_BIN="$HOME/.gem/ruby/2.6.0/bin"
POD_OLD="$GEM_BIN/pod_old"

if [ ! -f "$POD_OLD" ]; then
  echo "❌ $POD_OLD not found. Install CocoaPods first (see install_cocoapods_no_homebrew.sh)"
  exit 1
fi

ln -sf pod_old "$GEM_BIN/pod"
echo "✅ Created: $GEM_BIN/pod -> pod_old"

# Ensure PATH
if ! grep -q '\.gem/ruby/2\.6\.0/bin' ~/.zshrc 2>/dev/null; then
  echo '' >> ~/.zshrc
  echo 'export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"' >> ~/.zshrc
  echo "✅ Added CocoaPods to ~/.zshrc"
fi

echo ""
echo "Run: source ~/.zshrc   (or open a new terminal)"
echo "Then: pod --version"
echo ""
