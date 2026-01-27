#!/bin/bash
# Install Homebrew - run this in your terminal

echo "🍺 Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo ""
echo "📝 Add Homebrew to your PATH (run the commands shown above, or):"
echo '   eval "$(/opt/homebrew/bin/brew shellenv)"'
echo '   echo ''eval "$(/opt/homebrew/bin/brew shellenv)"'' >> ~/.zshrc'
echo ""
