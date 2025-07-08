package com.wavepaths.player.foreground.types.enums

import android.util.Log
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
enum class ForegroundServiceMethod {
    @SerialName("init") INIT,
    @SerialName("start") START,
    @SerialName("startSessionEarly") START_SESSION_EARLY,
    @SerialName("broadcastUserAdvanceFromPrelude") BROADCAST_USER_ADVANCE_FROM_PRELUDE,
    @SerialName("resume") RESUME,
    @SerialName("pause") PAUSE,
    @SerialName("dispose") DISPOSE;

    companion object {
        private const val TAG = "ForegroundServiceMethod"
        fun fromString(value: String): ForegroundServiceMethod? {
            return try {
                Json.decodeFromString<ForegroundServiceMethod>("\"$value\"")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to parse enum from string: $value")
                null
            }
        }
    }
}
