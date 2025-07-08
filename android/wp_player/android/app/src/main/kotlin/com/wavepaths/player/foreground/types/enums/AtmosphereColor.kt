package com.wavepaths.player.foreground.types.enums

import android.graphics.Color
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.serializer

@Serializable
enum class AtmosphereColor {
    @SerialName("Stillness") STILLNESS,
    @SerialName("Bittersweet") BITTERSWEET,
    @SerialName("Vitality") VITALITY,
    @SerialName("Tension") TENSION,
    @SerialName("Silence") SILENCE;

    val color: Int
        get() {
            return when (this) {
                STILLNESS -> Color.parseColor("#FFB5DECC")
                BITTERSWEET -> Color.parseColor("#FFB9C7DA")
                VITALITY -> Color.parseColor("#FFFDBF68")
                TENSION -> Color.parseColor("#FFE26460")
                SILENCE -> Color.parseColor("#FFFFFFFF")
            }
        }
}

class AtmosphereColorSerializer : KSerializer<AtmosphereColor> {
    private val delegate = serializer<AtmosphereColor>()
    override val descriptor = delegate.descriptor

    override fun serialize(encoder: Encoder, value: AtmosphereColor) {
        delegate.serialize(encoder, value)
    }

    override fun deserialize(decoder: Decoder): AtmosphereColor {
        return try {
            delegate.deserialize(decoder)
        } catch (e: SerializationException) {
            AtmosphereColor.STILLNESS
        }
    }
}
