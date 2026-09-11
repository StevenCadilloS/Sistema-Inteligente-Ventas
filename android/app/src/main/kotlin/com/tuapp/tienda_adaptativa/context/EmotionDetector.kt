package com.tuapp.tienda_adaptativa.context

import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions
import java.io.Closeable
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Detector binario de respuesta facial.
 *
 * El flujo comercial solo necesita saber si la reaccion es favorable o
 * desfavorable. Intentar distinguir cinco emociones con FER-2013 introducia
 * errores que despues se reducian igualmente a esos dos grupos. Esta version
 * utiliza la probabilidad de sonrisa de ML Kit, deja una zona intermedia como
 * incierta y rechaza lecturas en las que la cara esta lejos o girada.
 *
 * La imagen se procesa completamente en el dispositivo y nunca se almacena ni
 * se envia al backend.
 */
class EmotionDetector : Closeable {

    private val worker: ExecutorService = Executors.newSingleThreadExecutor()
    private val classifier = BinaryResponseClassifier()

    private val faceDetector: FaceDetector = FaceDetection.getClient(
        FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_ALL)
            // En un frame de 640 px exige aproximadamente 100 px de rostro.
            .setMinFaceSize(MIN_FACE_RATIO)
            .enableTracking()
            .build()
    )

    /** Procesa un frame y cierra siempre el ImageProxy al terminar. */
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

        val inputImage = InputImage.fromMediaImage(
            mediaImage,
            frame.imageInfo.rotationDegrees
        )

        faceDetector
            .process(inputImage)
            .addOnSuccessListener(worker) { faces ->
                try {
                    val face = faces.maxByOrNull {
                        it.boundingBox.width() * it.boundingBox.height()
                    }
                    onResult(
                        if (face == null) {
                            EmotionResult.noFace()
                        } else {
                            classifier.classify(
                                smileProbability = face.smilingProbability,
                                faceWidth = face.boundingBox.width(),
                                faceHeight = face.boundingBox.height(),
                                pitchDegrees = face.headEulerAngleX,
                                yawDegrees = face.headEulerAngleY,
                                rollDegrees = face.headEulerAngleZ
                            )
                        }
                    )
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

    override fun close() {
        faceDetector.close()
        worker.shutdown()
    }

    private companion object {
        const val MIN_FACE_RATIO = 0.16f
    }
}
