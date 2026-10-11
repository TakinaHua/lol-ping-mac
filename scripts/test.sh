#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/module-cache
xcrun swiftc -module-cache-path "$PWD/build/module-cache" Sources/Model.swift Sources/Sound.swift Tests/main.swift -framework AVFoundation -o build/PingWheelTests
./build/PingWheelTests
