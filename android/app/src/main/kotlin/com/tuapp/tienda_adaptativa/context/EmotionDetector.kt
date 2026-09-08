package com.tuapp.tienda_adaptativa.context

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.graphics.Rect
import android.os.SystemClock
import androidx.camera.core.ImageProxy
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions
import org.tensorflow.lite.DataType
import org.tensorflow.lite.Interpreter
import java.io.Closeable
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.roundToInt

/**
 * CONTEXTO - DETECCION Y CLASIFICACION DE EXPRESIONES FACIALES
 * Fase 1 del pipeline adaptativo.
 *
 * Responsabilidades:
 * - Recibir frames producidos por CameraManager/CameraX.
 * - Detectar el rostro principal con Google ML Kit.
 * - Recortar la region facial.
 * - Preparar el rostro con el contrato RGB 112x112 de EmotiScan.
 * - Ejecutar EmotiScan FaceExpressionNet con TensorFlow Lite.
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
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_NONE)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_NONE)
            .setMinFaceSize(0.25f)
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
        val detectionStartedAt = SystemClock.elapsedRealtime()

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
                            val inferenceStartedAt = SystemClock.elapsedRealtime()
                            val result = classifier.classify(faceBitmap)
                            Log.d(
                                TAG,
                                "fer=${result.emotion}(${"%.3f".format(result.confidence)}) " +
                                    "deteccionMs=${inferenceStartedAt - detectionStartedAt} " +
                                    "inferenciaMs=${SystemClock.elapsedRealtime() - inferenceStartedAt}"
                            )
                            onResult(result)
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
                setNumThreads(4)
            }

            interpreter = Interpreter(modelBuffer, options)

            val inputTensor = interpreter.getInputTensor(0)
            val outputTensor = interpreter.getOutputTensor(0)

            require(inputTensor.shape().contentEquals(INPUT_SHAPE)) {
                "EmotiScan debe recibir ${INPUT_SHAPE.contentToString()}; " +
                    "tensor real=${inputTensor.shape().contentToString()}."
            }
            require(inputTensor.dataType() == DataType.FLOAT32) {
                "La entrada de EmotiScan debe ser FLOAT32; tipo real=${inputTensor.dataType()}."
            }
            require(outputTensor.shape().contentEquals(OUTPUT_SHAPE)) {
                "EmotiScan debe devolver ${OUTPUT_SHAPE.contentToString()}; " +
                    "tensor real=${outputTensor.shape().contentToString()}."
            }
            require(outputTensor.dataType() == DataType.FLOAT32) {
                "La salida de EmotiScan debe ser FLOAT32; tipo real=${outputTensor.dataType()}."
            }
        }

        @Synchronized
        fun classify(faceBitmap: Bitmap): EmotionResult {
            require(faceBitmap.width > 0 && faceBitmap.height > 0) {
                "El rostro recibido esta vacio."
            }

            val input = preprocess(faceBitmap)
            val output = Array(1) { FloatArray(EMOTION_CLASS_COUNT) }
            interpreter.run(input, output)

            val probs = output[0]
            require(probs.all { it.isFinite() }) {
                "EmotiScan devolvio probabilidades no finitas."
            }
            Log.d(TAG, "probs=${probs.map { "%.3f".format(it) }}")

            val bestIndex = probs.indices.maxByOrNull { probs[it] }
                ?: return EmotionResult(EmotionResult.NEUTRAL, 0f)

            return EmotionResult(
                emotion = mapEmotiScanClass(bestIndex),
                confidence = probs[bestIndex].coerceIn(0f, 1f)
            )
        }

        /**
         * Reproduce el contrato de EmotiScan:
         * rostro -> RGB 112x112 -> float32 en rango 0..255.
         * La resta de la media RGB y la division entre 255 forman parte del
         * propio grafo TFLite, por lo que no se normaliza aqui.
         */
        private fun preprocess(bitmap: Bitmap): ByteBuffer {
            val resized = Bitmap.createScaledBitmap(
                bitmap,
                INPUT_SIZE,
                INPUT_SIZE,
                true
            )

            try {
                val pixels = IntArray(INPUT_SIZE * INPUT_SIZE)
                resized.getPixels(
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

                pixels.forEach { color ->
                    buffer.putFloat(((color shr 16) and 0xFF).toFloat())
                    buffer.putFloat(((color shr 8) and 0xFF).toFloat())
                    buffer.putFloat((color and 0xFF).toFloat())
                }

                buffer.rewind()
                return buffer
            } finally {
                if (resized !== bitmap && !resized.isRecycled) {
                    resized.recycle()
                }
            }
        }

        /**
         * Orden publicado por EmotiScan:
         * neutral, happy, sad, angry, fearful, disgusted, surprised.
         *
         * El pipeline del proyecto usa cinco emociones de negocio.
         */
        private fun mapEmotiScanClass(index: Int): String = when (index) {
            0 -> EmotionResult.NEUTRAL
            1 -> EmotionResult.HAPPY
            2 -> EmotionResult.SAD
            3 -> EmotionResult.ANGRY
            4 -> EmotionResult.UNKNOWN    // fearful: no existe regla propia
            5 -> EmotionResult.UNKNOWN    // disgusted: no existe regla propia
            6 -> EmotionResult.SURPRISE
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
    }

    private companion object {
        const val TAG = "EmotionDetector"
        const val FACE_PADDING_RATIO = 0.12f

        const val MODEL_ASSET = "emotion_model.tflite"
        const val INPUT_SIZE = 112
        const val INPUT_CHANNELS = 3
        const val EMOTION_CLASS_COUNT = 7
        const val FLOAT_BYTES = 4
        val INPUT_SHAPE = intArrayOf(1, INPUT_SIZE, INPUT_SIZE, INPUT_CHANNELS)
        val OUTPUT_SHAPE = intArrayOf(1, EMOTION_CLASS_COUNT)
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
