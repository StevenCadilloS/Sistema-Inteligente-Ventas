package com.tuapp.tiendaadaptativa.context

///**
// * CAPTURA DE CONTEXTO - CÁMARA
// * Fase 1 del Pipeline: CONTEXTO
// * Responsabilidad:
// * - Solicitar y gestionar permisos de cámara en runtime
// * - Inicializar CameraX con la cámara frontal (selfie)
// * - Configurar ImageAnalysis para procesar frames en tiempo real
// * - Enviar cada frame capturado a EmotionDetector
// * - Manejar ciclo de vida de la cámara (onPause/onResume)
// * - Controlar resolución y frame rate según batería disponible
// */
class CameraManager {
    // TODO: fun startCamera(context: Context, lifecycleOwner: LifecycleOwner, onFrameCaptured: (ImageProxy) -> Unit)
    //       -> Inicializa CameraX
    //       -> Configura analyzer con ImageAnalysis
    //       -> Usa cámara frontal (CameraSelector.DEFAULT_FRONT_CAMERA)
    //       -> Ejecuta onFrameCaptured por cada frame procesado
    // TODO: fun stopCamera()
    //       -> Detiene la cámara y libera recursos
    // TODO: fun hasPermission(context: Context): Boolean
    //       -> Verifica si tiene permiso de cámara (Manifest.permission.CAMERA)
    // TODO: fun requestPermission(activity: Activity)
    //       -> Solicita permiso de cámara al usuario en runtime
    //       -> Usa ActivityResultContracts
}
