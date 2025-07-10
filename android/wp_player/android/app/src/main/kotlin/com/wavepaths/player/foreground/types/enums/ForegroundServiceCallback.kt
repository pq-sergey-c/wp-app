package com.wavepaths.player.foreground.types.enums

import android.util.Log
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
enum class ForegroundServiceCallback {
    @SerialName("setBroadcastState") SET_BROADCAST_STATE,
    @SerialName("setSessionDuration") SET_SESSION_DURATION,
    @SerialName("setPlaybackTime") SET_PLAYBACK_TIME,
    @SerialName("setVoiceovers") SET_VOICEOVERS,
    @SerialName("processNetworkTick") PROCESS_NETWORK_TICK,
    @SerialName("disposed") DISPOSED,
    @SerialName("initialized") INITIALIZED,
    @SerialName("log") LOG;

    companion object {
        private const val TAG = "ForegroundServiceCallback"
        fun fromString(value: String): ForegroundServiceCallback? {
            return try {
                Json.decodeFromString<ForegroundServiceCallback>("\"$value\"")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to parse enum from string: $value")
                null
            }
        }
    }
}
