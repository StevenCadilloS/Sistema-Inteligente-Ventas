package com.tuapp.tienda_adaptativa.processing

import com.tuapp.tienda_adaptativa.context.EmotionResult
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Fase 2 del pipeline. Es logica pura, asi que corre en la JVM sin emulador:
 *   ./gradlew :app:testDebugUnitTest
 *
 * Cada caso fija un comportamiento que ya se rompio en dispositivo. La
 * estabilizacion no tiene otra red: cuando fallo, la app quedo inutilizable
 * sin ningun error visible, y solo se detecto leyendo logcat.
 */
class EmotionProcessorTest {

    private val umbral = EmotionProcessor.DEFAULT_STABILITY_THRESHOLD

    private fun feliz(confianza: Float = 0.9f) =
        EmotionResult(EmotionResult.HAPPY, confianza)

    private fun triste(confianza: Float = 0.9f) =
        EmotionResult(EmotionResult.SAD, confianza)

    private fun sinRostro() = EmotionResult.noFace()

    /** Alimenta [veces] lecturas y devuelve la ultima salida. */
    private fun EmotionProcessor.alimentar(
        lectura: EmotionResult,
        veces: Int
    ): ProcessedEmotion {
        var ultima = process(lectura)
        repeat(veces - 1) { ultima = process(lectura) }
        return ultima
    }

    @Test
    fun `no confirma nada antes de llenar la ventana`() {
        val processor = EmotionProcessor()

        val resultado = processor.alimentar(feliz(), umbral - 1)

        assertFalse(resultado.isStable)
    }

    @Test
    fun `confirma la emocion cuando domina la ventana`() {
        val processor = EmotionProcessor()

        val resultado = processor.alimentar(feliz(), umbral)

        assertTrue(resultado.isStable)
        assertEquals(EmotionResult.HAPPY, resultado.emotion)
    }

    /**
     * El bug que dejo la app muerta: ML Kit pierde el rostro un frame suelto
     * cada ~1s, y limpiar la ventana en cada uno la reiniciaba antes de
     * completarse. La emocion no se estabilizaba nunca.
     */
    @Test
    fun `un frame suelto sin rostro no descarta la ventana`() {
        val processor = EmotionProcessor()

        processor.alimentar(feliz(), umbral - 1)
        processor.process(sinRostro()) // parpadeo de ML Kit
        val resultado = processor.process(feliz())

        assertTrue(resultado.isStable)
        assertEquals(EmotionResult.HAPPY, resultado.emotion)
    }

    @Test
    fun `perder el rostro de verdad se avisa una sola vez`() {
        val processor = EmotionProcessor()
        processor.alimentar(feliz(), umbral)

        val avisos = (1..EmotionProcessor.MAX_FRAMES_SIN_ROSTRO * 2).count {
            processor.process(sinRostro()).rostroPerdido
        }

        // Si avisara en cada frame, la UI recibiria una rafaga de eventos.
        assertEquals(1, avisos)
    }

    @Test
    fun `sin rostro se reporta no_face y no una emocion estable`() {
        val processor = EmotionProcessor()
        processor.alimentar(feliz(), umbral)

        val resultado = processor.process(sinRostro())

        assertEquals(EmotionResult.NO_FACE, resultado.emotion)
        assertFalse(resultado.isStable)
    }

    /**
     * Histeresis: el clasificador alterna entre dos clases frame a frame
     * (medido: 48%/42% sobre la misma cara quieta). Sin margen, la emocion
     * cambiaba ~1 vez por segundo.
     */
    @Test
    fun `una emocion nueva sin ventaja clara no desplaza a la vigente`() {
        val processor = EmotionProcessor()
        processor.alimentar(feliz(), umbral)

        // Empate practico: la mitad de la ventana pasa a triste.
        val resultado = processor.alimentar(triste(), umbral / 2)

        assertEquals(EmotionResult.HAPPY, resultado.emotion)
    }

    @Test
    fun `una emocion sostenida si desplaza a la vigente`() {
        val processor = EmotionProcessor()
        processor.alimentar(feliz(), umbral)

        val resultado = processor.alimentar(triste(), umbral)

        assertTrue(resultado.isStable)
        assertEquals(EmotionResult.SAD, resultado.emotion)
    }

    @Test
    fun `la confianza reportada promedia solo los frames de la emocion ganadora`() {
        val processor = EmotionProcessor()

        val resultado = processor.alimentar(feliz(confianza = 0.8f), umbral)

        assertEquals(0.8f, resultado.confidence, 0.01f)
    }

    @Test
    fun `reset deja el filtro como recien creado`() {
        val processor = EmotionProcessor()
        processor.alimentar(feliz(), umbral)

        processor.reset()
        val resultado = processor.process(feliz())

        assertFalse(resultado.isStable)
    }
}
