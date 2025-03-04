#!/bin/sh

cmake -Bbuild .
if [ $? -ne 0 ]; then
    echo "cmake failed"
    exit 1
fi

cmake --build build
if [ $? -ne 0 ]; then
    echo "cmake build failed" 
    exit 1
fi
