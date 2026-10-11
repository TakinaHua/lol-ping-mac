#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/module-cache
APP="$PWD/build/Desktop Ping Wheel.app"
mkdir -p "$APP/Contents/MacOS"
xcrun swiftc -O -target "$(uname -m)-apple-macosx12.0" -module-cache-path "$PWD/build/module-cache" Sources/*.swift -o "$APP/Contents/MacOS/PingWheel" -framework AppKit -framework Carbon -framework AVFoundation
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
printf 'Built: %s\n' "$APP"
