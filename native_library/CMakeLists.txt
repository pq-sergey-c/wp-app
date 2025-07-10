cmake_minimum_required(VERSION 3.22.1)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(WpPlayerLibShared LANGUAGES C CXX)

# setup
set(CMAKE_CXX_STANDARD 17) # for android
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

# fix, TODO: maybe remove
if(NOT IS_ABSOLUTE "${CMAKE_INSTALL_PREFIX}")
    message(STATUS "CMAKE_INSTALL_PREFIX is not absolute. Converting to absolute path.")
    get_filename_component(ABS_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}" REALPATH BASE_DIR "${CMAKE_BINARY_DIR}")
    set(CMAKE_INSTALL_PREFIX "${ABS_INSTALL_PREFIX}" CACHE PATH "Install path prefix" FORCE)
endif()

# target
add_library(${PROJECT_NAME} SHARED
    wp_host_main.cpp
    wrapper_parts/wp_wrapper_native_port.cpp
    lib/dart_api_dl.c
)

# dart lib
set(FLUTTER_LIB "lib/")
target_include_directories(${PROJECT_NAME} PRIVATE ${FLUTTER_LIB})

# real library
add_subdirectory(wp_player_lib)
target_link_libraries(${PROJECT_NAME} PUBLIC WpPlayerLib)
target_include_directories(${PROJECT_NAME} PRIVATE wp_player_lib)

# options
# set_target_properties(${PROJECT_NAME} PROPERTIES COMPILE_FLAGS "-Wall -Wextra -Wpedantic -Werror") - due to Dart