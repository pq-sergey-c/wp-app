cmake_minimum_required(VERSION 3.22.2)

project(wp_playerlib_test)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DMA_NO_DEVICE_IO -DMA_NO_THREADING" PARENT_SCOPE)

set(TEST_DATA_DIR "${CMAKE_SOURCE_DIR}/test/testdata")
configure_file(
    "${CMAKE_SOURCE_DIR}/test/test_config.h.in"
    "${CMAKE_BINARY_DIR}/test/test_config.h"
)

add_executable(wp_playerlib_test
  wp_playerlib_test.c
)

target_include_directories(wp_playerlib_test PRIVATE
    ${CMAKE_BINARY_DIR}/test
)

target_link_libraries(wp_playerlib_test
  WpPlayerLib
  Unity
)

add_test(wp_playerlib_test wp_playerlib_test)
