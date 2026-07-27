# Concord macOS Build & Xcode Environment Guide

This document provides exact step-by-step instructions for building the **Concord iOS Client** on macOS using Xcode.

## Prerequisites on macOS
1. **macOS Sonoma (14.0+)** or **macOS Sequoia (15.0+)**
2. **Xcode 15.4+** or **Xcode 16.0+**
3. **CocoaPods** and **Swift Package Manager**
4. **Git LFS** (`brew install git-lfs`)
5. **Homebrew** tools: `brew install cargo rust protobuf cmake`

---

## Step-by-Step Xcode Build Instructions

### Step 1: Clone Concord Repository
```bash
git clone https://github.com/concord-org/Concord.git
cd Concord
```

### Step 2: Bootstrap Dependencies
```bash
# Run local client dependency setup
cd clients/ios
swift package resolve
```

### Step 3: Configure Build Configuration
```bash
# Verify custom bundle identifier settings
cat ../../configuration/BundleIdentifiers.xcconfig
```

### Step 4: Execute Command Line Xcode Build
```bash
xcodebuild -workspace Concord.xcworkspace \
  -scheme Concord \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build
```

---

## CI / GitHub Actions Configuration Example (`.github/workflows/ios-build.yml`)

```yaml
name: Concord iOS macOS Build

on:
  push:
    branches: [ "concord/signal-foundation", "main" ]
  pull_request:
    branches: [ "concord/signal-foundation" ]

jobs:
  build-ios:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Select Xcode Version
        run: sudo xcode-select -s /Applications/Xcode_15.4.app/Contents/Developer

      - name: Install Dependencies
        run: |
          brew install cargo rust protobuf cmake git-lfs

      - name: Build Concord Simulator Target
        run: |
          xcodebuild -workspace clients/ios/Concord.xcworkspace \
            -scheme Concord \
            -sdk iphonesimulator \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            build
```
