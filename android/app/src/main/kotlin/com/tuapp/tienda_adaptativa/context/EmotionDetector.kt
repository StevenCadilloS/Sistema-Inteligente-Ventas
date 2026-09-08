package com.tuapp.tienda_adaptativa.context

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.graphics.Rect
import androidx.camera.core.ImageProxy
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
            // FAST, no ACCURATE: con un solo rostro cercano la precision es
            // equivalente y ACCURATE bajaba los fps.
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_NONE)
            // Fraccion minima del ancho del frame que debe ocupar la cara.
            // 0.35 (376 frames sin una sola deteccion) y 0.15 (0 de 257 a un
            // brazo de distancia) dejaban la app usable solo pegada a la
            // cara. 0.10 es el default de ML Kit y cubre la distancia normal
            // de uso de un celular.
            .setMinFaceSize(0.08f)
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
     * Recorta un CUADRADO centrado en la cara, con un margen alrededor.
     *
     * Cuadrado y no el rectangulo de ML Kit: despues esto se escala a 48x48,
     * y un recorte mas alto que ancho se aplastaba al hacerlo, deformando el
     * rostro. Como la proporcion del rectangulo cambia con la distancia y el
     * angulo, la deformacion variaba frame a frame y las predicciones se
     * volvian inestables (misma cara neutral: 5% de "angry" de cerca contra
     * 63% a un brazo de distancia).
     */
    private fun extractFaceFromFrame(
        frameBitmap: Bitmap,
        face: Face
    ): Bitmap {
        val box = face.boundingBox
        val ladoDeseado =
            (maxOf(box.width(), box.height()) * (1f + 2 * FACE_PADDING_RATIO))
                .roundToInt()
        val lado = ladoDeseado.coerceAtMost(
            minOf(frameBitmap.width, frameBitmap.height)
        )

        val left = (box.centerX() - lado / 2)
            .coerceIn(0, frameBitmap.width - lado)
        val top = (box.centerY() - lado / 2)
            .coerceIn(0, frameBitmap.height - lado)

        val safeRect = Rect(left, top, left + lado, top + lado)


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

            val bestIndex = probs.indices.maxByOrNull { probs[it] }
                ?: return EmotionResult(EmotionResult.NEUTRAL, 0f)

            return EmotionResult(
                emotion = mapFerClass(bestIndex),
                confidence = probs[bestIndex].coerceIn(0f, 1f)
            )
        }

        /**
         * Convierte el rostro a 48x48, lo pasa a gris y replica ese gris en
         * los 3 canales que exige el tensor de entrada ([1,48,48,3],
         * verificado sobre el .tflite), normalizando a [0, 1].
         *
         * El gris replicado no es un capricho: FER-2013 es un dataset en
         * escala de grises, asi que un modelo con entrada de 3 canales
         * entrenado sobre el vio gris replicado (Keras con color_mode='rgb').
         * Pasarle el color real de la camara era entrada fuera de
         * distribucion: el modelo respondia sesgado y exigia expresiones
         * exageradas para cambiar de clase.
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

                val grises = IntArray(pixels.size) { i ->
                    val pixel = pixels[i]
                    val red = (pixel shr 16) and 0xFF
                    val green = (pixel shr 8) and 0xFF
                    val blue = pixel and 0xFF

                    (RED_WEIGHT * red + GREEN_WEIGHT * green + BLUE_WEIGHT * blue)
                        .roundToInt()
                        .coerceIn(0, 255)
                }

                ecualizar(grises)

                grises.forEach { gris ->
                    val valor = gris / 255f
                    repeat(INPUT_CHANNELS) { buffer.putFloat(valor) }
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
         * Ecualizacion de histograma sobre el recorte, in situ.
         *
         * Reparte los niveles de gris sobre todo el rango disponible, asi el
         * mismo rostro produce una entrada parecida con luz buena o mala. Sin
         * esto, a contraluz (el caso medido: paneles de techo detras del
         * usuario) la cara llegaba oscura y aplanada, y el modelo necesitaba
         * expresiones exageradas para distinguirlas.
         */
        private fun ecualizar(grises: IntArray) {
            val histograma = IntArray(256)
            grises.forEach { histograma[it]++ }

            val acumulado = IntArray(256)
            var suma = 0
            for (nivel in 0..255) {
                suma += histograma[nivel]
                acumulado[nivel] = suma
            }

            val minimo = acumulado.firstOrNull { it > 0 } ?: return
            val total = grises.size
            // Recorte de un solo tono: no hay rango que repartir.
            if (total == minimo) return

            val mapa = IntArray(256) { nivel ->
                ((acumulado[nivel] - minimo).toFloat() / (total - minimo) * 255f)
                    .roundToInt()
                    .coerceIn(0, 255)
            }

            for (i in grises.indices) {
                grises[i] = mapa[grises[i]]
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
         * Orden de clases del modelo: alfabetico por carpeta, que es como
         * Keras arma las etiquetas con flow_from_directory —
         * angry, disgust, fear, happy, neutral, sad, surprise — y NO el
         * orden canonico de FER-2013 (que pone sad, surprise, neutral al
         * final) que asumia el codigo original.
         *
         * Medido en dispositivo con el vector de probabilidades: una cara
         * relajada da indice 4 en el 56% de los frames, y hacer cara triste
         * lo hunde al 18% en vez de subirlo. Si el 4 fuera "sad" pasaria lo
         * contrario. Por eso antes una cara en reposo se mostraba como
         * "triste 97%".
         *
         * El pipeline del proyecto usa cinco emociones de negocio.
         */
        private fun mapFerClass(index: Int): String = when (index) {
            0 -> EmotionResult.ANGRY      // angry
            1 -> EmotionResult.ANGRY      // disgust: sin regla propia, va a enojo
            2 -> EmotionResult.NEUTRAL    // fear: sin regla propia en el proyecto
            3 -> EmotionResult.HAPPY      // happy
            4 -> EmotionResult.NEUTRAL    // neutral
            5 -> EmotionResult.SAD        // sad
            6 -> EmotionResult.SURPRISE   // surprise
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
        const val FACE_PADDING_RATIO = 0.12f

        const val MODEL_ASSET = "emotion_model.tflite"
        const val INPUT_SIZE = 48
        const val INPUT_CHANNELS = 3
        const val FER_CLASS_COUNT = 7
        const val FLOAT_BYTES = 4

        const val PROBABILITY_EPSILON = 0.05f

        // Luminancia ITU-R BT.601, la conversion a gris estandar.
        const val RED_WEIGHT = 0.299f
        const val GREEN_WEIGHT = 0.587f
        const val BLUE_WEIGHT = 0.114f
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

        private val SUPPORTED = setOf(
            SAD,
            HAPPY,
            SURPRISE,
            NEUTRAL,
            ANGRY,
            NO_FACE
        )

        fun noFace(): EmotionResult = EmotionResult(
            emotion = NO_FACE,
            confidence = 0f
        )
    }
}
