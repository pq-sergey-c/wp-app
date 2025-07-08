package com.wavepaths.player.foreground.utils

import android.util.Log
import kotlinx.serialization.json.*

public fun validateMessageAndGetType(message: String): String? {
    try {
        val json = Json.parseToJsonElement(message)
        if (json !is JsonObject) {
            Log.e(
                    "ERROR",
                    "Incoherent state in message between Main isolate and Foreground service, got incorrect message: $message"
            )
            return null
        }
        val type = json.jsonObject["type"]?.jsonPrimitive?.contentOrNull
        return type
    } catch (e: Exception) {
        Log.e("ERROR", "Caught exception: $e")
        return null
    }
}
