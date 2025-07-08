#include "dart_native_api.h"
#include "wp_player_lib/wp_playerlib.h"
#include <array>
#include <mutex>
#include <shared_mutex>
#include <stdexcept>
#define PUBLIC_FFI_API extern "C" __attribute__((visibility("default"))) __attribute__((used))

#include <dart_api.h>
#include <dart_api_dl.h>
#include <wp_playerlib.h>
// To read my comments about functions go to wp_playerlib.h header-file

/**
 * @brief Seems to be required by flutter to use native port (and maybe other stuff)
 */
PUBLIC_FFI_API intptr_t Dart_InitializeApi (void* data) { return Dart_InitializeApiDL(data); }

// ------------------------------------------------------------------------------------------

Dart_Port         native_port = 0;
std::shared_mutex native_port_mutex{};

// Note: changing this values require change in Dart also
enum Native_message_type : int32_t { Data_request = 1, Cancel_fetch = 2 };

// ------------------------------------------------------------------------------------------

void request_wrapper (const void* _context_ptr, uint32_t id, char const* url, int64_t scheduled_time) {
    std::shared_lock lock(native_port_mutex);
    if (native_port == 0) throw std::runtime_error("Got network request while native port isn't yet set");

    Dart_CObject type_dart, id_dart, url_dart, scheduled_time_dart;

    std::array<Dart_CObject*, 4> obj = {&type_dart, &id_dart, &url_dart, &scheduled_time_dart};

    type_dart.type           = Dart_CObject_kInt32;
    type_dart.value.as_int32 = Native_message_type::Data_request;

    id_dart.type           = Dart_CObject_kInt64; // cause of uint32 and not int32
    id_dart.value.as_int64 = static_cast<int64_t>(id);

    url_dart.type            = Dart_CObject_kString;
    url_dart.value.as_string = url;

    scheduled_time_dart.type           = Dart_CObject_kInt64;
    scheduled_time_dart.value.as_int64 = scheduled_time;

    Dart_CObject args;
    args.type                  = Dart_CObject_kArray;
    args.value.as_array.values = obj.data();
    args.value.as_array.length = obj.size();

    Dart_PostCObject_DL(native_port, &args);
}

void cancel_wrapper (const void* _context_ptr, uint32_t id) {
    std::shared_lock lock(native_port_mutex);
    if (native_port == 0) throw std::runtime_error("Got network request cancellation while native port isn't yet set");

    Dart_CObject type_dart, id_dart;

    std::array<Dart_CObject*, 2> obj = {&type_dart, &id_dart};

    type_dart.type           = Dart_CObject_kInt32;
    type_dart.value.as_int32 = Native_message_type::Cancel_fetch;

    id_dart.type           = Dart_CObject_kInt64; // cause of uint32 and not int32
    id_dart.value.as_int64 = static_cast<int64_t>(id);

    Dart_CObject args;
    args.type                  = Dart_CObject_kArray;
    args.value.as_array.values = obj.data();
    args.value.as_array.length = obj.size();

    if (native_port == 0) {}
    Dart_PostCObject_DL(native_port, &args);
}

PUBLIC_FFI_API void wp_playerlib_register_native_port (Dart_Port port) {
    std::scoped_lock lock(native_port_mutex); // write lock
    native_port = port;
}

// ------------------------------------------------------------------------------------------

PUBLIC_FFI_API void* wp_playerlib_create_wrapper (const double sample_rate, const int buffering_lookahead) {
    WpPlayerLibState* player = wp_playerlib_create(sample_rate, buffering_lookahead);
    wp_playerlib_register_network_request_callbacks(player, &request_wrapper, &cancel_wrapper, nullptr);
    return reinterpret_cast<void*>(player);
}