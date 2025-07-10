cmake_minimum_required(VERSION 3.22.1)

project(WpPlayerLib LANGUAGES C)

# ======================[  ]----------------------
#                    Make target
# ----------------------[  ]======================

add_library(${PROJECT_NAME} STATIC wp_playerlib.c)

# ======================[  ]----------------------
#                      Setup
# ----------------------[  ]======================

# portability
if(ANDROID)
    # Note: seems that dependencies use fopen64, fseeko, ftello - but Android has not of them
    #       so by this it is attempt to change functions for reading without changing code
    add_definitions(-Dfopen64=fopen -Dfseeko=fseek -Dftello=ftell)

    # Note: not sure about need of next one
    add_definitions(-D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE)

    # target_compile_options(${PROJECT_NAME} PRIVATE "-include ${CMAKE_SOURCEs_DIR}/android_print.h")
endif()

# imports
include(FetchContent)

# options
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_FLAGS_RELEASE "-O2 -DNDEBUG") # TODO: try O3

# kind of CMAKE_BUILD_TYPE"
set(TARGET_GROUP production CACHE STRING "Group to build")

# Opus flags
set(OP_DISABLE_DOCS ON CACHE BOOL "Disable building documentation" FORCE)
set(OP_DISABLE_EXAMPLES ON CACHE BOOL "Disable building examples" FORCE)
set(OP_DISABLE_HTTP ON CACHE BOOL "Disable building HTTP support" FORCE)


# ======================[  ]----------------------
#                 Fetch libraries
# ----------------------[  ]======================

# Opus
FetchContent_Declare(
    opus
    GIT_REPOSITORY https://github.com/xiph/opus.git
    GIT_TAG        v1.5.2
)
FetchContent_MakeAvailable(opus)

# Ogg
FetchContent_Declare(
    ogg
    GIT_REPOSITORY https://github.com/xiph/ogg.git
    GIT_TAG        v1.3.5
)
FetchContent_MakeAvailable(ogg)

# Opusfile
FetchContent_Declare(
    opusfile
    GIT_REPOSITORY https://github.com/xiph/opusfile.git
    GIT_TAG        9d718345ce03b2fad5d7d28e0bcd1cc69ab2b166
)
FetchContent_MakeAvailable(opusfile)


# ======================[  ]----------------------
#               Include public APIs
# ----------------------[  ]======================

include_directories(${opus_SOURCE_DIR}/include)
include_directories(${ogg_SOURCE_DIR}/include)
include_directories(${opusfile_SOURCE_DIR}/include)


# ======================[  ]----------------------
#                Linkage to libraries
# ----------------------[  ]======================

target_include_directories(${PROJECT_NAME}
    PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)
target_include_directories(${PROJECT_NAME}
    SYSTEM
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/vendor/miniaudio
)

target_link_libraries(${PROJECT_NAME} opus opusfile ogg)

if(APPLE)
    target_link_libraries(${PROJECT_NAME}
        "-framework AVFoundation"
        "-framework AudioToolbox"
    )
elseif(ANDROID) # may be unneeded
    target_link_libraries(${PROJECT_NAME}
        log
        android
        OpenSLES # comment to unlink old audio backend
    )
elseif(WIN32)
    target_link_libraries(${PROJECT_NAME}
        dsound
        dxguid
        winmm
    )
endif()

# ======================[  ]----------------------
#                     Options
# ----------------------[  ]======================

set_target_properties(${PROJECT_NAME} PROPERTIES COMPILE_FLAGS "-Wall -Wextra -Wpedantic -Werror")

# ======================[  ]----------------------
#                     Packaging
# ----------------------[  ]======================

# install(TARGETS ${PROJECT_NAME}
#     ARCHIVE DESTINATION lib
#     LIBRARY DESTINATION lib
#     RUNTIME DESTINATION bin
# )


# ======================[  ]----------------------
#                     Test setup
# ----------------------[  ]======================

# Note: Hasn't succeeded with setting up testing for android
# Problem: DMA_NO_DEVICE_IO flag blocks building of lib
#          I tried changing it to DMA_NO_DEVICE_IO_FAKE in code (it uses #ifdef and #ifndef).
#          but encounter problem which may be (not sure) that somewhy jobs aren't been added
#          so until fix leave it with if (FALSE)
if (FALSE) # if (TARGET_GROUP STREQUAL "testing")
    add_subdirectory("test")
endif()