package com.tuapp.tiendaadaptativa.ui

///**
// * PANTALLA PRINCIPAL - PRODUCTO + OFERTA ADAPTATIVA
// * Fase: UI (Frontend) + Integración del Pipeline completo
// * Responsabilidad:
// * - Mostrar producto actual con imagen, nombre, descripción y precio
// * - Activar cámara frontal en vivo (preview pequeño en esquina superior)
// * - Mostrar emoción detectada en tiempo real (badge con emoji + texto)
// * - Mostrar oferta adaptativa que CAMBIA según la emoción detectada
// * - Botones: "👍 Me interesa" / "👎 No gracias"
// * - Actualizar UI automáticamente cuando la emoción cambia
// * - Registrar cada interacción en EmotionHistory (qué ofreció, qué respondió)
// * - Navegar a HistoryActivity para ver historial
// *
// * Flujo visual:
// * ┌─────────────────────────────────────┐
// * │  📷 [cámara]    Emoción: 😞 triste │
// * ├─────────────────────────────────────┤
// * │  🎧 AUDÍFONOS BLUETOOTH            │
// * │  S/150                              │
// * ├─────────────────────────────────────┤
// * │  🎁 OFERTA PARA TI:                │
// * │  Mouse Gamer - S/45 (antes S/80)   │
// * │  "Tal vez esto te anime"            │
// * ├─────────────────────────────────────┤
// * │  [👍 Me interesa] [👎 No gracias]   │
// * └─────────────────────────────────────┘
// *
// * Flujo de ejecución:
// *   CameraManager → EmotionDetector → EmotionProcessor
// *        → AdaptationEngine → BanditOptimizer → UI se actualiza
// */
class ProductDetailActivity {
    // TODO: onCreate → verificar userId → init camera → start emotion detection
    // TODO: fun initCamera()
    //       -> Inicia CameraManager con lifecycle de esta activity
    // TODO: fun onEmotionDetected(emotion: ProcessedEmotion)
    //       -> Llama a AdaptationEngine.decide()
    //       -> Actualiza UI con nueva oferta
    // TODO: fun updateUI(result: AdaptationResult)
    //       -> Cambia badge de emoción (emoji + color)
    //       -> Cambia DynamicOfferCard con nueva oferta
    //       -> Aplica tema según emoción
    // TODO: fun handleAccept(offer: Offer)
    //       -> Registra en EmotionHistory: {emotion, offerId, accepted=true}
    //       -> Llama a BanditOptimizer.updateReward(offerId, emotion, true)
    //       -> Muestra siguiente producto
    // TODO: fun handleReject(offer: Offer)
    //       -> Registra en EmotionHistory: {emotion, offerId, accepted=false}
    //       -> Llama a BanditOptimizer.updateReward(offerId, emotion, false)
    //       -> Muestra siguiente oferta (puede ser otra para la misma emoción)
    // TODO: fun showNextProduct()
    //       -> Avanza al siguiente producto del catálogo
    //       -> Resetea el buffer de emoción
    // TODO: fun navigateToHistory()
    //       -> Intent a HistoryActivity con userId
}
