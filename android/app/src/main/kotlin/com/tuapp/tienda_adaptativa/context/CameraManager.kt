package com.tuapp.tienda_adaptativa.context

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

    // Se avisa a quien pidio la camara de que no va a haber frames, para que
    // no se quede esperando indefinidamente una lectura que nunca llega.
    private var onUnavailable: ((String) -> Unit)? = null

    // El launcher se registra en el bloque init, que corre al construir el
    // CameraManager. registerForActivityResult() tiene que llamarse ANTES de
    // que la Activity llegue a STARTED: si llega tarde, Android deja el
    // launcher inservible y launch() no hace nada — el dialogo de permiso no
    // aparece nunca y la camara no arranca, sin ningun error visible.
    private val permissionLauncher = activity.registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            onFrameCaptured?.let { bindCameraUseCases() }
        } else {
            // Rechazo explicito: la tienda sigue funcionando a precio normal.
            onUnavailable?.invoke("permiso_denegado")
        }
    }

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
    fun startCamera(
        onFrameCaptured: (ImageProxy) -> Unit,
        onUnavailable: ((String) -> Unit)? = null,
    ) {
        this.onFrameCaptured = onFrameCaptured
        this.onUnavailable = onUnavailable

        if (!hasPermission()) {
            // El dialogo es asincrono: la camara arranca en el callback del
            // launcher, no aqui.
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
        // getInstance() devuelve un future que tarda en resolverse la primera
        // vez. Antes se esperaba con .get(), que bloquea el hilo principal:
        // en un equipo lento eso congela la UI mientras arranca la camara, y
        // si el future fallaba la excepcion subia sin capturar. Ahora se
        // espera por callback, en el hilo principal pero sin bloquearlo.
        val future = ProcessCameraProvider.getInstance(activity)
        future.addListener({
            try {
                bindProvider(future.get())
            } catch (error: Exception) {
                error.printStackTrace()
                onUnavailable?.invoke("camara_no_disponible")
            }
        }, ContextCompat.getMainExecutor(activity))
    }

    private fun bindProvider(provider: ProcessCameraProvider) {
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
            // Camara ocupada por otra app, o sin camara frontal: la tienda
            // sigue, pero sin negociacion.
            error.printStackTrace()
            onUnavailable?.invoke("camara_no_disponible")
        }
    }

}
