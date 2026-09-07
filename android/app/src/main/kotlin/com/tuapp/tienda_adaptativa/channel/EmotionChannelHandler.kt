package com.tuapp.tienda_adaptativa.channel

import io.flutter.embedding.android.FlutterFragmentActivity
import com.tuapp.tienda_adaptativa.context.CameraManager
import com.tuapp.tienda_adaptativa.context.EmotionDetector
import com.tuapp.tienda_adaptativa.processing.EmotionProcessor
import io.flutter.plugin.common.EventChannel

class EmotionChannelHandler(
    private val activity: FlutterFragmentActivity
) : EventChannel.StreamHandler {

    private val cameraManager = CameraManager(activity)
    private val emotionDetector = EmotionDetector(activity)
    private val emotionProcessor = EmotionProcessor()

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        cameraManager.startCamera { frame ->
            emotionDetector.detectEmotion(
                frame,
                onResult = { crudo ->
                    val procesado = emotionProcessor.process(crudo)
                    if (procesado.isStable) {
                        events?.success(
                            mapOf(
                                "emotion" to procesado.emotion,
                                "confidence" to procesado.confidence,
                            )
                        )
                    }
                },
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
}
