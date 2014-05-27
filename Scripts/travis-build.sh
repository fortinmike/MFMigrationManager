#!/bin/sh
set -e

cd MFMigrationManager

pod install

xctool -workspace MFMigrationManager.xcworkspace -scheme MFMigrationManager.iOS test
xctool -workspace MFMigrationManager.xcworkspace -scheme MFMigrationManager.Mac test