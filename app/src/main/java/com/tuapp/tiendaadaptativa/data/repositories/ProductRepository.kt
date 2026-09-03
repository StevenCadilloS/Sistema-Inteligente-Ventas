package com.tuapp.tiendaadaptativa.data.repositories

///**
// * REPOSITORY - PRODUCTOS Y OFERTAS
// * Fase: Persistencia (data)
// * Responsabilidad:
// * - Intermediario entre la lógica de decisión y los DAOs
// * - Buscar productos por categoría, precio o ID
// * - Obtener ofertas filtradas por emoción
// * - Obtener ofertas para una categoría específica
// * - Se usa en AdaptationEngine para seleccionar la oferta adaptativa
// */
class ProductRepository(
    private val productDao: ProductDao,
    private val offerDao: OfferDao
) {
    // TODO: suspend fun getAllProducts(): List<Product>
    //       -> Retorna todo el catálogo
    // TODO: suspend fun getProductsByCategory(category: String): List<Product>
    //       -> Filtra productos por categoría
    // TODO: suspend fun getProductById(id: Int): Product?
    //       -> Busca un producto específico
    // TODO: suspend fun getOffersForEmotion(emotion: String): List<Offer>
    //       -> Retorna ofertas que targets esa emoción + "all"
    // TODO: suspend fun getActiveOffers(): List<Offer>
    //       -> Solo ofertas activas
    // TODO: suspend fun getOfferById(id: Int): Offer?
    //       -> Busca una oferta específica por ID
}
