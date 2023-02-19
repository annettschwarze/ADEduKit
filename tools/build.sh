#!/bin/sh

#  build.sh
#  ADEduKit
#
#  Created by Schwarze on 28.12.21.
#  
mkdir build
rm -rf build/ADEduKit*

# extract version:
# plutil -extract CFBundleShortVersionString xml1 -o - ./ADEduKit/Info.plist | sed -n "s/.*<string>\(.*\)<\/string>.*/\1/p"

xcodebuild archive \
 -scheme ADEduKit \
 -archivePath ./build/ADEduKit-iphonesimulator.xcarchive \
 -sdk iphonesimulator \
 SKIP_INSTALL=NO

xcodebuild archive \
 -scheme ADEduKit \
 -archivePath ./build/ADEduKit-iphoneos.xcarchive \
 -sdk iphoneos \
 SKIP_INSTALL=NO

xcodebuild -create-xcframework \
 -framework ./build/ADEduKit-iphonesimulator.xcarchive/Products/Library/Frameworks/ADEduKit.framework \
 -framework ./build/ADEduKit-iphoneos.xcarchive/Products/Library/Frameworks/ADEduKit.framework \
 -output ./build/ADEduKit.xcframework
