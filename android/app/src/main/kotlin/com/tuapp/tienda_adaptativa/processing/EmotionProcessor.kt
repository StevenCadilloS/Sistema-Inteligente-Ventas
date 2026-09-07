package com.tuapp.tienda_adaptativa.processing

import com.tuapp.tienda_adaptativa.context.EmotionResult
import java.util.ArrayDeque

/**
 * Estabiliza las predicciones del modelo antes de enviarlas a Flutter.
 *
 * El modelo puede alternar de clase entre frames aun cuando el gesto no haya
 * cambiado. Por eso se usa una ventana deslizante con voto ponderado por
 * confianza, en vez de confirmar una etiqueta por pocos frames consecutivos.
 */
class EmotionProcessor(
    private val windowSize: Int = DEFAULT_WINDOW_SIZE,
    private val minimumSamples: Int = DEFAULT_MINIMUM_SAMPLES,
    private val minimumConfidence: Float = DEFAULT_MINIMUM_CONFIDENCE,
    private val minimumWinnerShare: Float = DEFAULT_MINIMUM_WINNER_SHARE,
    private val switchConfirmations: Int = DEFAULT_SWITCH_CONFIRMATIONS,
) {
    private val buffer = ArrayDeque<EmotionResult>()

    private var currentStableEmotion: String = EmotionResult.NEUTRAL
    private var currentStableConfidence: Float = 0f
    private var hasStableEmotion = false
    private var pendingEmotion: String? = null
    private var pendingConfirmations = 0
    private var framesWithoutUsefulReading = 0

    init {
        require(windowSize > 0)
        require(minimumSamples in 1..windowSize)
        require(minimumConfidence in 0f..1f)
        require(minimumWinnerShare in 0.5f..1f)
        require(switchConfirmations > 0)
    }

    @Synchronized
    fun process(rawEmotion: EmotionResult): ProcessedEmotion {
        if (!isUseful(rawEmotion)) {
            framesWithoutUsefulReading++
            if (framesWithoutUsefulReading >= MAX_FRAMES_WITHOUT_USEFUL_READING) {
                buffer.clear()
                clearPendingCandidate()
            }
            return currentResult(didChange = false)
        }

        framesWithoutUsefulReading = 0
        buffer.addLast(rawEmotion)
        while (buffer.size > windowSize) buffer.removeFirst()

        val winner = findWinner() ?: return currentResult(didChange = false)

        // La primera lectura estable se puede publicar inmediatamente una vez
        // que la ventana tenga evidencia suficiente.
        if (!hasStableEmotion) {
            accept(winner)
            return currentResult(didChange = true)
        }

        // Si la ventana sigue apoyando el estado actual, sólo refrescamos su
        // confianza y cancelamos cualquier transición incompleta.
        if (winner.emotion == currentStableEmotion) {
            currentStableConfidence = winner.averageConfidence
            clearPendingCandidate()
            return currentResult(didChange = false)
        }

        // Histéresis: una emoción rival debe ganar varias ventanas seguidas
        // antes de reemplazar a la que ya está visible.
        if (pendingEmotion == winner.emotion) {
            pendingConfirmations++
        } else {
            pendingEmotion = winner.emotion
            pendingConfirmations = 1
        }

        if (pendingConfirmations < switchConfirmations) {
            return currentResult(didChange = false)
        }

        accept(winner)
        return currentResult(didChange = true)
    }

    private fun isUseful(result: EmotionResult): Boolean =
        result.emotion != EmotionResult.NO_FACE &&
            result.emotion != EmotionResult.UNKNOWN &&
            result.confidence >= minimumConfidence

    private fun findWinner(): Winner? {
        if (buffer.size < minimumSamples) return null

        val scores = mutableMapOf<String, Float>()
        val counts = mutableMapOf<String, Int>()
        var totalScore = 0f

        buffer.forEach { result ->
            scores[result.emotion] = (scores[result.emotion] ?: 0f) + result.confidence
            counts[result.emotion] = (counts[result.emotion] ?: 0) + 1
            totalScore += result.confidence
        }

        val winnerEntry = scores.maxByOrNull { it.value } ?: return null
        val winnerCount = counts.getValue(winnerEntry.key)
        val winnerShare = if (totalScore > 0f) winnerEntry.value / totalScore else 0f
        val averageConfidence = winnerEntry.value / winnerCount

        if (winnerShare < minimumWinnerShare) return null
        if (averageConfidence < minimumConfidence) return null

        return Winner(winnerEntry.key, averageConfidence.coerceIn(0f, 1f))
    }

    private fun accept(winner: Winner) {
        currentStableEmotion = winner.emotion
        currentStableConfidence = winner.averageConfidence
        hasStableEmotion = true
        clearPendingCandidate()
    }

    private fun currentResult(didChange: Boolean) = ProcessedEmotion(
        emotion = currentStableEmotion,
        confidence = currentStableConfidence,
        isStable = hasStableEmotion,
        didChange = didChange,
    )

    private fun clearPendingCandidate() {
        pendingEmotion = null
        pendingConfirmations = 0
    }

    @Synchronized
    fun reset() {
        buffer.clear()
        currentStableEmotion = EmotionResult.NEUTRAL
        currentStableConfidence = 0f
        hasStableEmotion = false
        framesWithoutUsefulReading = 0
        clearPendingCandidate()
    }

    private data class Winner(
        val emotion: String,
        val averageConfidence: Float,
    )

    companion object {
        // Ventana corta con histeresis: reacciona pronto a un gesto sostenido,
        // pero una prediccion aislada no cambia la interfaz.
        const val DEFAULT_WINDOW_SIZE = 7
        const val DEFAULT_MINIMUM_SAMPLES = 4
        const val DEFAULT_MINIMUM_CONFIDENCE = 0.55f
        const val DEFAULT_MINIMUM_WINNER_SHARE = 0.62f
        const val DEFAULT_SWITCH_CONFIRMATIONS = 2
        const val MAX_FRAMES_WITHOUT_USEFUL_READING = 8
    }
}

data class ProcessedEmotion(
    val emotion: String,
    val confidence: Float,
    val isStable: Boolean,
    val didChange: Boolean,
)
