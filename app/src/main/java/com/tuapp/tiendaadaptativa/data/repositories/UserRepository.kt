package com.tuapp.tiendaadaptativa.data.repositories

///**
// * REPOSITORY - USUARIO
// * Fase: Persistencia (data)
// * Responsabilidad:
// * - Intermediario entre la UI (registro/login) y el UserDao
// * - Validar datos antes de insertar (email no vacío, formato válido)
// * - Manejar errores de base de datos
// * - Proveer usuario actual para el pipeline adaptativo
// */
class UserRepository(private val userDao: UserDao) {
    // TODO: suspend fun register(name: String, email: String): Result<User>
    //       -> Valida que el email no esté registrado
    //       -> Inserta el usuario y retorna el usuario creado
    // TODO: suspend fun login(email: String): Result<User?>
    //       -> Busca usuario por email
    //       -> Retorna null si no existe
    // TODO: suspend fun getById(id: Int): User?
    //       -> Obtiene usuario por ID (para el pipeline)
}
