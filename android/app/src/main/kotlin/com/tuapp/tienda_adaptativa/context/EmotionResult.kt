package com.tuapp.tienda_adaptativa.context

/** Resultado crudo del detector binario. */
data class EmotionResult(
    val response: String,
    val confidence: Float,
    /** Probabilidad cruda de sonrisa entregada por ML Kit, si existe. */
    val smileProbability: Float? = null,
    /** Motivo tecnico de la lectura, usado por la pantalla de calibracion. */
    val status: String = STATUS_OK
) {
    init {
        require(response in SUPPORTED) {
            "Respuesta facial no soportada: $response"
        }
        require(confidence in 0f..1f) {
            "La confianza debe estar entre 0.0 y 1.0"
        }
        require(smileProbability == null || smileProbability in 0f..1f) {
            "La probabilidad de sonrisa debe estar entre 0.0 y 1.0"
        }
        require(status in SUPPORTED_STATUSES) {
            "Estado de lectura no soportado: $status"
        }
    }

    // Alias conservado para no cambiar el contrato del canal en esta rama.
    val emotion: String get() = response

    companion object {
        const val FAVORABLE = "favorable"
        const val UNFAVORABLE = "desfavorable"
        const val UNCERTAIN = "incierto"
        const val NO_FACE = "no_face"

        const val STATUS_OK = "ok"
        const val STATUS_NO_FACE = "no_face"
        const val STATUS_FACE_TOO_SMALL = "face_too_small"
        const val STATUS_BAD_ANGLE = "bad_angle"
        const val STATUS_NO_SMILE_PROBABILITY = "no_smile_probability"
        const val STATUS_AMBIGUOUS = "ambiguous"

        private val SUPPORTED = setOf(
            FAVORABLE,
            UNFAVORABLE,
            UNCERTAIN,
            NO_FACE
        )

        private val SUPPORTED_STATUSES = setOf(
            STATUS_OK,
            STATUS_NO_FACE,
            STATUS_FACE_TOO_SMALL,
            STATUS_BAD_ANGLE,
            STATUS_NO_SMILE_PROBABILITY,
            STATUS_AMBIGUOUS
        )

        fun noFace(): EmotionResult = EmotionResult(
            response = NO_FACE,
            confidence = 0f,
            status = STATUS_NO_FACE
        )

        fun uncertain(
            confidence: Float = 0f,
            smileProbability: Float? = null,
            status: String = STATUS_AMBIGUOUS
        ): EmotionResult = EmotionResult(
            response = UNCERTAIN,
            confidence = confidence.coerceIn(0f, 1f),
            smileProbability = smileProbability?.coerceIn(0f, 1f),
            status = status
        )
    }
}
