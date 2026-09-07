package com.tuapp.tiendaadaptativa.ui

///**
// * PANTALLA PRINCIPAL - REGISTRO / LOGIN
// * Fase: UI (Frontend)
// * Responsabilidad:
// * - Mostrar pantalla de bienvenida con logo de la tienda
// * - Formulario de registro: nombre + email
// * - Login simple: solo email (o con código si se complica)
// * - Guardar usuario en Room via UserRepository
// * - Navegar a ProductDetailActivity después del registro exitoso
// * - Verificar si ya hay sesión activa (splash screen automático)
// *
// * Flujo:
// *   App abre → ¿Hay usuario en BD? → SÍ → ProductDetailActivity
// *                                  → NO → Mostrar formulario registro
// *                                  → Registrar → ProductDetailActivity
// */
class MainActivity {
    // TODO: onCreate → verificar sesión activa → mostrar login o redirigir
    // TODO: fun setupRegisterForm()
    //       -> Valida que nombre y email no estén vacíos
    //       -> Valida formato de email
    // TODO: fun handleRegister(name: String, email: String)
    //       -> Llama a UserRepository.register()
    //       -> Si éxito: guarda userId en SharedPreferences → navega
    //       -> Si error: muestra mensaje
    // TODO: fun navigateToProductDetail(userId: Int)
    //       -> Intent a ProductDetailActivity con userId
}
