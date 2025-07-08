package com.wavepaths.player.foreground.utils.generateAlbumCover

import SeededRandom
import android.graphics.Bitmap
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Shader
import com.wavepaths.player.R
import com.wavepaths.player.core.GlobalApplication
import com.wavepaths.player.foreground.types.enums.AtmosphereColor
import com.wavepaths.player.foreground.types.enums.EmotionalIntensity
import com.wavepaths.player.foreground.types.methodsDartMain.TriadOfAtmosphereColors
import com.wavepaths.player.foreground.utils.generateAlbumCover.types.CircleType
import kotlin.math.min

private const val w = 50
private const val h = 50
private lateinit var generator: SeededRandom
private const val TAG = "Generate album cover (notification)"

// both are approximation
private const val sigmaToRadius = 2.0f
private const val noiseImageScaleFactor = 0.2f

fun generateAlbumCover(
        data: Pair<TriadOfAtmosphereColors, EmotionalIntensity>?,
        seed: String
): Bitmap {
    if (data == null) return generateFallback()
    return generateReal(data.first, data.second, seed)
}

// --------------------------------------------------------------------------

private fun generateFallback(): Bitmap {
    val shader =
            LinearGradient(
                    0f,
                    0f,
                    w.toFloat(),
                    0f,
                    0xFFE91E63.toInt(),
                    0xFF2196F3.toInt(),
                    Shader.TileMode.CLAMP
            )

    return Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).apply {
        Canvas(this)
                .drawRect(0f, 0f, w.toFloat(), h.toFloat(), Paint().apply { this.shader = shader })
    }
}

// --------------------------------------------------------------------------

private fun generateReal(
        atmosphereColors: TriadOfAtmosphereColors,
        emotionalIntensity: EmotionalIntensity,
        seed: String
): Bitmap {
    if (!::generator.isInitialized) generator = SeededRandom.fromString(seed)

    val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    canvas.drawRect(Rect(0, 0, w, h), Paint().apply { color = Color.WHITE })
    canvas.drawRect(
            Rect(0, 0, w, h),
            Paint().apply {
                color = atmosphereColors.first.color
                alpha = (255 * 0.4).toInt()
            }
    )

    drawCircle(canvas, CircleType.TERTIARY, atmosphereColors.third, emotionalIntensity, generator)
    drawCircle(canvas, CircleType.SECONDARY, atmosphereColors.second, emotionalIntensity, generator)
    drawCircle(canvas, CircleType.PRIMARY, atmosphereColors.first, emotionalIntensity, generator)
    drawNoise(canvas)
    return bitmap
}

private fun drawCircle(
        canvas: Canvas,
        circleType: CircleType,
        atmosphereColor: AtmosphereColor,
        emotionalIntensity: EmotionalIntensity,
        generator: SeededRandom
) {
    data class Ceil(val width: Double, val height: Double)

    // position circle in center of cell in grid of 5x5
    val ceil: Ceil = Ceil(width = w / 5.0, height = h / 5.0)

    val x: Double = ceil.width * generator.nextInt(start = 0, end = 4) + ceil.width / 2
    val y: Double = ceil.height * generator.nextInt(start = 0, end = 4) + ceil.height / 2

    val radiusRange = circleType.getRadiusRange(min(w, h).toDouble())
    val radius = generator.nextDouble(start = radiusRange.min, end = radiusRange.max)

    canvas.drawCircle(
            x.toFloat(),
            y.toFloat(),
            radius.toFloat(),
            Paint().apply {
                color = atmosphereColor.color
                alpha = (255 * 0.8).toInt()
                maskFilter =
                        BlurMaskFilter(
                                emotionalIntensity
                                        .getBlurStandardDeviation(min(w, h).toDouble())
                                        .toFloat() * sigmaToRadius,
                                BlurMaskFilter.Blur.NORMAL
                        )
            }
    )
}

private fun drawNoise(canvas: Canvas) {
    val context = GlobalApplication.context
    val drawable = context.getDrawable(R.drawable.fractal_noise) ?: return

    // drawable to bitmap
    val noiseBitmap =
            Bitmap.createBitmap(
                    (drawable.intrinsicWidth * noiseImageScaleFactor).toInt(),
                    (drawable.intrinsicHeight * noiseImageScaleFactor).toInt(),
                    Bitmap.Config.ARGB_8888
            )
    val tempCanvas = Canvas(noiseBitmap)
    drawable.setBounds(0, 0, tempCanvas.width, tempCanvas.height)
    drawable.draw(tempCanvas)

    // ---

    canvas.drawRect(
            Rect(0, 0, w, h),
            Paint().apply {
                shader =
                        android.graphics.BitmapShader(
                                noiseBitmap,
                                Shader.TileMode.REPEAT,
                                Shader.TileMode.REPEAT
                        )
                alpha = (255 * 0.1).toInt()
            }
    )
}
