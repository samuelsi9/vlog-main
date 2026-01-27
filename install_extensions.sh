#!/bin/bash
# Install Cursor extensions - run in your terminal: bash install_extensions.sh

CURSOR="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"

if [ ! -f "$CURSOR" ]; then
  echo "❌ Cursor CLI not found at $CURSOR"
  exit 1
fi

echo "📦 Installing Cursor extensions..."
echo ""

"$CURSOR" --install-extension Dart-Code.flutter --force
"$CURSOR" --install-extension Dart-Code.dart-code --force
"$CURSOR" --install-extension PKief.material-icon-theme --force
"$CURSOR" --install-extension usernamehw.errorlens --force
"$CURSOR" --install-extension zhuangtongfa.Material-theme --force

echo ""
echo "✅ Done! Restart Cursor to apply extensions."
