cmake_minimum_required(VERSION 3.22.2)
project(WpPlayerLibApple LANGUAGES C Swift OBJC)

set(CMAKE_XCODE_ATTRIBUTE_BUILD_LIBRARY_FOR_DISTRIBUTION YES)
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO)
set(CMAKE_Swift_LANGUAGE_VERSION 5.9)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -x objective-c -O3")

add_subdirectory(../player build)

add_library(WpPlayerLibApple SHARED WpPlayerLibBridge.swift NetworkManager.swift)
target_link_libraries(WpPlayerLibApple PRIVATE WpPlayerLib)
set_target_properties(WpPlayerLibApple PROPERTIES
    FRAMEWORK TRUE
    COMPILE_WARNING_AS_ERROR ON
    MACOSX_FRAMEWORK_IDENTIFIER WpPlayerLibApple
    MACOSX_FRAMEWORK_BUNDLE_VERSION 0.5.0
    MACOSX_FRAMEWORK_SHORT_VERSION_STRING 0.5.0
)

install(TARGETS WpPlayerLibApple DESTINATION lib)
