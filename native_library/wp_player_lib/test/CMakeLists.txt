cmake_minimum_required(VERSION 3.21.2)

project(wp_playerlib_test)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DMA_NO_DEVICE_IO -DMA_NO_THREADING" PARENT_SCOPE)

set(TEST_DATA_DIR "${CMAKE_SOURCE_DIR}/test/testdata")
configure_file(
    "${CMAKE_SOURCE_DIR}/test/test_config.h.in"
    "${CMAKE_BINARY_DIR}/test/test_config.h"
)

add_executable(${PROJECT_NAME}
  wp_playerlib_test.c
)

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_BINARY_DIR}/test
)

target_link_libraries(${PROJECT_NAME}
  WpPlayerLib
  Unity
)

add_test(${PROJECT_NAME} ${PROJECT_NAME} )
