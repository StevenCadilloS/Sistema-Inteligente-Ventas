package com.tuapp.tienda_adaptativa.context

import kotlin.math.abs

/**
 * Regla pura y comprobable que convierte la salida facial de ML Kit en una
 * respuesta de negocio. No fuerza las observaciones ambiguas a una clase.
 */
class BinaryResponseClassifier(
    private val favorableThreshold: Float = FAVORABLE_THRESHOLD,
    private val unfavorableThreshold: Float = UNFAVORABLE_THRESHOLD,
    private val minFacePixels: Int = MIN_FACE_PIXELS
) {
    init {
        require(unfavorableThreshold < favorableThreshold)
        require(minFacePixels > 0)
    }

    fun classify(
        smileProbability: Float?,
        faceWidth: Int,
        faceHeight: Int,
        pitchDegrees: Float,
        yawDegrees: Float,
        rollDegrees: Float
    ): EmotionResult {
        val smile = smileProbability?.coerceIn(0f, 1f)

        if (faceWidth < minFacePixels || faceHeight < minFacePixels) {
            return EmotionResult.uncertain(
                smileProbability = smile,
                status = EmotionResult.STATUS_FACE_TOO_SMALL
            )
        }

        if (
            abs(pitchDegrees) > MAX_PITCH_DEGREES ||
            abs(yawDegrees) > MAX_YAW_DEGREES ||
            abs(rollDegrees) > MAX_ROLL_DEGREES
        ) {
            return EmotionResult.uncertain(
                smileProbability = smile,
                status = EmotionResult.STATUS_BAD_ANGLE
            )
        }

        if (smile == null) {
            return EmotionResult.uncertain(
                status = EmotionResult.STATUS_NO_SMILE_PROBABILITY
            )
        }
        return when {
            smile >= favorableThreshold -> EmotionResult(
                response = EmotionResult.FAVORABLE,
                confidence = smile,
                smileProbability = smile
            )
            smile <= unfavorableThreshold -> EmotionResult(
                response = EmotionResult.UNFAVORABLE,
                confidence = 1f - smile,
                smileProbability = smile
            )
            else -> EmotionResult.uncertain(
                confidence = maxOf(smile, 1f - smile),
                smileProbability = smile,
                status = EmotionResult.STATUS_AMBIGUOUS
            )
        }
    }

    companion object {
        const val MIN_FACE_PIXELS = 96
        const val MAX_PITCH_DEGREES = 20f
        const val MAX_YAW_DEGREES = 18f
        const val MAX_ROLL_DEGREES = 18f
        const val FAVORABLE_THRESHOLD = 0.65f
        const val UNFAVORABLE_THRESHOLD = 0.35f
    }
}
