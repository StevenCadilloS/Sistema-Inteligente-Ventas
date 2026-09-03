package com.tuapp.tiendaadaptativa.context

import android.content.Context
import android.graphics.Bitmap
import org.tensorflow.lite.Interpreter
import java.io.Closeable
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.math.exp

/**
 * Clasificador TensorFlow Lite basado en FER-2013.
 *
 * El modelo esperado recibe una imagen facial 48x48 en escala de grises y
 * devuelve las siete clases FER-2013 en este orden:
 * angry, disgust, fear, happy, sad, surprise, neutral.
 *
 * El resto del proyecto trabaja con cinco emociones. Por eso:
 * - angry y disgust -> "enojo"
 * - fear -> "neutral" (el proyecto no define una adaptación específica)
 * - happy -> "feliz"
 * - sad -> "triste"
 * - surprise -> "sorpresa"
 * - neutral -> "neutral"
 */
class TfliteEmotionClassifier(
    context: Context,
    modelAssetName: String = DEFAULT_MODEL_ASSET
) : Closeable {

    private val interpreter: Interpreter

    init {
        val modelBuffer = loadModel(context, modelAssetName)
        val options = Interpreter.Options().apply {
            setNumThreads(2)
        }
        interpreter = Interpreter(modelBuffer, options)

        require(interpreter.getInputTensor(0).numElements() == INPUT_SIZE * INPUT_SIZE) {
            "El modelo TFLite debe recibir $INPUT_SIZE x $INPUT_SIZE valores de entrada."
        }

        require(interpreter.getOutputTensor(0).numElements() == FER_CLASS_COUNT) {
            "El modelo TFLite debe devolver $FER_CLASS_COUNT clases FER-2013."
        }
    }

    /**
     * Preprocesa el rostro y devuelve la emoción con mayor probabilidad.
     */
    @Synchronized
    fun classify(faceBitmap: Bitmap): EmotionResult {
        require(faceBitmap.width > 0 && faceBitmap.height > 0) {
            "El rostro recibido está vacío."
        }

        val input = preprocess(faceBitmap)
        val rawOutput = Array(1) { FloatArray(FER_CLASS_COUNT) }

        interpreter.run(input, rawOutput)

        val probabilities = toProbabilities(rawOutput[0])
        val bestIndex = probabilities.indices.maxByOrNull { probabilities[it] }
            ?: return EmotionResult(EmotionLabels.NEUTRAL, 0f)

        return EmotionResult(
            emotion = mapFerClass(bestIndex),
            confidence = probabilities[bestIndex].coerceIn(0f, 1f)
        )
    }

    /**
     * Convierte el rostro a 48x48 grayscale y normaliza cada píxel a [0, 1].
     */
    private fun preprocess(bitmap: Bitmap): ByteBuffer {
        val scaled = Bitmap.createScaledBitmap(
            bitmap,
            INPUT_SIZE,
            INPUT_SIZE,
            true
        )

        val pixels = IntArray(INPUT_SIZE * INPUT_SIZE)
        scaled.getPixels(
            pixels,
            0,
            INPUT_SIZE,
            0,
            0,
            INPUT_SIZE,
            INPUT_SIZE
        )

        val buffer = ByteBuffer
            .allocateDirect(INPUT_SIZE * INPUT_SIZE * FLOAT_BYTES)
            .order(ByteOrder.nativeOrder())

        pixels.forEach { pixel ->
            val red = (pixel shr 16) and 0xFF
            val green = (pixel shr 8) and 0xFF
            val blue = pixel and 0xFF

            val gray = (
                RED_WEIGHT * red +
                    GREEN_WEIGHT * green +
                    BLUE_WEIGHT * blue
                ) / 255f

            buffer.putFloat(gray)
        }

        buffer.rewind()

        if (scaled !== bitmap) {
            scaled.recycle()
        }

        return buffer
    }

    /**
     * Algunos modelos terminan en Softmax y otros entregan logits.
     * Si la salida ya parece una distribución de probabilidad se conserva;
     * en caso contrario se aplica Softmax de forma estable.
     */
    private fun toProbabilities(values: FloatArray): FloatArray {
        val sum = values.sum()
        val alreadyProbabilities =
            values.all { it in 0f..1f } && abs(sum - 1f) <= PROBABILITY_EPSILON

        if (alreadyProbabilities) {
            return values.copyOf()
        }

        val max = values.maxOrNull() ?: 0f
        val exponentials = DoubleArray(values.size) { index ->
            exp((values[index] - max).toDouble())
        }
        val denominator = exponentials.sum().takeIf { it > 0.0 } ?: 1.0

        return FloatArray(values.size) { index ->
            (exponentials[index] / denominator).toFloat()
        }
    }

    private fun mapFerClass(index: Int): String = when (index) {
        0 -> EmotionLabels.ANGRY      // angry
        1 -> EmotionLabels.ANGRY      // disgust
        2 -> EmotionLabels.NEUTRAL    // fear: sin regla específica en el proyecto
        3 -> EmotionLabels.HAPPY
        4 -> EmotionLabels.SAD
        5 -> EmotionLabels.SURPRISE
        6 -> EmotionLabels.NEUTRAL
        else -> EmotionLabels.NEUTRAL
    }

    override fun close() {
        interpreter.close()
    }

    private fun loadModel(context: Context, assetName: String): ByteBuffer {
        val bytes = context.assets.open(assetName).use { stream ->
            stream.readBytes()
        }

        require(bytes.isNotEmpty()) {
            "El modelo TFLite '$assetName' está vacío."
        }

        return ByteBuffer
            .allocateDirect(bytes.size)
            .order(ByteOrder.nativeOrder())
            .apply {
                put(bytes)
                rewind()
            }
    }

    private companion object {
        const val DEFAULT_MODEL_ASSET = "emotion_model.tflite"
        const val INPUT_SIZE = 48
        const val FER_CLASS_COUNT = 7
        const val FLOAT_BYTES = 4

        const val RED_WEIGHT = 0.299f
        const val GREEN_WEIGHT = 0.587f
        const val BLUE_WEIGHT = 0.114f
        const val PROBABILITY_EPSILON = 0.05f
    }
}
