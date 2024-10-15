#!/bin/bash

# Exit on error
set -e

# Define the library name
LIB_NAME="yrs"

# Define the output directory
OUTPUT_DIR="target/universal"

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

# Step 3: Build the library for iOS (Device only)
echo "Building for iOS (Device only)..."
cargo build --release --target aarch64-apple-ios

# Step 4: Build the library for iOS Simulator (ARM64 and x86_64)
echo "Building for iOS Simulator (ARM64 and x86_64)..."
cargo build --release --target aarch64-apple-ios-sim
cargo build --release --target x86_64-apple-ios

# Step 5: Create Universal Binary for macOS
echo "Creating universal static library for macOS..."
lipo -create -output $OUTPUT_DIR/lib$LIB_NAME-macos.a \
    target/aarch64-apple-darwin/release/lib$LIB_NAME.a \
    target/x86_64-apple-darwin/release/lib$LIB_NAME.a

# Step 6: Create Universal Binary for iOS Simulator
echo "Creating universal static library for iOS Simulator..."
lipo -create -output $OUTPUT_DIR/lib$LIB_NAME-ios-simulator.a \
    target/aarch64-apple-ios-sim/release/lib$LIB_NAME.a \
    target/x86_64-apple-ios/release/lib$LIB_NAME.a

# Step 7: Copy the iOS device binary to the output directory
echo "Copying iOS device binary to output directory..."
cp target/aarch64-apple-ios/release/lib$LIB_NAME.a $OUTPUT_DIR/lib$LIB_NAME-ios.a

echo "Build completed successfully!"
