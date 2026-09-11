package com.tuapp.tienda_adaptativa.channel

import android.content.Context
import android.view.View
import androidx.camera.core.Preview
import androidx.camera.view.PreviewView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** Crea la vista CameraX que Flutter incrusta en el modo de diagnostico. */
class EmotionCameraPreviewFactory(
    private val handler: EmotionChannelHandler
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return EmotionCameraPreview(context, handler)
    }
}

private class EmotionCameraPreview(
    context: Context,
    private val handler: EmotionChannelHandler
) : PlatformView {
    private val previewView = PreviewView(context).apply {
        scaleType = PreviewView.ScaleType.FILL_CENTER
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
    }
    private val surfaceProvider: Preview.SurfaceProvider = previewView.surfaceProvider

    init {
        handler.attachPreview(surfaceProvider)
    }

    override fun getView(): View = previewView

    override fun dispose() {
        handler.detachPreview(surfaceProvider)
    }
}
