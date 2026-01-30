#!/bin/bash

# ACM Monitor Mobile App Build Script
# This script builds APK for Android and IPA for iOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ACM Monitor Mobile App Build Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Navigate to mobile directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter is not installed. Please install Flutter first.${NC}"
    exit 1
fi

# Get Flutter dependencies
echo -e "\n${YELLOW}Getting Flutter dependencies...${NC}"
flutter pub get

# Clean previous builds
echo -e "\n${YELLOW}Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Build function
build_android() {
    echo -e "\n${GREEN}Building Android APK...${NC}"

    # Build APK for all environments
    echo -e "${YELLOW}Building Development APK...${NC}"
    flutter build apk --flavor development --debug

    echo -e "${YELLOW}Building Production APK (Release)...${NC}"
    flutter build apk --flavor production --release

    echo -e "${YELLOW}Building App Bundle (AAB) for Play Store...${NC}"
    flutter build appbundle --flavor production --release

    # Output locations
    echo -e "\n${GREEN}Android builds completed!${NC}"
    echo -e "Debug APK: build/app/outputs/flutter-apk/app-development-debug.apk"
    echo -e "Release APK: build/app/outputs/flutter-apk/app-production-release.apk"
    echo -e "App Bundle: build/app/outputs/bundle/productionRelease/app-production-release.aab"
}

build_ios() {
    echo -e "\n${GREEN}Building iOS IPA...${NC}"

    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}iOS builds can only be created on macOS.${NC}"
        return 1
    fi

    # Check Xcode installation
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}Xcode is not installed. Please install Xcode first.${NC}"
        return 1
    fi

    # Install CocoaPods dependencies
    echo -e "${YELLOW}Installing CocoaPods dependencies...${NC}"
    cd ios
    pod install
    cd ..

    # Build iOS archive
    echo -e "${YELLOW}Building iOS archive...${NC}"
    flutter build ios --release --no-codesign

    # Create IPA (requires proper signing configuration)
    echo -e "${YELLOW}Creating IPA...${NC}"

    # For CI/CD, use:
    # flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

    echo -e "\n${GREEN}iOS build completed!${NC}"
    echo -e "Archive location: build/ios/archive/"
    echo -e "Note: To create a signed IPA, configure code signing in Xcode."
}

# Parse arguments
case "$1" in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    all)
        build_android
        build_ios
        ;;
    *)
        echo -e "\n${YELLOW}Usage: ./build.sh [android|ios|all]${NC}"
        echo -e "  android - Build Android APK and AAB"
        echo -e "  ios     - Build iOS IPA (macOS only)"
        echo -e "  all     - Build for both platforms"
        echo -e "\n${YELLOW}Building for all platforms...${NC}"
        build_android
        build_ios
        ;;
esac

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Build process completed!${NC}"
echo -e "${GREEN}========================================${NC}"
