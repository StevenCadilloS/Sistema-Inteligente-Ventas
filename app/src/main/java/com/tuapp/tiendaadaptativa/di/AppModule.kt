package com.tuapp.tiendaadaptativa.di

///**
// * MÓDULO DE INYECCIÓN DE DEPENDENCIAS
// * Fase: Infraestructura (no es parte del pipeline, pero conecta todo)
// * Responsabilidad:
// * - Proveer instancias únicas de: AppDatabase, DAOs, Repositories,
// *   EmotionDetector, EmotionProcessor, AdaptationEngine, BanditOptimizer
// * - Evitar acoplamiento entre capas (cada clase no crea sus dependencias)
// * - Garantizar que solo haya una instancia de cada componente (Singleton)
// *
// * Opción A: Hilt (@Module @InstallIn) → recomendado para Android nativo
// * Opción B: Inyección manual → más simple, sin dependencias extra
// *
// * Flujo de dependencias:
// *   AppDatabase → UserDao, ProductDao, OfferDao, EmotionDao
// *   UserDao → UserRepository
// *   ProductDao + OfferDao → ProductRepository
// *   EmotionDetector + EmotionProcessor → AdaptationEngine
// *   BanditOptimizer → AdaptationEngine
// *   AdaptationEngine + ProductRepository → ProductDetailActivity
// */
class AppModule {
    // TODO: @Singleton @Provides fun provideDatabase(context: Context): AppDatabase
    //       -> Room.databaseBuilder(context, AppDatabase::class.java, "tienda.db")
    // TODO: @Singleton @Provides fun provideUserDao(db: AppDatabase): UserDao
    // TODO: @Singleton @Provides fun provideProductDao(db: AppDatabase): ProductDao
    // TODO: @Singleton @Provides fun provideOfferDao(db: AppDatabase): OfferDao
    // TODO: @Singleton @Provides fun provideEmotionDao(db: AppDatabase): EmotionDao
    // TODO: @Singleton @Provides fun provideUserRepository(userDao: UserDao): UserRepository
    // TODO: @Singleton @Provides fun provideProductRepository(
    //       productDao: ProductDao,
    //       offerDao: OfferDao
    //   ): ProductRepository
    // TODO: @Singleton @Provides fun provideEmotionDetector(context: Context): EmotionDetector
    //       -> Inicializa ML Kit + TFLite
    // TODO: @Singleton @Provides fun provideEmotionProcessor(): EmotionProcessor
    // TODO: @Singleton @Provides fun provideBanditOptimizer(): BanditOptimizer
    // TODO: @Singleton @Provides fun provideAdaptationEngine(
    //       bandit: BanditOptimizer,
    //       productRepository: ProductRepository
    //   ): AdaptationEngine
}
