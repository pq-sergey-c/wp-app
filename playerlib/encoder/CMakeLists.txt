cmake_minimum_required(VERSION 3.22.2)

project(wp_encoderlib)

include(FetchContent)

set(TARGET_GROUP production CACHE STRING "Group to build")

# Opus flags
set(OP_DISABLE_DOCS ON CACHE BOOL "Disable building documentation" FORCE)
set(OP_DISABLE_EXAMPLES ON CACHE BOOL "Disable building examples" FORCE)
set(OP_DISABLE_HTTP ON CACHE BOOL "Disable building HTTP support" FORCE)

FetchContent_Declare(
  opus
  GIT_REPOSITORY https://github.com/xiph/opus.git
  GIT_TAG        v1.5.2
)
FetchContent_MakeAvailable(opus)
include_directories(${opus_SOURCE_DIR}/include)

# Add libopusenc
add_subdirectory(vendor/libopusenc)

add_library(WpEncoderLib STATIC
  wp_encoderlib.c)

target_include_directories(WpEncoderLib
  PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(WpEncoderLib opus libopusenc)

set_property(TARGET WpEncoderLib PROPERTY C_STANDARD 17)

if(TARGET_GROUP STREQUAL test)
  FetchContent_Declare(
    ogg
    GIT_REPOSITORY https://github.com/xiph/ogg.git
    GIT_TAG        v1.3.5
  )
  FetchContent_MakeAvailable(ogg)
  include_directories(${ogg_SOURCE_DIR}/include)

  FetchContent_Declare(
    opusfile
    GIT_REPOSITORY https://github.com/xiph/opusfile.git
    GIT_TAG        9d718345ce03b2fad5d7d28e0bcd1cc69ab2b166
  )
  FetchContent_MakeAvailable(opusfile)
  include_directories(${opusfile_SOURCE_DIR}/include)
  
  include(CTest)
  add_subdirectory(vendor/unity)
  add_subdirectory(test)
  target_link_libraries(WpEncoderLib ogg opusfile)
endif()

set_target_properties(WpEncoderLib PROPERTIES COMPILE_FLAGS "-Wall -Wextra -Wpedantic -Werror")

# Add the executable target
add_executable(wp_encoder wp_encoder.c)
target_link_libraries(wp_encoder WpEncoderLib)
set_property(TARGET wp_encoder PROPERTY C_STANDARD 17)
set_target_properties(wp_encoder PROPERTIES COMPILE_FLAGS "-Wall -Wextra -Wpedantic -Werror")

install(TARGETS WpEncoderLib wp_encoder
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin)
