#include "wp_player_lib/wp_playerlib.h"
#include "wrapper_parts/include/wp_wrapper_native_port.h"
#include <dart_api.h>
#include <dart_api_dl.h>
#include <wp_playerlib.h> // In this heaader there are comments about player functions

#define PUBLIC_FFI_API extern "C" __attribute__((visibility("default"))) __attribute__((used))

/**
 * @brief Seems to be required by flutter to use native port (and maybe other stuff)
 */
PUBLIC_FFI_API intptr_t Dart_InitializeApi (void* data) { return Dart_InitializeApiDL(data); }

PUBLIC_FFI_API void wp_playerlib_register_native_port (Dart_Port port) { wp_wrapper::set_native_port(port); }

PUBLIC_FFI_API void* wp_playerlib_create_wrapper (const double sample_rate, const int buffering_lookahead) {
    WpPlayerLibState* player = wp_playerlib_create(sample_rate, buffering_lookahead);
    wp_playerlib_register_network_request_callbacks(
        player, &wp_wrapper::request_wrapper, &wp_wrapper::cancel_wrapper, nullptr
    );
    return reinterpret_cast<void*>(player);
}