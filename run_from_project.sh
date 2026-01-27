#!/bin/bash
# Toujours lancer ce script depuis le dossier du projet vlog-main

PROJECT_ROOT="/Users/samuelsi92023icloud.com/Downloads/vlog-main"

# Aller dans le projet
cd "$PROJECT_ROOT" || { echo "❌ Dossier projet introuvable: $PROJECT_ROOT"; exit 1; }

echo "✅ Répertoire actuel: $(pwd)"
echo ""

# Flutter pub get
if command -v flutter &>/dev/null; then
    echo "📦 flutter pub get..."
    flutter pub get
else
    echo "📦 flutter pub get..."
    /Users/samuelsi92023icloud.com/flutter/bin/flutter pub get 2>/dev/null || flutter pub get
fi

echo ""
echo "🍎 Pod install (ios)..."
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
cd "$PROJECT_ROOT/ios" && pod install && cd "$PROJECT_ROOT"

echo ""
echo "✅ Terminé. Vous pouvez lancer: flutter run"
