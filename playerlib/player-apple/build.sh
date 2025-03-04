#!/bin/zsh

set -e

# Check for debug argument
BUILD_TYPE="Release"
if [[ $1 == "debug" ]]; then
    BUILD_TYPE="Debug"
fi

# Build for each platform

cmake -B build/os64 -G Xcode -DTARGET_GROUP=production -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DPLATFORM=OS64 -DDEPLOYMENT_TARGET=13.1
cmake --build build/os64 --config $BUILD_TYPE

cmake -B build/simulator64 -G Xcode -DTARGET_GROUP=production -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DPLATFORM=SIMULATOR64COMBINED -DDEPLOYMENT_TARGET=13.1
cmake --build build/simulator64 --config $BUILD_TYPE

cmake -B build/mac_catalyst -G Xcode -DTARGET_GROUP=production -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DPLATFORM=MAC_CATALYST_UNIVERSAL -DDEPLOYMENT_TARGET=13.1 -DMACOSX_DEPLOYMENT_TARGET=13.1 
# Bypassing the ios toolchain for mac catalyst due to https://github.com/leetal/ios-cmake/issues/172
cd build/mac_catalyst
xcodebuild -configuration $BUILD_TYPE -parallelizeTargets -jobs 2 -sdk macosx SUPPORTS_MAC_CATALYST=YES -project WpPlayerLibApple.xcodeproj -scheme WpPlayerLibApple  -destination 'platform=macOS,variant=Mac Catalyst' IPHONEOS_DEPLOYMENT_TARGET=13.1 MACOSX_DEPLOYMENT_TARGET=13.1
cd ../..

# Combine the platform builds into an XCFramework

rm -rf build/xcf
mkdir build/xcf

xcodebuild -create-xcframework \
    -framework build/os64/$BUILD_TYPE-iphoneos/WpPlayerLibApple.framework \
    -framework build/simulator64/$BUILD_TYPE-iphonesimulator/WpPlayerLibApple.framework \
    -framework build/mac_catalyst/$BUILD_TYPE/WpPlayerLibApple.framework \
    -output build/xcf/WpPlayerLibApple.xcframework
