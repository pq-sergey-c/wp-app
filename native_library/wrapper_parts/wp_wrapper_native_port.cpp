#include "include/wp_wrapper_native_port.h"
#include <array>
#include <mutex>
#include <stdexcept>

void wp_wrapper::request_wrapper (const void* _context_ptr, uint32_t id, char const* url, int64_t scheduled_time) {
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

void wp_wrapper::cancel_wrapper (const void* _context_ptr, uint32_t id) {
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

void wp_wrapper::set_native_port (Dart_Port port) {
    std::scoped_lock lock(native_port_mutex); // write lock
    wp_wrapper::native_port = port;
}
