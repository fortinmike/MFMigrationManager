#!/bin/sh
set -e

cd "$1"

pod install

xctool -workspace "$1.xcworkspace" -scheme "$1.iOS" -sdk iphonesimulator test
xctool -workspace "$1.xcworkspace" -scheme "$1.Mac" test