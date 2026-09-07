package com.tuapp.tienda_adaptativa.context

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.graphics.Rect
import androidx.camera.core.ImageProxy
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions
import org.tensorflow.lite.Interpreter
import java.io.Closeable
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.roundToInt

/**
 * CONTEXTO - DETECCION Y CLASIFICACION DE EXPRESIONES FACIALES
 * Fase 1 del pipeline adaptativo.
 *
 * Responsabilidades:
 * - Recibir frames producidos por CameraManager/CameraX.
 * - Detectar el rostro principal con Google ML Kit.
 * - Recortar la region facial.
 * - Preparar la imagen a 48x48 en escala de grises.
 * - Ejecutar el modelo FER-2013 con TensorFlow Lite.
 * - Devolver un EmotionResult crudo para EmotionProcessor.
 *
 * Flujo:
 * CameraManager -> EmotionDetector -> EmotionProcessor
 */
class EmotionDetector(context: Context) : Closeable {

    private val worker: ExecutorService = Executors.newSingleThreadExecutor()
    private val classifier = TfliteClassifier(context)

    private val faceDetector: FaceDetector = FaceDetection.getClient(
        FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_NONE)
            .setMinFaceSize(0.35f)
            .enableTracking()
            .build()
    )

    /**
     * Procesa un frame de CameraX de forma asincrona.
     * El ImageProxy se cierra siempre al finalizar el procesamiento.
     */
    fun detectEmotion(
        frame: ImageProxy,
        onResult: (EmotionResult) -> Unit,
        onError: (Throwable) -> Unit = {}
    ) {
        val mediaImage = frame.image

        if (mediaImage == null) {
            frame.close()
            onResult(EmotionResult.noFace())
            return
        }

        val rotationDegrees = frame.imageInfo.rotationDegrees
        val inputImage = InputImage.fromMediaImage(mediaImage, rotationDegrees)

        faceDetector
            .process(inputImage)
            .addOnSuccessListener(worker) { faces ->
                try {
                    val mainFace = selectMainFace(faces)
                    if (mainFace == null) {
                        onResult(EmotionResult.noFace())
                        return@addOnSuccessListener
                    }

                    val uprightFrame = rotateBitmap(
                        bitmap = frame.toBitmap(),
                        rotationDegrees = rotationDegrees
                    )

                    try {
                        val faceBitmap = extractFaceFromFrame(
                            frameBitmap = uprightFrame,
                            face = mainFace
                        )

                        try {
                            onResult(classifier.classify(faceBitmap))
                        } finally {
                            if (!faceBitmap.isRecycled) {
                                faceBitmap.recycle()
                            }
                        }
                    } finally {
                        if (!uprightFrame.isRecycled) {
                            uprightFrame.recycle()
                        }
                    }
                } catch (error: Throwable) {
                    onError(error)
                } finally {
                    frame.close()
                }
            }
            .addOnFailureListener(worker) { error ->
                try {
                    onError(error)
                } finally {
                    frame.close()
                }
            }
    }

    /**
     * Si aparecen varios rostros, usa el de mayor area como rostro principal.
     */
    private fun selectMainFace(faces: List<Face>): Face? =
        faces.maxByOrNull { face ->
            face.boundingBox.width() * face.boundingBox.height()
        }

    /**
     * Recorta la cara conservando un pequeno margen alrededor.
     */
    private fun extractFaceFromFrame(
        frameBitmap: Bitmap,
        face: Face
    ): Bitmap {
        val box = face.boundingBox
        val horizontalPadding = (box.width() * FACE_PADDING_RATIO).roundToInt()
        val verticalPadding = (box.height() * FACE_PADDING_RATIO).roundToInt()

        val safeRect = Rect(
            (box.left - horizontalPadding).coerceAtLeast(0),
            (box.top - verticalPadding).coerceAtLeast(0),
            (box.right + horizontalPadding).coerceAtMost(frameBitmap.width),
            (box.bottom + verticalPadding).coerceAtMost(frameBitmap.height)
        )

        require(safeRect.width() > 0 && safeRect.height() > 0) {
            "ML Kit devolvio una region facial invalida: $safeRect"
        }

        return Bitmap.createBitmap(
            frameBitmap,
            safeRect.left,
            safeRect.top,
            safeRect.width(),
            safeRect.height()
        )
    }

    private fun rotateBitmap(bitmap: Bitmap, rotationDegrees: Int): Bitmap {
        if (rotationDegrees == 0) return bitmap

        val matrix = Matrix().apply {
            postRotate(rotationDegrees.toFloat())
        }

        val rotated = Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true
        )

        if (rotated !== bitmap && !bitmap.isRecycled) {
            bitmap.recycle()
        }

        return rotated
    }

    override fun close() {
        faceDetector.close()
        classifier.close()
        worker.shutdown()
    }

    /**
     * Clasificador TFLite encapsulado dentro de EmotionDetector para mantener
     * la estructura original del proyecto sin crear clases/archivos adicionales.
     */
    private class TfliteClassifier(context: Context) : Closeable {

        private val interpreter: Interpreter

        init {
            val modelBuffer = loadModel(context)
            val options = Interpreter.Options().apply {
                setNumThreads(2)
            }

            interpreter = Interpreter(modelBuffer, options)

            require(
                interpreter.getInputTensor(0).numElements() ==
                    INPUT_SIZE * INPUT_SIZE * INPUT_CHANNELS
            ) {
                "El modelo debe recibir una imagen de $INPUT_SIZE x $INPUT_SIZE x $INPUT_CHANNELS."
            }
            require(interpreter.getOutputTensor(0).numElements() == FER_CLASS_COUNT) {
                "El modelo debe devolver $FER_CLASS_COUNT clases FER-2013."
            }
        }

        @Synchronized
        fun classify(faceBitmap: Bitmap): EmotionResult {
            require(faceBitmap.width > 0 && faceBitmap.height > 0) {
                "El rostro recibido esta vacio."
            }

            val input = preprocess(faceBitmap)
            val rawOutput = Array(1) { FloatArray(FER_CLASS_COUNT) }
            interpreter.run(input, rawOutput)

            val probs = toProbabilities(rawOutput[0])
            Log.d(TAG, "raw_logits=${rawOutput[0].map { "%.3f".format(it) }}")
            Log.d(TAG, "probs=${probs.map { "%.3f".format(it) }}")

            val bestIndex = probs.indices.maxByOrNull { probs[it] }
                ?: return EmotionResult(EmotionResult.NEUTRAL, 0f)

            return EmotionResult(
                emotion = mapFerClass(bestIndex),
                confidence = probs[bestIndex].coerceIn(0f, 1f)
            )
        }

        /**
         * Convierte el rostro a 48x48 RGB y normaliza cada canal a [0, 1].
         * El modelo (emotion_model.tflite) espera shape [1, 48, 48, 3], no
         * escala de grises - verificado inspeccionando el tensor de entrada
         * real del .tflite (input.shape=[1,48,48,3]), distinto de lo que
         * asumia el codigo original.
         */
        private fun preprocess(bitmap: Bitmap): ByteBuffer {
            val scaled = Bitmap.createScaledBitmap(
                bitmap,
                INPUT_SIZE,
                INPUT_SIZE,
                true
            )

            try {
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
                    .allocateDirect(INPUT_SIZE * INPUT_SIZE * INPUT_CHANNELS * FLOAT_BYTES)
                    .order(ByteOrder.nativeOrder())

                pixels.forEach { pixel ->
                    val red = (pixel shr 16) and 0xFF
                    val green = (pixel shr 8) and 0xFF
                    val blue = pixel and 0xFF

                    buffer.putFloat(red / 255f)
                    buffer.putFloat(green / 255f)
                    buffer.putFloat(blue / 255f)
                }

                buffer.rewind()
                return buffer
            } finally {
                if (scaled !== bitmap && !scaled.isRecycled) {
                    scaled.recycle()
                }
            }
        }

        /**
         * Conserva probabilidades si el modelo ya aplica Softmax; de lo
         * contrario convierte logits a probabilidades con Softmax estable.
         */
        private fun toProbabilities(values: FloatArray): FloatArray {
            val sum = values.sum()
            val alreadyProbabilities =
                values.all { it in 0f..1f } &&
                    abs(sum - 1f) <= PROBABILITY_EPSILON

            if (alreadyProbabilities) return values.copyOf()

            val max = values.maxOrNull() ?: 0f
            val exponentials = DoubleArray(values.size) { index ->
                exp((values[index] - max).toDouble())
            }
            val denominator = exponentials.sum().takeIf { it > 0.0 } ?: 1.0

            return FloatArray(values.size) { index ->
                (exponentials[index] / denominator).toFloat()
            }
        }

        /**
         * Orden FER-2013 del modelo:
         * angry, disgust, fear, happy, sad, surprise, neutral.
         *
         * El pipeline del proyecto usa cinco emociones de negocio.
         */
        private fun mapFerClass(index: Int): String = when (index) {
            0 -> EmotionResult.ANGRY      // angry
            1 -> EmotionResult.UNKNOWN    // disgust: no existe regla propia
            2 -> EmotionResult.UNKNOWN    // fear: no existe regla propia
            3 -> EmotionResult.HAPPY
            4 -> EmotionResult.SAD
            5 -> EmotionResult.SURPRISE
            6 -> EmotionResult.NEUTRAL
            else -> EmotionResult.NEUTRAL
        }

        private fun loadModel(context: Context): ByteBuffer {
            val bytes = context.assets.open(MODEL_ASSET).use { stream ->
                stream.readBytes()
            }

            require(bytes.isNotEmpty()) {
                "El modelo TFLite '$MODEL_ASSET' esta vacio."
            }

            return ByteBuffer
                .allocateDirect(bytes.size)
                .order(ByteOrder.nativeOrder())
                .apply {
                    put(bytes)
                    rewind()
                }
        }

        override fun close() {
            interpreter.close()
        }

        private companion object {
            const val TAG = "EmotionDetector"
        }
    }

    private companion object {
        const val FACE_PADDING_RATIO = 0.12f

        const val MODEL_ASSET = "emotion_model.tflite"
        const val INPUT_SIZE = 48
        const val INPUT_CHANNELS = 3
        const val FER_CLASS_COUNT = 7
        const val FLOAT_BYTES = 4

        const val PROBABILITY_EPSILON = 0.05f
    }
}

/**
 * Resultado crudo producido por la fase CONTEXTO.
 */
data class EmotionResult(
    val emotion: String,
    val confidence: Float
) {
    init {
        require(emotion in SUPPORTED) {
            "Emocion no soportada por el pipeline: $emotion"
        }
        require(confidence in 0f..1f) {
            "La confianza debe estar entre 0.0 y 1.0"
        }
    }

    companion object {
        const val SAD = "triste"
        const val HAPPY = "feliz"
        const val SURPRISE = "sorpresa"
        const val NEUTRAL = "neutral"
        const val ANGRY = "enojo"
        const val NO_FACE = "no_face"
        const val UNKNOWN = "unknown"

        private val SUPPORTED = setOf(
            SAD,
            HAPPY,
            SURPRISE,
            NEUTRAL,
            ANGRY,
            NO_FACE,
            UNKNOWN
        )

        fun noFace(): EmotionResult = EmotionResult(
            emotion = NO_FACE,
            confidence = 0f
        )
    }
}
