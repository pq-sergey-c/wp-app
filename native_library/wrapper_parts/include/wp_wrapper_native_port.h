#ifndef WAVEPATHS_WRAPPER_NATIVE_PORT_H
#define WAVEPATHS_WRAPPER_NATIVE_PORT_H

#include <dart_api.h>
#include <dart_api_dl.h>
#include <dart_native_api.h>
#include <shared_mutex>

namespace wp_wrapper {
// Note: changing this values require change in Dart also
enum Native_message_type : int32_t { Data_request = 1, Cancel_fetch = 2 };

inline Dart_Port         native_port = 0;
inline std::shared_mutex native_port_mutex{};

void request_wrapper (const void* _context_ptr, uint32_t id, char const* url, int64_t scheduled_time);
void cancel_wrapper (const void* _context_ptr, uint32_t id);

void set_native_port (Dart_Port port);
} // namespace wp_wrapper

#endif // WAVEPATHS_WRAPPER_NATIVE_PORT_H