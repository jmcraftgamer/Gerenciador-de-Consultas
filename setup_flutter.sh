#!/bin/bash
set -e

echo "Installing Flutter SDK..."

cd /tmp
wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.8-stable.tar.xz -O flutter.tar.xz
tar xf flutter.tar.xz
rm flutter.tar.xz
export PATH="/tmp/flutter/bin:$PATH"

echo "Flutter installed: $(flutter --version | head -1)"

flutter config --no-analytics

cd "$OLDPWD"
flutter pub get

echo "Flutter setup complete!"
