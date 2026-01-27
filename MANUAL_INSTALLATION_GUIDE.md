# Manual Installation Guide - Without Homebrew

This guide helps you install all dependencies for the VLog Flutter project **without using Homebrew**, which is useful if you have connection issues.

## 🎯 Quick Start

Run this script in your terminal:

```bash
cd /Users/samuelsi92023icloud.com/Downloads/vlog-main
./install_cocoapods_no_homebrew.sh
```

## 📋 Step-by-Step Manual Installation

### Step 1: Install CocoaPods (Without Homebrew)

Since you have Ruby 2.6, we'll install an older CocoaPods version that's compatible:

```bash
# Install CocoaPods 1.13.0 (compatible with Ruby 2.6)
gem install cocoapods -v 1.13.0 --user-install --no-document
```

**If that fails**, try version 1.10.2:

```bash
gem install cocoapods -v 1.10.2 --user-install --no-document
```

**Add CocoaPods to your PATH:**

```bash
# Add to your shell configuration
echo 'export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"' >> ~/.zshrc

# Reload your shell
source ~/.zshrc

# Verify installation
pod --version
```

### Step 2: Install Flutter Dependencies

```bash
cd /Users/samuelsi92023icloud.com/Downloads/vlog-main

# Use your Flutter installation
/Users/samuelsi92023icloud.com/flutter/bin/flutter pub get
```

### Step 3: Install iOS CocoaPods Dependencies

```bash
cd /Users/samuelsi92023icloud.com/Downloads/vlog-main/ios

# Make sure CocoaPods is in PATH
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"

# Install pods
pod install
```

### Step 4: Install macOS CocoaPods Dependencies (Optional)

```bash
cd /Users/samuelsi92023icloud.com/Downloads/vlog-main/macos
pod install
```

## 🔧 Troubleshooting

### If CocoaPods Installation Fails

**Option A: Install with specific dependencies**

```bash
gem install activesupport -v 6.1.7.6 --user-install --no-document
gem install cocoapods -v 1.10.2 --user-install --no-document
```

**Option B: Download gem file manually** (if connection is very poor)

1. Download the CocoaPods gem file from: https://rubygems.org/gems/cocoapods/versions/1.13.0
2. Save it to your Downloads folder
3. Install from local file:
   ```bash
   gem install ~/Downloads/cocoapods-1.13.0.gem --user-install
   ```

### If "pod" command not found

Make sure CocoaPods is in your PATH:

```bash
# Check if it exists
ls -la ~/.gem/ruby/2.6.0/bin/pod

# If it exists, add to PATH
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"

# Test
pod --version
```

### If pod install fails

1. **Clean and retry:**
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   ```

2. **Update CocoaPods repo:**
   ```bash
   pod repo update
   ```

## ✅ Verification

After installation, verify everything works:

```bash
# Check CocoaPods
pod --version

# Check Flutter
/Users/samuelsi92023icloud.com/flutter/bin/flutter doctor

# Check iOS pods
cd /Users/samuelsi92023icloud.com/Downloads/vlog-main/ios
ls -la Pods  # Should show Pods directory
```

## 🚀 Running the App

Once all dependencies are installed:

```bash
cd /Users/samuelsi92023icloud.com/Downloads/vlog-main

# Run on iOS simulator/device
/Users/samuelsi92023icloud.com/flutter/bin/flutter run

# Or build for iOS
/Users/samuelsi92023icloud.com/flutter/bin/flutter build ios
```

## 📝 Notes

- **Ruby Version**: This guide uses Ruby 2.6.10 which comes with macOS
- **CocoaPods Version**: We use version 1.13.0 or 1.10.2 (compatible with Ruby 2.6)
- **No Sudo Required**: All installations use `--user-install` flag
- **Connection Issues**: If downloads fail, try again when connection is better, or download gem files manually

## 🆘 Still Having Issues?

1. Check your internet connection
2. Try installing at a different time (network might be busy)
3. Use a VPN if your network blocks certain sites
4. Download gem files manually from rubygems.org
