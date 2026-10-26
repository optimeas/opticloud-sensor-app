#!/bin/sh
# Archives the app and uploads it to App Store Connect for TestFlight.
# Run from ios/ on a clean checkout of main:
#   Tools/upload-testflight.sh [output folder]
# The version is MARKETING_VERSION from the project. The build number is the number of commits on HEAD, so it rises
# with every merge into main and is the same for the same commit. Signing uses the team in Config/Local.xcconfig and
# the Apple account signed in to Xcode.
set -eu

out="${1:-build/testflight}"
build=$(git rev-list --count HEAD)

if [ -n "$(git status --porcelain)" ]; then
    echo "The working tree has changes. Commit or stash them first." >&2
    exit 1
fi

rm -rf "$out"
xcodebuild archive \
    -project OptiCloudSensor.xcodeproj \
    -scheme OptiCloudSensor \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$out/OptiCloudSensor.xcarchive" \
    -allowProvisioningUpdates \
    CURRENT_PROJECT_VERSION="$build"

xcodebuild -exportArchive \
    -archivePath "$out/OptiCloudSensor.xcarchive" \
    -exportOptionsPlist Config/ExportOptions.plist \
    -exportPath "$out/export" \
    -allowProvisioningUpdates

echo "Uploaded build $build."
