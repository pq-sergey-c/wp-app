cmake_minimum_required(VERSION 3.22.2)

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

add_library(WpPlayerLib STATIC
  wp_playerlib.c)

target_include_directories(WpPlayerLib
  PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(WpPlayerLib
  SYSTEM
  PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/vendor/miniaudio)

target_link_libraries(WpPlayerLib opus opusfile ogg)
if(APPLE)
  target_link_libraries(WpPlayerLib
    "-framework AVFoundation"
    "-framework AudioToolbox"
  )
endif()

set_property(TARGET WpPlayerLib PROPERTY C_STANDARD 17)

if(TARGET_GROUP STREQUAL test)
  include(CTest)
  add_subdirectory(vendor/unity)
  add_subdirectory(test)
endif()

set_target_properties(WpPlayerLib PROPERTIES COMPILE_FLAGS "-Wall -Wextra -Wpedantic -Werror")

install(TARGETS WpPlayerLib
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin)
