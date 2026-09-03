package com.tuapp.tiendaadaptativa.data.database.dao

///**
// * DAO - HISTORIAL DE EMOCIONES
// * Fase: Persistencia (data)
// * Responsabilidad:
// * - Registrar cada detección de emoción (con timestamp)
// * - Obtener historial de emociones de un usuario
// * - Obtener emociones recientes (últimas N)
// * - Contar emociones por tipo (para estadísticas)
// * - Calcular tasa de aceptación por emoción + oferta
// */
interface EmotionDao {
    // TODO: @Insert suspend fun insert(emotion: EmotionHistory)
    // TODO: @Query("SELECT * FROM emotion_history WHERE userId = :userId ORDER BY timestamp DESC")
    //       suspend fun getByUser(userId: Int): List<EmotionHistory>
    // TODO: @Query("SELECT * FROM emotion_history ORDER BY timestamp DESC LIMIT :limit")
    //       suspend fun getRecent(limit: Int): List<EmotionHistory>
    // TODO: @Query("SELECT emotion, COUNT(*) as count FROM emotion_history WHERE userId = :userId GROUP BY emotion")
    //       suspend fun countByEmotion(userId: Int): List<EmotionCount>
    // TODO: @Query("SELECT * FROM emotion_history WHERE userId = :userId AND emotion = :emotion AND accepted IS NOT NULL")
    //       suspend fun getAcceptedByEmotion(userId: Int, emotion: String): List<EmotionHistory>
    // TODO: @Update suspend fun update(emotion: EmotionHistory)
}
