package com.wavepaths.player.foreground.types.methodsDartMain

import android.util.Log
import com.wavepaths.player.foreground.types.enums.AtmosphereColor
import com.wavepaths.player.foreground.types.enums.AtmosphereColorSerializer
import com.wavepaths.player.foreground.types.enums.EmotionalIntensity
import com.wavepaths.player.foreground.types.enums.EmotionalIntensitySerializer
import kotlinx.serialization.json.*

// Session duration as member is temporary
// Note: Not all fields are parsed in JSON
data class DartMainInitMethod(
        val sessionId: String,
        val sessionName: String,
        val artist: String,
        val emotionalIntensity: EmotionalIntensity,
        val atmosphereColors: TriadOfAtmosphereColors
) {

    companion object {
        private const val TAG = "DartMainInitMethod"
        fun fromJson(jsonString: String): DartMainInitMethod? {
            try {
                val json = Json.parseToJsonElement(jsonString) as? JsonObject
                if (json == null) return null

                val dataField = json["data"] as? JsonObject
                if (dataField == null) return null

                val sessionId = dataField["sessionId"]?.jsonPrimitive?.contentOrNull
                if (sessionId == null) return null

                val sessionName = dataField["sessionName"]?.jsonPrimitive?.contentOrNull
                if (sessionName == null) return null

                val artist = dataField["artist"]?.jsonPrimitive?.contentOrNull
                if (artist == null) return null

                val emotionalIntensity =
                        dataField["emotionalIntensity"]?.let {
                            try {
                                Json.decodeFromJsonElement(EmotionalIntensitySerializer(), it)
                            } catch (e: Exception) {
                                null
                            }
                        }
                if (emotionalIntensity == null) return null

                val atmosphereColors =
                        (dataField["atmosphereColors"] as? JsonObject)?.let { atmosphereColorsJson
                            ->
                            TriadOfAtmosphereColors.fromJson(atmosphereColorsJson)
                        }
                if (atmosphereColors == null) return null

                return DartMainInitMethod(
                        sessionId,
                        sessionName,
                        artist,
                        emotionalIntensity,
                        atmosphereColors
                )
            } catch (e: Exception) {
                Log.e(TAG, "Caught exception: $e")
                return null
            }
        }
    }
}

data class TriadOfAtmosphereColors(
        val first: AtmosphereColor,
        val second: AtmosphereColor,
        val third: AtmosphereColor,
) {
    companion object {
        fun fromJson(json: JsonObject): TriadOfAtmosphereColors? {
            var first: AtmosphereColor?
            var second: AtmosphereColor?
            var third: AtmosphereColor?
            try {
                first =
                        json["first"]?.let {
                            Json.decodeFromJsonElement(AtmosphereColorSerializer(), it)
                        }
                second =
                        json["second"]?.let {
                            Json.decodeFromJsonElement(AtmosphereColorSerializer(), it)
                        }
                third =
                        json["third"]?.let {
                            Json.decodeFromJsonElement(AtmosphereColorSerializer(), it)
                        }
            } catch (e: Exception) {
                return null
            }
            if (first == null || second == null || third == null) return null

            return TriadOfAtmosphereColors(first, second, third)
        }
    }
}
