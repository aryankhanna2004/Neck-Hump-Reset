#!/bin/sh
set -e

# Install CocoaPods using Homebrew
brew install cocoapods

# Navigate to the project directory and install pods
cd "$CI_PRIMARY_REPOSITORY_PATH"
pod install
