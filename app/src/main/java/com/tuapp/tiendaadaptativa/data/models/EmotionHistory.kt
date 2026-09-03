package com.tuapp.tiendaadaptativa.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey

///**
// * MODELO - HISTORIAL DE EMOCIONES
// * Fase: Persistencia (data)
// * Responsabilidad:
// * - Registrar cada evento de detección de emoción
// * - Guardar: qué emoción se detectó, qué oferta se mostró, si aceptó o rechazó
// * - Se usa para el aprendizaje del Multi-Armed Bandit
// * - Permite estadísticas: emoción más común, tasa de aceptación por emoción
// */
@Entity(tableName = "emotion_history")
data class EmotionHistory(
    // TODO: @PrimaryKey(autoGenerate = true) val id: Int = 0,
    // TODO: val userId: Int,              // FK → User
    // TODO: val emotion: String,          // "triste", "feliz", "sorpresa", "neutral", "enojo"
    // TODO: val offerId: Int?,            // FK → Offer (qué oferta se mostró, null si no se ofreció nada)
    // TODO: val accepted: Boolean?,       // true = aceptó, false = rechazó, null = aún no responde
    // TODO: val confidence: Float = 0f,   // Confianza de la detección (0.0 a 1.0)
    // TODO: val timestamp: Long = System.currentTimeMillis()
)
