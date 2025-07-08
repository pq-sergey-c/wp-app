cmake_minimum_required(VERSION 3.22.1)

set(TEST_LIB_NAME "${PROJECT_NAME}_test")
# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DMA_NO_DEVICE_IO -DMA_NO_THREADING" PARENT_SCOPE)
# not dev of lib: I tried to change MA_NO_DEVICE_IO to MA_NO_DEVICE_IO_FAKE in code
# while it helped to run it - it could be the reason why tests fail
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DMA_NO_DEVICE_IO_FAKE" PARENT_SCOPE)

include(CTest)
add_subdirectory(vendor/unity)

set(TEST_DATA_DIR "${CMAKE_SOURCE_DIR}/testdata")
configure_file(
    "${CMAKE_SOURCE_DIR}/lib/wp_player_lib/test/test_config.h.in"
    "${CMAKE_BINARY_DIR}/lib/wp_player_lib/test/test_config.h"
)

add_library(${TEST_LIB_NAME}
  wp_playerlib_test.c
)

target_include_directories(${TEST_LIB_NAME}
  PRIVATE ${CMAKE_BINARY_DIR}/test/player
  INTERFACE ${CMAKE_SOURCE_DIR}/lib/wp_player_lib/test/public
)


target_link_libraries(${TEST_LIB_NAME}
  WpPlayerLib
  Unity
)

add_test(${TEST_LIB_NAME} ${TEST_LIB_NAME})
