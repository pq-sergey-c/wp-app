#!/bin/bash
set -euo pipefail

# Builds the iOS dynamic library for the native player and copies it into the
# Runner target's Frameworks folder so it can be loaded at runtime.

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly BUILD_CONFIGURATION="${CONFIGURATION:-Debug}"
readonly EFFECTIVE_PLATFORM="${EFFECTIVE_PLATFORM_NAME:-}"
readonly ARCHS_TO_BUILD="${ARCHS:-arm64}"
readonly DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-13.0}"
readonly BUILD_ROOT="${REPO_ROOT}/build/native_ios/${BUILD_CONFIGURATION}${EFFECTIVE_PLATFORM}"
readonly CMAKE_GENERATOR="Ninja Multi-Config"
readonly LIB_NAME="libWpPlayerLibShared.dylib"
readonly NATIVE_SOURCE_DIR="${REPO_ROOT}/native_library"
readonly DESTINATION_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
readonly DESTINATION_PATH="${DESTINATION_DIR}/${LIB_NAME}"
readonly FRAMEWORK_NAME="WpPlayerLib"
readonly FRAMEWORK_DIR="${DESTINATION_DIR}/${FRAMEWORK_NAME}.framework"

find_cmake() {
  if command -v cmake >/dev/null 2>&1; then
    command -v cmake
    return
  fi

  local candidate
  for candidate in \
    /opt/homebrew/bin/cmake \
    /usr/local/bin/cmake \
    /opt/local/bin/cmake \
    /Applications/CMake.app/Contents/bin/cmake \
    /usr/bin/cmake; do
    if [[ -x "${candidate}" ]]; then
      echo "${candidate}"
      return
    fi
  done

  echo "error: Unable to locate cmake. Ensure CMake is installed and available on PATH." >&2
  exit 1
}

find_ninja() {
  if command -v ninja >/dev/null 2>&1; then
    command -v ninja
    return
  fi

  local candidate
  for candidate in \
    /opt/homebrew/bin/ninja \
    /usr/local/bin/ninja \
    /opt/local/bin/ninja \
    /usr/bin/ninja; do
    if [[ -x "${candidate}" ]]; then
      echo "${candidate}"
      return
    fi
  done

  echo "error: Unable to locate ninja. Ensure Ninja is installed and available on PATH." >&2
  exit 1
}


readonly CMAKE_BIN="$(find_cmake)"
readonly CMAKE_BIN_DIR="$(dirname "${CMAKE_BIN}")"
readonly NINJA_BIN="$(find_ninja)"
readonly NINJA_BIN_DIR="$(dirname "${NINJA_BIN}")"
export PATH="${CMAKE_BIN_DIR}:${NINJA_BIN_DIR}:${PATH}"

if [[ "${EFFECTIVE_PLATFORM}" == "-iphonesimulator" ]]; then
  readonly SDK_NAME="iphonesimulator"
else
  readonly SDK_NAME="iphoneos"
fi

readonly SDK_PATH="$(xcrun --sdk "${SDK_NAME}" --show-sdk-path)"
readonly CC_PATH="$(xcrun --sdk "${SDK_NAME}" --find clang)"
readonly CXX_PATH="$(xcrun --sdk "${SDK_NAME}" --find clang++)"
readonly PRIMARY_ARCH="${ARCHS_TO_BUILD%% *}"

# Ensure CMake drives try_compile with the same target triple as the main build.
case "${PRIMARY_ARCH}" in
  arm64)
    if [[ "${SDK_NAME}" == "iphonesimulator" ]]; then
      readonly COMPILER_TARGET="arm64-apple-ios${DEPLOYMENT_TARGET}-simulator"
    else
      readonly COMPILER_TARGET="arm64-apple-ios${DEPLOYMENT_TARGET}"
    fi
    ;;
  x86_64)
    readonly COMPILER_TARGET="x86_64-apple-ios${DEPLOYMENT_TARGET}-simulator"
    ;;
  *)
    readonly COMPILER_TARGET=""
    ;;
esac

if [[ -f "${BUILD_ROOT}/CMakeCache.txt" ]]; then
  if ! grep -q "CMAKE_GENERATOR:INTERNAL=${CMAKE_GENERATOR}" "${BUILD_ROOT}/CMakeCache.txt"; then
    echo "info: Clearing previous CMake cache due to generator change" >&2
    rm -rf "${BUILD_ROOT}"
  fi
fi

mkdir -p "${BUILD_ROOT}"

