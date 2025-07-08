package com.wavepaths.player.foreground.types.enums

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.serializer

@Serializable
enum class EmotionalIntensity {
    @SerialName("Low") LOW,
    @SerialName("Medium") MEDIUM,
    @SerialName("High") HIGHT,
    @SerialName("Low to High") ALL,
    @SerialName("None") NONE;

    val circleSizeScale: Double
        get() {
            return when (this) {
                LOW -> 1.0
                MEDIUM -> 1.1
                HIGHT -> 1.2
                ALL -> 1.0
                NONE -> 1.0
            }
        }

    /// [canvasRadius] = min(canvas.width, canvas.height)
    fun getBlurStandardDeviation(canvasRadius: Double): Double {
        return when (this) {
            LOW -> canvasRadius * 0.14
            MEDIUM -> canvasRadius * 0.12
            HIGHT -> canvasRadius * 0.1
            ALL -> canvasRadius * 0.2
            NONE -> canvasRadius * 0.2
        }
    }
}

class EmotionalIntensitySerializer : KSerializer<EmotionalIntensity> {
    private val delegate = serializer<EmotionalIntensity>()
    override val descriptor = delegate.descriptor

    override fun serialize(encoder: Encoder, value: EmotionalIntensity) {
        delegate.serialize(encoder, value)
    }

    override fun deserialize(decoder: Decoder): EmotionalIntensity {
        return try {
            delegate.deserialize(decoder)
        } catch (e: SerializationException) {
            EmotionalIntensity.NONE
        }
    }
}
