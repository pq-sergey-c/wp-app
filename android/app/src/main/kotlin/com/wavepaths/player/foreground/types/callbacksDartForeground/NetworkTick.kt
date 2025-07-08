package com.wavepaths.player.foreground.types.callbacksDartForeground

import android.util.Log
import com.wavepaths.player.foreground.types.enums.NetworkSessionState
import kotlinx.serialization.json.*

data class NetworkTick(val sessionState: NetworkSessionState) {
    companion object {
        private const val TAG = "NetworkTick"

        // not all field are used from JSON
        fun fromJson(jsonString: String): NetworkTick? {
            try {
                val json = Json.parseToJsonElement(jsonString) as? JsonObject
                if (json == null) return null

                val dataField = json["data"] as? JsonObject
                if (dataField == null) return null

                val sessionState =
                        dataField["sessionState"]?.let {
                            try {
                                Json.decodeFromJsonElement<NetworkSessionState>(it)
                            } catch (e: Exception) {
                                null
                            }
                        }
                if (sessionState == null) return null

                return NetworkTick(sessionState)
            } catch (e: Exception) {
                Log.e(TAG, "Caught exception: $e")
                return null
            }
        }
    }
}
