package com.tuapp.tienda_adaptativa.processing

import com.tuapp.tienda_adaptativa.context.EmotionResult
import java.util.ArrayDeque

/**
 * PROCESAMIENTO - FILTRO DE ESTABILIDAD DE EMOCIONES
 * Fase 2 del pipeline adaptativo.
 *
 * Responsabilidades:
 * - Recibir emociones crudas provenientes de EmotionDetector.
 * - Mantener una ventana de N frames.
 * - Confirmar una emocion solo si se repite durante N frames consecutivos.
 * - Calcular la confianza promedio de la emocion estable.
 * - Conservar la ultima emocion estable mientras la lectura aun oscila.
 *
 * Flujo:
 * EmotionResult -> buffer de N frames -> ProcessedEmotion
 */
class EmotionProcessor(
    private val stabilityThreshold: Int = DEFAULT_STABILITY_THRESHOLD
) {

    private val buffer = ArrayDeque<EmotionResult>()

    private var currentStableEmotion: String = EmotionResult.NEUTRAL
    private var currentStableConfidence: Float = 0f

    init {
        require(stabilityThreshold > 0) {
            "El numero de frames para estabilizar debe ser mayor que cero."
        }
    }

    /**
     * Agrega una lectura cruda y determina si ya existe una emocion estable.
     *
     * `no_face` no se confirma como emocion. Cuando no hay rostro, se limpia
     * la ventana para evitar mezclar frames anteriores con una lectura nueva.
     */
    @Synchronized
    fun process(rawEmotion: EmotionResult): ProcessedEmotion {
        if (rawEmotion.emotion == EmotionResult.NO_FACE) {
            buffer.clear()
            return ProcessedEmotion(
                emotion = currentStableEmotion,
                confidence = 0f,
                isStable = false
            )
        }

        buffer.addLast(rawEmotion)

        while (buffer.size > stabilityThreshold) {
            buffer.removeFirst()
        }

        val stable = isStable()

        if (stable) {
            currentStableEmotion = rawEmotion.emotion
            currentStableConfidence = getAverageConfidence()
        }

        return ProcessedEmotion(
            emotion = currentStableEmotion,
            confidence = if (stable) {
                currentStableConfidence
            } else {
                currentStableConfidence.coerceIn(0f, 1f)
            },
            isStable = stable
        )
    }

    /**
     * Una lectura se considera estable solo cuando la ventana esta completa
     * y todos los frames contienen la misma emocion.
     */
    private fun isStable(): Boolean {
        if (buffer.size < stabilityThreshold) return false

        val firstEmotion = buffer.firstOrNull()?.emotion ?: return false
        return buffer.all { result -> result.emotion == firstEmotion }
    }

    /**
     * Confianza promedio de los frames presentes en la ventana.
     */
    private fun getAverageConfidence(): Float {
        if (buffer.isEmpty()) return 0f

        val sum = buffer.sumOf { result -> result.confidence.toDouble() }
        return (sum / buffer.size)
            .toFloat()
            .coerceIn(0f, 1f)
    }

    /**
     * Reinicia el filtro, por ejemplo al cambiar de pantalla o producto.
     */
    @Synchronized
    fun reset() {
        buffer.clear()
        currentStableEmotion = EmotionResult.NEUTRAL
        currentStableConfidence = 0f
    }

    companion object {
        const val DEFAULT_STABILITY_THRESHOLD = 10
    }
}

/**
 * Emocion procesada y estabilizada por la fase 2.
 */
data class ProcessedEmotion(
    val emotion: String,
    val confidence: Float,
    val isStable: Boolean
)
