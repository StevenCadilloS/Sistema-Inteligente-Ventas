package com.tuapp.tienda_adaptativa.processing

import com.tuapp.tienda_adaptativa.context.EmotionResult
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class EmotionProcessorTest {
    private fun result(emotion: String, confidence: Float = 0.8f) =
        EmotionResult(emotion, confidence)

    @Test
    fun `confirma por mayoria ponderada y no exige frames identicos`() {
        val processor = EmotionProcessor(
            windowSize = 10,
            minimumSamples = 10,
            minimumConfidence = 0.55f,
            minimumWinnerShare = 0.70f,
            switchConfirmations = 3,
        )

        repeat(7) { processor.process(result(EmotionResult.HAPPY, 0.9f)) }
        repeat(2) { processor.process(result(EmotionResult.SAD, 0.6f)) }
        val stable = processor.process(result(EmotionResult.HAPPY, 0.9f))

        assertTrue(stable.isStable)
        assertTrue(stable.didChange)
        assertEquals(EmotionResult.HAPPY, stable.emotion)
    }

    @Test
    fun `ignora confianza baja y clases sin regla de negocio`() {
        val processor = EmotionProcessor(
            windowSize = 3,
            minimumSamples = 3,
            minimumConfidence = 0.55f,
            minimumWinnerShare = 0.70f,
            switchConfirmations = 2,
        )

        repeat(5) { processor.process(result(EmotionResult.SAD, 0.3f)) }
        repeat(5) { processor.process(result(EmotionResult.UNKNOWN, 0.99f)) }
        val state = processor.process(EmotionResult.noFace())

        assertFalse(state.isStable)
        assertFalse(state.didChange)
    }

    @Test
    fun `no cambia por una rafaga corta de otra emocion`() {
        val processor = EmotionProcessor(
            windowSize = 10,
            minimumSamples = 10,
            minimumConfidence = 0.55f,
            minimumWinnerShare = 0.70f,
            switchConfirmations = 3,
        )

        repeat(10) { processor.process(result(EmotionResult.HAPPY, 0.9f)) }
        repeat(4) {
            val state = processor.process(result(EmotionResult.SAD, 0.95f))
            assertEquals(EmotionResult.HAPPY, state.emotion)
            assertFalse(state.didChange)
        }
    }

    @Test
    fun `exige varias ventanas ganadoras para cambiar la emocion visible`() {
        val processor = EmotionProcessor(
            windowSize = 10,
            minimumSamples = 10,
            minimumConfidence = 0.55f,
            minimumWinnerShare = 0.70f,
            switchConfirmations = 3,
        )

        repeat(10) { processor.process(result(EmotionResult.HAPPY, 0.9f)) }

        var state: ProcessedEmotion? = null
        repeat(9) { state = processor.process(result(EmotionResult.SAD, 0.95f)) }

        assertEquals(EmotionResult.SAD, state?.emotion)
        assertTrue(state?.didChange == true)

        val repeated = processor.process(result(EmotionResult.SAD, 0.95f))
        assertEquals(EmotionResult.SAD, repeated.emotion)
        assertFalse(repeated.didChange)
    }
}
