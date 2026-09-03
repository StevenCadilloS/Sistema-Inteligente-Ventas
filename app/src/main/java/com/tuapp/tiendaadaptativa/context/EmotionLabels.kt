package com.tuapp.tiendaadaptativa.context

/**
 * Etiquetas oficiales que circulan por el pipeline adaptativo.
 *
 * Se centralizan para evitar strings repetidos e inconsistencias entre
 * contexto, procesamiento, decisión y persistencia.
 */
object EmotionLabels {
    const val SAD = "triste"
    const val HAPPY = "feliz"
    const val SURPRISE = "sorpresa"
    const val NEUTRAL = "neutral"
    const val ANGRY = "enojo"
    const val NO_FACE = "no_face"

    val supported: Set<String> = setOf(
        SAD,
        HAPPY,
        SURPRISE,
        NEUTRAL,
        ANGRY,
        NO_FACE
    )
}
