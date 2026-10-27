#!/bin/bash
# Makes the custom symbols opticloud.pulse and opticloud.off in Shared/Symbols.xcassets from the dark app icon.
set -euo pipefail
cd "$(dirname "$0")/../.."
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
xcrun swiftc -O -o "$work/trace" Tools/symbols/trace.swift
"$work/trace" OptiCloudSensor/Assets.xcassets/AppIcon.appiconset/AppIcon-dark.png "$work/loops.json" > /dev/null
python3 -I Tools/symbols/make-symbols.py "$work/loops.json" Shared/Symbols.xcassets
