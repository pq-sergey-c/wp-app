#!/bin/zsh

set -e

../../../emsdk/emsdk activate latest
source "../../../emsdk/emsdk_env.sh"

emcmake cmake -S. -Bbuild
cmake --build build

# Hack to fix the path issue in WpPlayerlibWasm.js
sed -i '' 's|"WpPlayerlibWasm.aw.js"|"/playerlib/WpPlayerlibWasm.aw.js"|g' build/WpPlayerlibWasm.js

mkdir -p ../../bonny/dist/playerlib
cp build/WpPlayerlibWasm* ../../bonny/dist/playerlib