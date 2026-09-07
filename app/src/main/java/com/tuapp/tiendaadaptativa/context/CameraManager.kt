package com.tuapp.tiendaadaptativa.context

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.util.Size
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner

///**
// * CAPTURA DE CONTEXTO - CÁMARA
// * Fase 1 del Pipeline: CONTEXTO
// *
// * Responsabilidades:
// * - Verificar y solicitar permisos de cámara en runtime
// * - Inicializar CameraX con la cámara frontal (selfie)
// * - Configurar ImageAnalysis para procesar frames en tiempo real
// * - Entregar cada frame mediante un callback (onFrameCaptured)
// * - Liberar recursos al detener la cámara
// *
// * Flujo:
// *   CameraManager → ImageProxy → EmotionDetector → EmotionProcessor
// *
// * Uso:
// *   val cameraManager = CameraManager(this)
// *   cameraManager.startCamera { frame ->
// *       emotionDetector.detectEmotion(frame, onResult = { ... })
// *   }
// */
class CameraManager(
    private val activity: ComponentActivity
) {

    private var cameraProvider: ProcessCameraProvider? = null
    private val analyzerExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()

    // Callback que se ejecuta cuando se obtiene un frame
    private var onFrameCaptured: ((ImageProxy) -> Unit)? = null

    ///**
    // * Verifica si la app tiene permiso de cámara concedido.
    // */
    fun hasPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    ///**
    // * Solicita permiso de cámara al usuario.
    // * Si se concede, inicia la cámara automáticamente.
    // */
    fun requestPermission() {
        permissionLauncher.launch(Manifest.permission.CAMERA)
    }

    ///**
    // * Inicia la cámara frontal y comienza a entregar frames.
    // *
    // * @param onFrameCaptured Callback que recibe cada frame procesado por CameraX.
    // *                        El caller es responsable de cerrar el ImageProxy
    // *                        después de procesarlo.
    // */
    fun startCamera(onFrameCaptured: (ImageProxy) -> Unit) {
        this.onFrameCaptured = onFrameCaptured

        if (!hasPermission()) {
            requestPermission()
            return
        }

        bindCameraUseCases()
    }

    ///**
    // * Detiene la cámara y libera recursos.
    // */
    fun stopCamera() {
        cameraProvider?.unbindAll()
        cameraProvider = null
    }

    ///**
    // * Libera el executor de análisis.
    // * Llamar cuando la Activity se destruye.
    // */
    fun release() {
        stopCamera()
        analyzerExecutor.shutdown()
    }

    ///**
    // * Vincula los casos de uso de CameraX:
    // * - ImageAnalysis: para procesar frames en tiempo real
    // *
    // * La cámara frontal es la seleccionada por defecto (selfie).
    // * Se usa STRATEGY_KEEP_ONLY_LATEST para evitar buffering innecesario.
    // */
    private fun bindCameraUseCases() {
        val provider = ProcessCameraProvider.getInstance(activity).get()
        cameraProvider = provider

        val imageAnalysis = ImageAnalysis.Builder()
            .setTargetResolution(Size(640, 480))
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()

        imageAnalysis.setAnalyzer(analyzerExecutor) { imageProxy ->
            onFrameCaptured?.invoke(imageProxy)
        }

        val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

        try {
            provider.unbindAll()
            provider.bindToLifecycle(
                activity as LifecycleOwner,
                cameraSelector,
                imageAnalysis
            )
        } catch (error: Exception) {
            error.printStackTrace()
        }
    }

    ///**
    // * Launcher para solicitar permisos de cámara en runtime.
    // * Se registra en init para cumplir con el ciclo de vida de ActivityResult.
    // */
    private val permissionLauncher = activity.registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            // Permiso concedido: iniciar cámara con el callback previamente configurado
            onFrameCaptured?.let { bindCameraUseCases() }
        }
    }
}
