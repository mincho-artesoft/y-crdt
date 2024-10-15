#!/bin/bash

# Exit on error
set -e

# Define the library name
LIB_NAME="yrs"

# Define output directories
OUTPUT_DIR="target/universal"
XCFRAMEWORK_OUTPUT="./Yrs.xcframework"

# Ensure the output directory exists
mkdir -p $OUTPUT_DIR

# Step 1: Ensure the necessary Rust targets are installed
echo "Installing necessary Rust targets..."

rustup target add aarch64-apple-darwin
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios
rustup target add aarch64-apple-ios-sim

# Step 2: Build the library for macOS (x86_64 and ARM64)
echo "Building for macOS (x86_64 and ARM64)..."

cargo build --release --target aarch64-apple-darwin
cargo build --release --target x86_64-apple-darwin

# Step 3: Build the library for iOS (Device)
echo "Building for iOS (Device)..."
cargo build --release --target aarch64-apple-ios

# Step 4: Build the library for iOS Simulator (ARM64 and x86_64)
echo "Building for iOS Simulator (ARM64 and x86_64)..."
cargo build --release --target aarch64-apple-ios-sim
cargo build --release --target x86_64-apple-ios

# Step 5: Create Universal Binaries

## macOS Universal Binary
echo "Creating universal static library for macOS..."
lipo -create -output $OUTPUT_DIR/lib$LIB_NAME-macos.a \
    target/aarch64-apple-darwin/release/lib$LIB_NAME.a \
    target/x86_64-apple-darwin/release/lib$LIB_NAME.a

## iOS Simulator Universal Binary
echo "Creating universal static library for iOS Simulator..."
lipo -create -output $OUTPUT_DIR/lib$LIB_NAME-ios-simulator.a \
    target/aarch64-apple-ios-sim/release/lib$LIB_NAME.a \
    target/x86_64-apple-ios/release/lib$LIB_NAME.a

# Step 6: Copy the iOS device binary to the output directory
echo "Copying iOS device binary to output directory..."
cp target/aarch64-apple-ios/release/lib$LIB_NAME.a $OUTPUT_DIR/lib$LIB_NAME-ios.a

# Step 7: Define paths for xcframework creation

MAC_LIB_PATH="$OUTPUT_DIR/lib$LIB_NAME-macos.a"
MAC_HEADERS_PATH="tests-ffi/include"

IOS_DEVICE_LIB_PATH="$OUTPUT_DIR/lib$LIB_NAME-ios.a"
IOS_SIMULATOR_LIB_PATH="$OUTPUT_DIR/lib$LIB_NAME-ios-simulator.a"
IOS_HEADERS_PATH="tests-ffi/include"

# Step 8: Check if headers exist
echo "Checking if header files exist..."

if [ ! -d "$MAC_HEADERS_PATH" ]; then
    echo "Error: macOS headers not found at $MAC_HEADERS_PATH"
    exit 1
fi

if [ ! -d "$IOS_HEADERS_PATH" ]; then
    echo "Error: iOS headers not found at $IOS_HEADERS_PATH"
    exit 1
fi

# Step 9: Remove existing xcframework if it exists
if [ -d "$XCFRAMEWORK_OUTPUT" ]; then
    rm -rf "$XCFRAMEWORK_OUTPUT"
fi

# Step 10: Create the xcframework
echo "Creating xcframework..."

xcodebuild -create-xcframework \
    -library "$MAC_LIB_PATH" \
    -headers "$MAC_HEADERS_PATH" \
    -library "$IOS_DEVICE_LIB_PATH" \
    -headers "$IOS_HEADERS_PATH" \
    -library "$IOS_SIMULATOR_LIB_PATH" \
    -headers "$IOS_HEADERS_PATH" \
    -output "$XCFRAMEWORK_OUTPUT"

if [ $? -eq 0 ]; then
    echo "Created xcframework at $XCFRAMEWORK_OUTPUT"
else
    echo "Failed to create xcframework"
    exit 1
fi

echo "Build and xcframework creation completed successfully!"
