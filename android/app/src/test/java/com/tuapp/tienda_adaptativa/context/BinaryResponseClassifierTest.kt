package com.tuapp.tienda_adaptativa.context

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BinaryResponseClassifierTest {
    private val classifier = BinaryResponseClassifier()

    private fun classify(
        smile: Float?,
        width: Int = 140,
        height: Int = 140,
        pitch: Float = 0f,
        yaw: Float = 0f,
        roll: Float = 0f
    ) = classifier.classify(smile, width, height, pitch, yaw, roll)

    @Test
    fun `sonrisa clara es favorable`() {
        val result = classify(0.82f)

        assertEquals(EmotionResult.FAVORABLE, result.response)
        assertEquals(0.82f, result.confidence, 0.001f)
    }

    @Test
    fun `ausencia clara de sonrisa es desfavorable`() {
        val result = classify(0.18f)

        assertEquals(EmotionResult.UNFAVORABLE, result.response)
        assertEquals(0.82f, result.confidence, 0.001f)
    }

    @Test
    fun `zona intermedia no se fuerza a ninguna respuesta`() {
        assertEquals(EmotionResult.UNCERTAIN, classify(0.50f).response)
    }

    @Test
    fun `rostro pequeno produce lectura incierta`() {
        assertEquals(
            EmotionResult.UNCERTAIN,
            classify(smile = 0.95f, width = 80, height = 80).response
        )
    }

    @Test
    fun `rostro girado produce lectura incierta`() {
        assertEquals(
            EmotionResult.UNCERTAIN,
            classify(smile = 0.95f, yaw = 25f).response
        )
    }

    @Test
    fun `probabilidad ausente produce lectura incierta`() {
        val result = classify(null)

        assertEquals(EmotionResult.UNCERTAIN, result.response)
        assertTrue(result.confidence == 0f)
    }
}
