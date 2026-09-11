package com.tuapp.tienda_adaptativa.channel

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import com.tuapp.tienda_adaptativa.context.CameraManager
import com.tuapp.tienda_adaptativa.context.EmotionDetector
import com.tuapp.tienda_adaptativa.context.EmotionResult
import com.tuapp.tienda_adaptativa.processing.EmotionProcessor
import androidx.camera.core.Preview
import io.flutter.plugin.common.EventChannel

class EmotionChannelHandler(
    private val activity: FlutterFragmentActivity
) : EventChannel.StreamHandler {

    private val cameraManager = CameraManager(activity)
    private val emotionDetector = EmotionDetector()
    private val emotionProcessor = EmotionProcessor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val diagnosticMode = (arguments as? Map<*, *>)?.get("diagnostic") == true
        emotionProcessor.reset()
        cameraManager.startCamera(
            onFrameCaptured = { frame ->
                emotionDetector.detectEmotion(
                    frame,
                    onResult = { crudo ->
                        if (diagnosticMode) {
                            mainHandler.post {
                                events?.success(
                                    mapOf(
                                        "emotion" to crudo.emotion,
                                        "confidence" to crudo.confidence,
                                        "smileProbability" to crudo.smileProbability,
                                        "status" to crudo.status,
                                    )
                                )
                            }
                            return@detectEmotion
                        }

                        val procesado = emotionProcessor.process(crudo)
                        if (procesado.rostroPerdido) {
                            // Sin este aviso la UI se quedaba con la ultima
                            // respuesta para siempre aunque ya no haya nadie
                            // delante de la camara.
                            mainHandler.post {
                                events?.success(
                                    mapOf(
                                        "emotion" to EmotionResult.NO_FACE,
                                        "confidence" to 0.0f,
                                    )
                                )
                            }
                        } else if (procesado.isStable) {
                            // EventSink.success() es @UiThread, pero este callback
                            // corre en el executor de ML Kit: sin el post al hilo
                            // principal, Flutter lanza "Methods marked with
                            // @UiThread must be executed on the main thread" y el
                            // evento nunca cruza a Dart.
                            mainHandler.post {
                                events?.success(
                                    mapOf(
                                        "emotion" to procesado.emotion,
                                        "confidence" to procesado.confidence,
                                    )
                                )
                            }
                        }
                    },
                    onError = { error ->
                        Log.e(TAG, "error detectando emocion", error)
                        mainHandler.post {
                            events?.error(
                                "DETECTOR_ERROR",
                                "No se pudo analizar la imagen de la camara.",
                                null
                            )
                        }
                    },
                )
            },
            onError = { error ->
                Log.e(TAG, "no se pudo iniciar la camara", error)
                mainHandler.post {
                    events?.error(
                        "CAMERA_UNAVAILABLE",
                        error.message ?: "No se pudo iniciar la camara.",
                        null
                    )
                }
            }
        )
    }

    override fun onCancel(arguments: Any?) {
        cameraManager.stopCamera()
        emotionProcessor.reset()
    }

    fun attachPreview(surfaceProvider: Preview.SurfaceProvider) {
        cameraManager.attachPreview(surfaceProvider)
    }

    fun detachPreview(surfaceProvider: Preview.SurfaceProvider) {
        cameraManager.detachPreview(surfaceProvider)
    }

    fun dispose() {
        cameraManager.release()
        emotionDetector.close()
    }

    private companion object {
        const val TAG = "EmotionChannel"
    }
}
