#!/bin/bash

# Quick script to check pod install progress

echo "🔍 Checking CocoaPods installation progress..."
echo ""

cd /Users/samuelsi92023icloud.com/Downloads/vlog-main/ios

# Check if Pods directory exists and its size
if [ -d "Pods" ]; then
    PODS_SIZE=$(du -sh Pods 2>/dev/null | cut -f1)
    PODS_COUNT=$(find Pods -type d -maxdepth 1 2>/dev/null | wc -l)
    echo "✅ Pods directory exists"
    echo "   Size: $PODS_SIZE"
    echo "   Pods installed: $((PODS_COUNT - 1))"
    echo ""
    echo "📦 Recent pod installations:"
    ls -lt Pods 2>/dev/null | head -10
else
    echo "⏳ Pods directory not created yet - installation in progress..."
fi

echo ""
echo "💡 Tip: This is normal! Pod install can take 5-15 minutes with slow connection."
echo "   Just let it run - it will complete eventually."
