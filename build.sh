#!/bin/bash

# MLX Mac App Build Script
# Usage: ./build.sh [debug|release|clean|run]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
PROJECT_NAME="MLXMacApp"
SCHEME="MLXMacApp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[MLX Mac App] ${message}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for Xcode command line tools
if ! command_exists xcodebuild; then
    print_status "$RED" "Xcode command line tools not found. Please install Xcode."
    exit 1
fi

# Check for Xcode
if ! command_exists xcode-select; then
    print_status "$RED" "Xcode not found. Please install Xcode from the Mac App Store."
    exit 1
fi

# Parse arguments
ACTION="${1:-debug}"

case "$ACTION" in
    debug)
        print_status "$BLUE" "Building in Debug configuration..."
        xcodebuild -project "$PROJECT_NAME.xcodeproj" \
            -scheme "$SCHEME" \
            -configuration Debug \
            -derivedDataPath "$PROJECT_DIR/build/Debug" \
            clean build
        print_status "$GREEN" "Debug build completed successfully!"
        ;;
    release)
        print_status "$BLUE" "Building in Release configuration..."
        xcodebuild -project "$PROJECT_NAME.xcodeproj" \
            -scheme "$SCHEME" \
            -configuration Release \
            -derivedDataPath "$PROJECT_DIR/build/Release" \
            clean build
        print_status "$GREEN" "Release build completed successfully!"
        ;;
    clean)
        print_status "$BLUE" "Cleaning build artifacts..."
        xcodebuild -project "$PROJECT_NAME.xcodeproj" \
            -scheme "$SCHEME" \
            clean
        rm -rf "$PROJECT_DIR/build"
        print_status "$GREEN" "Clean completed!"
        ;;
    run)
        print_status "$BLUE" "Building and running in Debug configuration..."
        xcodebuild -project "$PROJECT_NAME.xcodeproj" \
            -scheme "$SCHEME" \
            -configuration Debug \
            -derivedDataPath "$PROJECT_DIR/build/Debug" \
            clean build
        
        # Find the built app
        APP_PATH="$PROJECT_DIR/build/Debug/$PROJECT_NAME.app"
        if [ -d "$APP_PATH" ]; then
            print_status "$GREEN" "Opening $PROJECT_NAME..."
            open "$APP_PATH"
        else
            print_status "$RED" "Could not find built app at $APP_PATH"
            exit 1
        fi
        ;;
    archive)
        print_status "$BLUE" "Creating archive..."
        xcodebuild -project "$PROJECT_NAME.xcodeproj" \
            -scheme "$SCHEME" \
            -configuration Release \
            -archivePath "$PROJECT_DIR/build/$PROJECT_NAME.xcarchive" \
            archive
        print_status "$GREEN" "Archive created at $PROJECT_DIR/build/$PROJECT_NAME.xcarchive"
        ;;
    export)
        print_status "$BLUE" "Exporting archive..."
        xcodebuild -exportArchive \
            -archivePath "$PROJECT_DIR/build/$PROJECT_NAME.xcarchive" \
            -exportPath "$PROJECT_DIR/build/Exported" \
            -exportOptionsPlist "$PROJECT_DIR/ExportOptions.plist"
        print_status "$GREEN" "Archive exported to $PROJECT_DIR/build/Exported"
        ;;
    *)
        print_status "$RED" "Unknown action: $ACTION"
        print_status "$YELLOW" "Usage: $0 [debug|release|clean|run|archive|export]"
        exit 1
        ;;
esac

exit 0
