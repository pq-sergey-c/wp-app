cmake_minimum_required(VERSION 3.22.2)

project(wp_encoderlib_test)

set(TEST_DATA_DIR "${CMAKE_SOURCE_DIR}/test/testdata")
configure_file(
    "${CMAKE_SOURCE_DIR}/test/test_config.h.in"
    "${CMAKE_BINARY_DIR}/test/test_config.h"
)

add_executable(wp_encoderlib_test
  wp_encoderlib_test.c
)

target_include_directories(wp_encoderlib_test PRIVATE
    ${CMAKE_BINARY_DIR}/test
)

target_link_libraries(wp_encoderlib_test
  WpEncoderLib
  Unity
)

add_test(wp_encoderlib_test wp_encoderlib_test)
