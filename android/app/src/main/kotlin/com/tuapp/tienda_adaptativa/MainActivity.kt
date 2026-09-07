package com.tuapp.tienda_adaptativa

import com.tuapp.tienda_adaptativa.channel.EmotionChannelHandler
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

// FlutterFragmentActivity (no FlutterActivity): CameraManager necesita
// ComponentActivity para registerForActivityResult() al pedir el permiso
// de camara, y FlutterActivity extiende Activity puro, no ComponentActivity.
class MainActivity : FlutterFragmentActivity() {
    private val emotionChannelName = "com.tuapp.tienda_adaptativa/emotion"
    private var handler: EmotionChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        handler = EmotionChannelHandler(this)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, emotionChannelName)
            .setStreamHandler(handler)
    }

    override fun onDestroy() {
        handler?.dispose()
        super.onDestroy()
    }
}
