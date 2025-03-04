cmake_minimum_required(VERSION 3.26)
project(WpPlayerlibWasm LANGUAGES C)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -msimd128 -pthread -O3")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msimd128 -pthread -O3")
add_definitions(-DMA_ENABLE_AUDIO_WORKLETS -DMA_AUDIO_WORKLETS_THREAD_STACK_SIZE=524288 -DMA_WEBAUDIO_LATENCY_HINT_PLAYBACK)

set(OPUS_STACK_PROTECTOR OFF)
add_subdirectory(../player build)

add_executable(WpPlayerlibWasm wp_playerlib_wasm.c)
target_link_libraries(WpPlayerlibWasm PRIVATE WpPlayerLib)

# Use  -sSTACK_OVERFLOW_CHECK=2 if there's weird problems, the stack size in miniaudio's audio worklet thread might be too small
set_target_properties(WpPlayerlibWasm PROPERTIES
    COMPILE_WARNING_AS_ERROR ON
    LINK_FLAGS "-sASYNCIFY -sAUDIO_WORKLET=1 -sWASM_WORKERS=1 -sWASM_BIGINT -pthread -sPTHREAD_POOL_SIZE=2 -sALLOW_MEMORY_GROWTH -sMAXIMUM_MEMORY=1000MB -sALLOW_TABLE_GROWTH -sMODULARIZE=1 -sEXPORT_ES6=1 -sENVIRONMENT=web,worker -sEXPORT_NAME=\"'WpPlayerlibWasm'\" -sEXPORTED_FUNCTIONS=_wp_playerlib_wasm_create,_wp_playerlib_wasm_set_session,_wp_playerlib_wasm_get_phase,_wp_playerlib_wasm_get_time_in_phase,_wp_playerlib_wasm_set_phase,_wp_playerlib_wasm_seek_to_time_in_phase,_wp_playerlib_wasm_set_volume,_wp_playerlib_wasm_get_buffered_time,_wp_playerlib_wasm_network_response,_wp_playerlib_wasm_start,_wp_playerlib_wasm_stop,_wp_playerlib_wasm_is_started,_wp_playerlib_wasm_destroy,_wp_playerlib_wasm_malloc_streams,_wp_playerlib_wasm_set_stream,_malloc,_free -sEXPORTED_RUNTIME_METHODS=ccall,cwrap,getValue,setValue,stringToUTF8,UTF8ToString,addFunction,removeFunction,emscriptenGetAudioObject,STACK_SIZE"
)
