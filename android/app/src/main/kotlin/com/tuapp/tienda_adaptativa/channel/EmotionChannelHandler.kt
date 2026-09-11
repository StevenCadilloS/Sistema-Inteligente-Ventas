package com.tuapp.tienda_adaptativa.channel

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import com.tuapp.tienda_adaptativa.context.CameraManager
import com.tuapp.tienda_adaptativa.context.EmotionDetector
import com.tuapp.tienda_adaptativa.context.EmotionResult
import com.tuapp.tienda_adaptativa.processing.EmotionProcessor
import io.flutter.plugin.common.EventChannel

class EmotionChannelHandler(
    private val activity: FlutterFragmentActivity
) : EventChannel.StreamHandler {

    private val cameraManager = CameraManager(activity)
    private val emotionDetector = EmotionDetector()
    private val emotionProcessor = EmotionProcessor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        cameraManager.startCamera { frame ->
            emotionDetector.detectEmotion(
                frame,
                onResult = { crudo ->
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
                onError = { error -> Log.e(TAG, "error detectando emocion", error) },
            )
        }
    }

    override fun onCancel(arguments: Any?) {
        cameraManager.stopCamera()
    }

    fun dispose() {
        cameraManager.release()
        emotionDetector.close()
    }

    private companion object {
        const val TAG = "EmotionChannel"
    }
}
