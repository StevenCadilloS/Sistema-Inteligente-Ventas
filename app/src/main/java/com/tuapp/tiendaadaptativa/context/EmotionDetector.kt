package com.tuapp.tiendaadaptativa.context

///**
// * CAPTURA DE CONTEXTO - EMOCIONES FACIALES
// * Fase 1 del Pipeline: CONTEXTO
// * Responsabilidad:
// * - Recibir frames de CameraManager (imágenes en tiempo real)
// * - Usar Google ML Kit Face Detection para detectar rostros
// * - Extraer landmarks faciales (ojos, boca, cejas, nariz)
// * - Clasificar emoción usando modelo TFLite preentrenado (FER-2013)
// * - Devolver emoción detectada con nivel de confianza
// * - Emociones soportadas: triste, feliz, sorpresa, neutral, enojo
// *
// * Flujo:
// *   Frame → ML Kit (detectar cara) → TFLite (clasificar emoción) → EmotionResult
// */
class EmotionDetector {
    // TODO: fun detectEmotion(frame: ImageProxy): EmotionResult
    //       -> Recibe frame de la cámara
    //       -> Usa ML Kit para detectar si hay cara
    //       -> Si hay cara: extraebitmap → ejecuta TFLite → retorna emoción
    //       -> Si no hay cara: retorna "no_face" con confianza 0
    // TODO: private fun extractFaceFromFrame(frame: ImageProxy, face: Face): Bitmap
    //       -> Recorta solo la región de la cara del frame completo
    // TODO: private fun runTfliteModel(faceBitmap: Bitmap): EmotionResult
    //       -> Carga modelo FER-2013 desde assets
    //       -> Ejecutainferencia → retorna emoción + confianza
    // TODO: private val faceDetector: FaceDetector  // ML Kit
    // TODO: private val tfliteInterpreter: Interpreter  // TFLite
}

///**
// * Resultado de la detección de emoción
// */
data class EmotionResult(
    val emotion: String,    // "triste", "feliz", "sorpresa", "neutral", "enojo", "no_face"
    val confidence: Float   // 0.0 a 1.0
)
