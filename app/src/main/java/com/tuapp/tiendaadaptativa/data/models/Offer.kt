package com.tuapp.tiendaadaptativa.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey

///**
// * MODELO - OFERTA
// * Fase: Persistencia (data) + Decisión (decision)
// * Responsabilidad:
// * - Representar una oferta adaptativa que se muestra al usuario
// * - Contener: producto ofrecido, tipo de adaptación, emoción objetivo
// * - Tipos de oferta: "descuento", "combo", "sustituto", "premium"
// * - Se usa para que el motor de decisión seleccione la oferta correcta
// */
@Entity(tableName = "offers")
data class Offer(
    // TODO: @PrimaryKey(autoGenerate = true) val id: Int = 0,
    // TODO: val productId: Int,           // FK → Product (producto que se ofrece)
    // TODO: val type: String,             // "discount", "combo", "substitute", "premium"
    // TODO: val targetEmotion: String,    // "triste", "feliz", "sorpresa", "neutral", "all"
    // TODO: val discountPercent: Double = 0.0,
    // TODO: val comboDescription: String = "",  // Descripción si es combo
    // TODO: val description: String,      // Texto que se muestra al usuario
    // TODO: val priority: Int = 0,        // Prioridad inicial para el Bandit
    // TODO: val active: Boolean = true    // Si está activa o no
)
