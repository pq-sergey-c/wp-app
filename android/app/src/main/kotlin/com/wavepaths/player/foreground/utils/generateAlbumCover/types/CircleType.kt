package com.wavepaths.player.foreground.utils.generateAlbumCover.types

enum class CircleType(val type: String) {
    PRIMARY("primary"),
    SECONDARY("secondary"),
    TERTIARY("tertiary"),
    NONE("none");

    data class RadiusRange(val min: Double, val max: Double)

    /** [canvasRadius] = min(canvas.width, canvas.height) */
    fun getRadiusRange(canvasRadius: Double): RadiusRange {
        val baseRadius = canvasRadius / 2
        return when (this) {
            PRIMARY -> RadiusRange(baseRadius * 0.7, baseRadius * 0.9)
            SECONDARY -> RadiusRange(baseRadius * 0.6, baseRadius * 0.8)
            TERTIARY -> RadiusRange(baseRadius * 0.5, baseRadius * 0.7)
            NONE -> RadiusRange(baseRadius * 0.4, baseRadius * 0.6)
        }
    }
}
