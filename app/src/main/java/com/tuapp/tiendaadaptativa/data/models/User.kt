package com.tuapp.tiendaadaptativa.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey

///**
// * MODELO - USUARIO
// * Fase: Persistencia (data)
// * Responsabilidad:
// * - Representar al usuario registrado en la app
// * - Almacenar datos básicos: nombre, email, fecha de registro
// * - Se usa en la pantalla de registro/login
// */
@Entity(tableName = "users")
data class User(
    // TODO: @PrimaryKey(autoGenerate = true) val id: Int = 0,
    // TODO: val name: String,
    // TODO: val email: String,
    // TODO: val createdAt: Long = System.currentTimeMillis()
)
