#!/bin/sh

cmake -Bbuild/test -DTARGET_GROUP=test -DCMAKE_C_FLAGS="-DUNITY_INCLUDE_DOUBLE" .
if [ $? -ne 0 ]; then
    echo "cmake failed"
    exit 1
fi
cmake --build build/test
if [ $? -ne 0 ]; then
    echo "cmake build failed"
    exit 1
fi
cd build/test && ctest --verbose -R wp_encoderlib

