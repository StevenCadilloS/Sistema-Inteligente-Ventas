package com.tuapp.tiendaadaptativa.context

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
import java.io.Closeable
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.roundToInt

/**
 * CAPTURA DE CONTEXTO - EMOCIONES FACIALES
 * Fase 1 del Pipeline: CONTEXTO
 *
 * Responsabilidad:
 * - Recibir frames de CameraManager mediante CameraX.
 * - Detectar rostros con Google ML Kit Face Detection.
 * - Seleccionar y recortar el rostro principal.
 * - Clasificar la expresión con TensorFlow Lite (FER-2013).
 * - Devolver emoción y confianza como EmotionResult.
 *
 * Flujo:
 * Frame -> ML Kit -> rostro -> TFLite -> EmotionResult
 *
 * EmotionProcessor recibe después este resultado crudo y se encarga
 * de estabilizarlo entre varios frames.
 */
class EmotionDetector(
    context: Context,
    private val classifier: TfliteEmotionClassifier = TfliteEmotionClassifier(context)
) : Closeable {

    private val worker: ExecutorService = Executors.newSingleThreadExecutor()

    private val faceDetector: FaceDetector = FaceDetection.getClient(
        FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
            .enableTracking()
            .build()
    )

    /**
     * Procesa un frame de CameraX de manera asíncrona.
     *
     * Esta función consume el ImageProxy y garantiza su cierre al terminar,
     * incluso cuando ML Kit o TensorFlow Lite producen un error.
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

                    val faceBitmap = extractFaceFromFrame(
                        frameBitmap = uprightFrame,
                        face = mainFace
                    )

                    val result = classifier.classify(faceBitmap)
                    onResult(result)

                    if (faceBitmap !== uprightFrame) {
                        faceBitmap.recycle()
                    }
                    uprightFrame.recycle()
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
     * Si aparecen varias personas se usa el rostro de mayor área, que suele
     * corresponder al usuario que está frente a la cámara del celular.
     */
    private fun selectMainFace(faces: List<Face>): Face? =
        faces.maxByOrNull { face ->
            face.boundingBox.width() * face.boundingBox.height()
        }

    /**
     * Recorta únicamente la región de la cara y conserva un pequeño margen
     * alrededor para no perder frente, mandíbula y mejillas.
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
            "ML Kit devolvió una región facial inválida: $safeRect"
        }

        return Bitmap.createBitmap(
            frameBitmap,
            safeRect.left,
            safeRect.top,
            safeRect.width(),
            safeRect.height()
        )
    }

    private fun rotateBitmap(
        bitmap: Bitmap,
        rotationDegrees: Int
    ): Bitmap {
        if (rotationDegrees == 0) {
            return bitmap
        }

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

        if (rotated !== bitmap) {
            bitmap.recycle()
        }

        return rotated
    }

    override fun close() {
        faceDetector.close()
        classifier.close()
        worker.shutdown()
    }

    private companion object {
        const val FACE_PADDING_RATIO = 0.12f
    }
}

/**
 * Resultado crudo de la fase CONTEXTO.
 */
data class EmotionResult(
    val emotion: String,
    val confidence: Float
) {
    init {
        require(emotion in EmotionLabels.supported) {
            "Emoción no soportada por el pipeline: $emotion"
        }
        require(confidence in 0f..1f) {
            "La confianza debe estar entre 0.0 y 1.0"
        }
    }

    companion object {
        fun noFace(): EmotionResult = EmotionResult(
            emotion = EmotionLabels.NO_FACE,
            confidence = 0f
        )
    }
}