if [[ -d "${BUILD_ROOT}/_deps" ]]; then
  if find "${BUILD_ROOT}/_deps" -name CMakeCache.txt -exec grep -L "CMAKE_GENERATOR:INTERNAL=${CMAKE_GENERATOR}" {} \; | grep -q .; then
    echo "info: Clearing FetchContent subbuilds due to generator change" >&2
    rm -rf "${BUILD_ROOT}/_deps"
  fi
fi

"${CMAKE_BIN}" \
  -S "${NATIVE_SOURCE_DIR}" \
  -B "${BUILD_ROOT}" \
  -G "${CMAKE_GENERATOR}" \
  -DCMAKE_SYSTEM_NAME=iOS \
  ${COMPILER_TARGET:+-DCMAKE_SYSTEM_PROCESSOR="${PRIMARY_ARCH}"} \
  ${COMPILER_TARGET:+-DCMAKE_C_COMPILER_TARGET="${COMPILER_TARGET}"} \
  ${COMPILER_TARGET:+-DCMAKE_CXX_COMPILER_TARGET="${COMPILER_TARGET}"} \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_TRY_COMPILE_CONFIGURATION="${BUILD_CONFIGURATION}" \
  -DCMAKE_TRY_COMPILE_PLATFORM_VARIABLES="CMAKE_OSX_ARCHITECTURES;CMAKE_OSX_SYSROOT;CMAKE_OSX_DEPLOYMENT_TARGET;CMAKE_SYSTEM_NAME;CMAKE_SYSTEM_PROCESSOR;CMAKE_C_COMPILER_TARGET;CMAKE_CXX_COMPILER_TARGET" \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_OSX_SYSROOT="${SDK_PATH}" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}" \
  -DCMAKE_OSX_ARCHITECTURES="${ARCHS_TO_BUILD}" \
  -DCMAKE_C_COMPILER="${CC_PATH}" \
  -DCMAKE_CXX_COMPILER="${CXX_PATH}" \
  -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="${BUILD_ROOT}/${BUILD_CONFIGURATION}${EFFECTIVE_PLATFORM}" \
  -DINT16_SIZE=2 \
  -DUINT16_SIZE=2 \
  -DU_INT16_SIZE=2 \
  -DINT32_SIZE=4 \
  -DUINT32_SIZE=4 \
  -DU_INT32_SIZE=4 \
  -DINT64_SIZE=8 \
  -DSHORT_SIZE=2 \
  -DINT_SIZE=4 \
  -DLONG_SIZE=8 \
  -DLONG_LONG_SIZE=8

"${CMAKE_BIN}" --build "${BUILD_ROOT}" --config "${BUILD_CONFIGURATION}" --target WpPlayerLibShared

readonly BUILD_OUTPUT_SUBDIR="${BUILD_CONFIGURATION}${EFFECTIVE_PLATFORM}"
readonly BUILD_OUTPUT_PATH="${BUILD_ROOT}/${BUILD_OUTPUT_SUBDIR}/${LIB_NAME}"

LIB_SOURCE_PATH="${BUILD_OUTPUT_PATH}"

if [[ ! -f "${LIB_SOURCE_PATH}" ]]; then
  readonly ALT_BUILD_OUTPUT_PATH="${BUILD_ROOT}/${BUILD_OUTPUT_SUBDIR}/${BUILD_CONFIGURATION}/${LIB_NAME}"
  if [[ -f "${ALT_BUILD_OUTPUT_PATH}" ]]; then
    LIB_SOURCE_PATH="${ALT_BUILD_OUTPUT_PATH}"
  else
    echo "error: Failed to locate ${LIB_NAME}. Checked ${LIB_SOURCE_PATH} and ${ALT_BUILD_OUTPUT_PATH}" >&2
    exit 1
  fi
fi

mkdir -p "${DESTINATION_DIR}"
cp "${LIB_SOURCE_PATH}" "${DESTINATION_PATH}"

echo "info: Copied ${LIB_NAME} to ${DESTINATION_PATH}" >&2

mkdir -p "${FRAMEWORK_DIR}"
mkdir -p "${FRAMEWORK_DIR}/Modules"

mv "${DESTINATION_PATH}" "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"

cat > "${FRAMEWORK_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.wavepaths.${FRAMEWORK_NAME}</string>
    <key>CFBundleName</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>${DEPLOYMENT_TARGET}</string>
</dict>
</plist>
EOF

cat > "${FRAMEWORK_DIR}/Modules/module.modulemap" << EOF
framework module ${FRAMEWORK_NAME} {
    header "${FRAMEWORK_NAME}.h"
    export *
}
EOF

echo "info: Created framework at ${FRAMEWORK_DIR}" >&2

if [[ "${CODE_SIGNING_ALLOWED:-YES}" != "NO" && -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]]; then
  /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
  echo "info: Codesigned ${FRAMEWORK_DIR}" >&2
fi
