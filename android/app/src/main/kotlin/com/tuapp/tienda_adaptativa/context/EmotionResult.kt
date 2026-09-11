package com.tuapp.tienda_adaptativa.context

/** Resultado crudo del detector binario. */
data class EmotionResult(
    val response: String,
    val confidence: Float
) {
    init {
        require(response in SUPPORTED) {
            "Respuesta facial no soportada: $response"
        }
        require(confidence in 0f..1f) {
            "La confianza debe estar entre 0.0 y 1.0"
        }
    }

    // Alias conservado para no cambiar el contrato del canal en esta rama.
    val emotion: String get() = response

    companion object {
        const val FAVORABLE = "favorable"
        const val UNFAVORABLE = "desfavorable"
        const val UNCERTAIN = "incierto"
        const val NO_FACE = "no_face"

        private val SUPPORTED = setOf(
            FAVORABLE,
            UNFAVORABLE,
            UNCERTAIN,
            NO_FACE
        )

        fun noFace(): EmotionResult = EmotionResult(NO_FACE, 0f)

        fun uncertain(confidence: Float = 0f): EmotionResult =
            EmotionResult(UNCERTAIN, confidence.coerceIn(0f, 1f))
    }
}
