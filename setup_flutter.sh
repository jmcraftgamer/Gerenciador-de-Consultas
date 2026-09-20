#!/bin/bash
set -e

echo "Installing Flutter SDK..."

# Download and extract Flutter
cd /tmp
curl -fsSL -o flutter.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.8-stable.tar.xz"
tar xf flutter.tar.xz
rm flutter.tar.xz
export PATH="/tmp/flutter/bin:$PATH"

echo "Flutter installed: $(flutter --version | head -1)"

# Configure Flutter
flutter config --no-analytics
flutter doctor -v

# Get dependencies
cd "$OLDPWD"
flutter pub get

echo "Flutter setup complete!"
