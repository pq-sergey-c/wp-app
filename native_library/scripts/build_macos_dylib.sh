#!/bin/bash
set -euo pipefail

# Builds the macOS dynamic library for the native player and copies it into the
# Runner target's Frameworks folder so it can be loaded at runtime.

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly BUILD_CONFIGURATION="${CONFIGURATION:-Debug}"
readonly ARCHS_TO_BUILD="${ARCHS:-arm64;x86_64}"
readonly DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-10.15}"
readonly BUILD_ROOT="${REPO_ROOT}/build/native_macos/${BUILD_CONFIGURATION}"
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

readonly SDK_NAME="macosx"
readonly SDK_PATH="$(xcrun --sdk "${SDK_NAME}" --show-sdk-path)"
readonly CC_PATH="$(xcrun --sdk "${SDK_NAME}" --find clang)"
readonly CXX_PATH="$(xcrun --sdk "${SDK_NAME}" --find clang++)"

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
  -DCMAKE_SYSTEM_NAME=Darwin \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_TRY_COMPILE_CONFIGURATION="${BUILD_CONFIGURATION}" \
  -DCMAKE_TRY_COMPILE_PLATFORM_VARIABLES="CMAKE_OSX_ARCHITECTURES;CMAKE_OSX_SYSROOT;CMAKE_OSX_DEPLOYMENT_TARGET;CMAKE_SYSTEM_NAME" \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_OSX_SYSROOT="${SDK_PATH}" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}" \
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
  -DCMAKE_C_COMPILER="${CC_PATH}" \
  -DCMAKE_CXX_COMPILER="${CXX_PATH}" \
  -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="${BUILD_ROOT}/${BUILD_CONFIGURATION}" \
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

readonly BUILD_OUTPUT_SUBDIR="${BUILD_CONFIGURATION}"
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

mkdir -p "${FRAMEWORK_DIR}/Versions/A/Resources"

mv "${DESTINATION_PATH}" "${FRAMEWORK_DIR}/Versions/A/${FRAMEWORK_NAME}"

ln -sf A "${FRAMEWORK_DIR}/Versions/Current"
ln -sf Versions/Current/${FRAMEWORK_NAME} "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
ln -sf Versions/Current/Resources "${FRAMEWORK_DIR}/Resources"

cat > "${FRAMEWORK_DIR}/Versions/A/Resources/Info.plist" << EOF
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
    <key>LSMinimumSystemVersion</key>
    <string>${DEPLOYMENT_TARGET}</string>
</dict>
</plist>
EOF

echo "info: Created framework at ${FRAMEWORK_DIR}" >&2

if [[ "${CODE_SIGNING_ALLOWED:-YES}" != "NO" && -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]]; then
  /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements "${FRAMEWORK_DIR}/Versions/A/${FRAMEWORK_NAME}"
  echo "info: Codesigned ${FRAMEWORK_DIR}" >&2
fi