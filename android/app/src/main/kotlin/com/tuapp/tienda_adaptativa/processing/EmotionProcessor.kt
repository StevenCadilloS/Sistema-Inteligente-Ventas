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
    private var framesSinRostro: Int = 0

    init {
        require(stabilityThreshold > 0) {
            "El numero de frames para estabilizar debe ser mayor que cero."
        }
    }

    /**
     * Agrega una lectura cruda y determina si ya existe una emocion estable.
     *
     * `no_face` no se confirma como emocion. La ventana se limpia solo tras
     * [MAX_FRAMES_SIN_ROSTRO] lecturas seguidas sin rostro (la persona se
     * fue de verdad): con la camara real, ML Kit pierde el rostro un frame
     * suelto cada ~1s por movimiento o desenfoque, y limpiar en cada uno
     * reiniciaba la ventana antes de completar los frames necesarios — la
     * emocion no llegaba a estabilizarse nunca.
     */
    @Synchronized
    fun process(rawEmotion: EmotionResult): ProcessedEmotion {
        if (rawEmotion.emotion == EmotionResult.NO_FACE) {
            framesSinRostro++
            // Flanco: solo el frame exacto en que se confirma la perdida, para
            // avisar una vez a la UI en vez de en cada frame sin rostro.
            val acabaDePerderElRostro = framesSinRostro == MAX_FRAMES_SIN_ROSTRO
            if (acabaDePerderElRostro) {
                // Solo se descarta la ventana. La emocion vigente se conserva
                // a proposito: a la UI ya se le avisa con `rostroPerdido`, y
                // reiniciarla a neutral fabricaba transiciones falsas cada vez
                // que el rostro salia un instante de cuadro (medido: 143 de
                // ~430 frames sin rostro en 20s de uso normal).
                buffer.clear()
            }
            return ProcessedEmotion(
                emotion = EmotionResult.NO_FACE,
                confidence = 0f,
                isStable = false,
                rostroPerdido = acabaDePerderElRostro
            )
        }

        framesSinRostro = 0
        buffer.addLast(rawEmotion)

        while (buffer.size > stabilityThreshold) {
            buffer.removeFirst()
        }

        if (buffer.size < stabilityThreshold) {
            return ProcessedEmotion(
                emotion = currentStableEmotion,
                confidence = currentStableConfidence,
                isStable = false
            )
        }

        // Voto por mayoria en vez de exigir la ventana entera identica: el
        // clasificador alterna entre dos clases frame a frame (medido: 48% /
        // 42% sobre la misma cara quieta), asi que pedir unanimidad no daba
        // estabilidad — daba saltos cada vez que se alineaba una racha corta.
        val votos = buffer.groupingBy { it.emotion }.eachCount()
        val ganadora = votos.maxByOrNull { it.value } ?: return ProcessedEmotion(
            emotion = currentStableEmotion,
            confidence = currentStableConfidence,
            isStable = false
        )
        val proporcion = ganadora.value.toFloat() / buffer.size

        if (proporcion < MAYORIA_MINIMA) {
            // Ninguna clase manda con claridad: se conserva la anterior en
            // vez de parpadear entre dos.
            return ProcessedEmotion(
                emotion = currentStableEmotion,
                confidence = currentStableConfidence,
                isStable = false
            )
        }

        // Histeresis: para desplazar a la emocion vigente no basta con ganar,
        // hay que ganarle por un margen. Sin esto, dos clases empatadas se
        // turnaban el primer puesto y la emocion cambiaba ~1 vez por segundo
        // (medido: 16 cambios en 20s con el usuario quieto).
        val votosVigente = votos[currentStableEmotion] ?: 0
        val esOtraEmocion = ganadora.key != currentStableEmotion
        if (esOtraEmocion && ganadora.value < votosVigente + MARGEN_PARA_CAMBIAR) {
            return ProcessedEmotion(
                emotion = currentStableEmotion,
                confidence = currentStableConfidence,
                isStable = false
            )
        }

        currentStableEmotion = ganadora.key
        currentStableConfidence = buffer
            .filter { it.emotion == ganadora.key }
            .map { it.confidence }
            .average()
            .toFloat()
            .coerceIn(0f, 1f)

        return ProcessedEmotion(
            emotion = currentStableEmotion,
            confidence = currentStableConfidence,
            isStable = true
        )
    }

    /**
     * Reinicia el filtro, por ejemplo al cambiar de pantalla o producto.
     */
    @Synchronized
    fun reset() {
        buffer.clear()
        currentStableEmotion = EmotionResult.NEUTRAL
        currentStableConfidence = 0f
        framesSinRostro = 0
    }

    companion object {
        /**
         * Tamano de la ventana de votacion. A ~20 fps reales en dispositivo,
         * 20 frames son ~1s: filtra el ruido del clasificador sin que la app
         * se sienta lenta.
         */
        const val DEFAULT_STABILITY_THRESHOLD = 26

        /**
         * Cuantos votos de ventaja necesita una emocion nueva para desplazar
         * a la vigente. Evita el ida y vuelta entre dos clases empatadas.
         */
        const val MARGEN_PARA_CAMBIAR = 6

        /**
         * Fraccion de la ventana que una emocion debe ganar para confirmarse.
         * 0.45 y no mas alto porque medido en dispositivo la clase correcta
         * gana con ~54% de los frames (el resto se reparte entre 4 clases, y
         * el azar seria 20%): con 0.6 no se confirmaba ninguna emocion nunca.
         */
        const val MAYORIA_MINIMA = 0.45f

        const val MAX_FRAMES_SIN_ROSTRO = 5
    }
}

/**
 * Emocion procesada y estabilizada por la fase 2.
 */
data class ProcessedEmotion(
    val emotion: String,
    val confidence: Float,
    val isStable: Boolean,
    /** Solo true en el frame que confirma que el rostro se fue. */
    val rostroPerdido: Boolean = false
)
