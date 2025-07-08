add_library(Unity STATIC
  ${CMAKE_CURRENT_SOURCE_DIR}/unity.c
)

target_include_directories(Unity PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}
) 