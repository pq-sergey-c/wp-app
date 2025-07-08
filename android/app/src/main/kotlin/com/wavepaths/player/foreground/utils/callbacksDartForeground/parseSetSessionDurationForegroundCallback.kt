package com.wavepaths.player.foreground.utils.callbacksDartForeground

import android.util.Log
import kotlin.time.Duration
import kotlin.time.DurationUnit
import kotlin.time.toDuration
import kotlinx.serialization.json.*

private const val TAG = "parseSetPlaybackTimeForegroundCallback"

fun parseSetSessionDurationForegroundCallback(jsonString: String): Duration? {
    try {
        val json = Json.parseToJsonElement(jsonString) as? JsonObject
        if (json == null) return null

        val dataMilliseconds = json["data"] as? JsonPrimitive
        if (dataMilliseconds == null) return null

        return dataMilliseconds.longOrNull?.toDuration(DurationUnit.MILLISECONDS)
    } catch (e: Exception) {
        Log.e(TAG, "Caught exception: $e")
        return null
    }
}
