package com.tuapp.tiendaadaptativa.decision

///**
// * MOTOR DE DECISIÓN - REGLAS DE ADAPTACIÓN
// * Fase 3 del Pipeline: DECISIÓN
// * Responsabilidad:
// * - Recibir emoción procesada del EmotionProcessor
// * - Aplicar reglas de negocio para seleccionar la oferta adaptativa
// * - Consultar BanditOptimizer para priorizar entre ofertas similares
// * - Devolver la Offer que se mostrará al usuario
// *
// * Reglas principales:
// * ┌─────────────────┬──────────────────────────────────────────┐
// * │ Emoción         │ Adaptación                               │
// * ├─────────────────┼──────────────────────────────────────────┤
// * │ triste          │ Producto Sustituto más económico         │
// * │ enojo/disgusto  │ Cambiar categoría + oferta con descuento │
// * │ sorpresa        │ Descuento Especial o Combo               │
// * │ felicidad       │ Oferta Premium (sin descuento)           │
// * │ neutral         │ Oferta estándar del catálogo             │
// * └─────────────────┴──────────────────────────────────────────┘
// *
// * Cada decisión genera un "reason" que se guarda en el historial
// */
class AdaptationEngine(private val banditOptimizer: BanditOptimizer) {
    // TODO: fun decide(emotion: ProcessedEmotion, userId: Int): AdaptationResult
    //       -> Recibe emoción procesada y ID del usuario
    //       -> Aplica reglas según emoción
    //       -> Consulta BanditOptimizer para desempatar entre ofertas candidatas
    //       -> Retorna AdaptationResult con oferta seleccionada y razón
    // TODO: private fun getOffersByEmotion(emotion: String): List<Offer>
    //       -> Filtra ofertas que targets la emoción detectada
    // TODO: private fun applySubstituteRule(offers: List<Offer>): Offer
    //       -> Para triste: selecciona producto más económico
    // TODO: private fun applyDiscountRule(offers: List<Offer>): Offer
    //       -> Para sorpresa: selecciona mayor descuento disponible
    // TODO: private fun applyPremiumRule(offers: List<Offer>): Offer
    //       -> Para felicidad: selecciona producto premium (sin descuento)
    // TODO: private fun applyNeutralRule(offers: List<Offer>): Offer
    //       -> Para neutral: oferta estándar con prioridad más alta
}

///**
// * Resultado de la decisión de adaptación
// */
data class AdaptationResult(
    val offer: Offer,           // Oferta seleccionada para mostrar
    val reason: String,         // Razón de la decisión (para historial y UI)
    val emotionDetected: String // Emoción que provocó esta decisión
)
