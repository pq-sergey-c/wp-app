#include "wp_playerlib_custom_decoders_opus.c"

ma_decoding_backend_vtable* pCustomBackendVTables[] =
  {
    &g_ma_decoding_backend_vtable_libopus
  };
