#!/bin/zsh

# Use Homebrew-installed LLVM/Clang
# export PATH="/opt/homebrew/Cellar/llvm/19.1.2/bin:$PATH"
# export CC=/opt/homebrew/Cellar/llvm/19.1.2/bin/clang
# export CXX=/opt/homebrew/Cellar/llvm/19.1.2/bin/clang++


# export ASAN_OPTIONS=detect_leaks=1
# cmake -Bbuild/test -DTARGET_GROUP=test -DCMAKE_C_FLAGS="-fsanitize=address -g" -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address"  -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX .
cmake -Bbuild/test -DTARGET_GROUP=test .
if [ $? -ne 0 ]; then
    echo "cmake failed"
    exit 1
fi
cmake --build build/test
if [ $? -ne 0 ]; then
    echo "cmake build failed"
    exit 1
fi
# cd build/test && ASAN_OPTIONS=detect_leaks=1 ctest --verbose -R wp_playerlib
cd build/test && ctest --verbose -R wp_playerlib
