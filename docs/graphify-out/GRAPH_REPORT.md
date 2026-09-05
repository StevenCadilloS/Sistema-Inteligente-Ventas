# Graph Report - docs  (2026-09-05)

## Corpus Check
- 39 files · ~0 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 278 nodes · 342 edges · 83 communities (16 shown, 44 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 34 edges (avg confidence: 0.84)
- Token cost: 9,500 input · 6,200 output

## Community Hubs (Navigation)
- Esquema Corregido y KPIs de Ventas
- Capa de Datos y DI (planeada)
- Pipeline de Decision y Adaptacion
- Deteccion Facial y Clasificacion TFLite
- Diseno Externo y Modulos UI
- Proceso Batch y Correccion de KPIs
- Modelos de Datos y Bandit (planeados)
- Captura de Camara (CameraX)
- Temas de Color por Emocion
- Estadisticas de Historial
- Reglas de Oferta por Emocion (planeadas)
- Autenticacion de Usuario (planeada)
- Vista Normalizada 1NF (G8/C10)
- Catalogo Maestra-Gestos (G2/C2)
- Catalogo Maestra-Tipo-Transaccion (G4/C4)
- Unificacion de Nombres FK (N1-N4/C7-C8)
- Ofertas Activas (planeado)
- Productos por Categoria (planeado)
- Catalogo de Productos (planeado)
- Producto por ID (planeado)
- Login de Usuario (planeado)
- Usuario por ID (planeado)
- Regla Sorpresa - Descuento (planeada)
- Regla Neutral - Oferta Estandar (planeada)
- Regla Felicidad - Premium (planeada)
- Regla Tristeza - Sustituto (planeada)
- Pantalla de Registro/Login (planeada)
- FKs Nullable sin Centinela (G9/C11)
- Context Readme
- Emotiondao Getacceptedbyemotion
- Emotiondao Getbyuser
- Emotiondao Getrecent
- Emotiondao Insert
- Emotiondao Update
- Offerdao Getbycategory
- Offerdao Update
- Productdao Getbypricerange
- Productrepository Getofferbyid
- Banditoptimizer Getstats
- Banditoptimizer Reset
- Appmodule Provideadaptationengine
- Appmodule Providebanditoptimizer
- Appmodule Providedatabase
- Appmodule Provideemotiondao
- Appmodule Provideemotiondetector
- Appmodule Provideemotionprocessor
- Appmodule Provideofferdao
- Appmodule Provideproductdao
- Appmodule Provideproductrepository
- Appmodule Provideuserdao
- Appmodule Provideuserrepository
- Processing Readme
- Dynamicoffercard Animatedcardtransition
- Dynamicoffercard Emotionbadge
- Dynamicoffercard Offertypebadge
- Dynamicoffercard Pricetag
- Historyactivity Formattimestamp
- Historyactivity Setuprecyclerview
- Mainactivity Setupregisterform
- Productdetailactivity Shownextproduct

## God Nodes (most connected - your core abstractions)
1. `Entregable - Monografía - Cierre de Ventas (Documento)` - 17 edges
2. `Maestra - Productos` - 16 edges
3. `Bitácora - Interacciones` - 15 edges
4. `Bitácora - Ventas` - 15 edges
5. `Maestra - Clientes` - 14 edges
6. `Módulo Batch` - 14 edges
7. `AppModule` - 13 edges
8. `Maestra - Estrategias` - 11 edges
9. `Bitácora - Detalle Venta` - 11 edges
10. `CameraManager` - 10 edges

## Surprising Connections (you probably didn't know these)
- `Módulo Online – Entregable Final (PDF)` --semantically_similar_to--> `Maestra - Productos`  [EXTRACTED] [semantically similar]
  Cierre de Ventas - Módulo Online - Entregable final.pdf → graphify-out/converted/Cierre de Ventas - Módulo Online_ae77b07b.md
- `Monografía Final – Sistema Cierre de Ventas` --semantically_similar_to--> `Módulo Batch`  [EXTRACTED] [semantically similar]
  Cierre de Ventas - Monografía - Entrega Final.pdf → graphify-out/converted/Cierre de ventas - Módulo Batch - Entregable Final_2bf098dc.md
- `Batch: Actualización Maestra Clientes (cierres/entradas)` --conceptually_related_to--> `Módulo Batch`  [INFERRED]
  Cierre de Ventas - Monografía - Entrega Final.pdf → graphify-out/converted/Cierre de ventas - Módulo Batch - Entregable Final_2bf098dc.md
- `Batch: Actualización Maestra Estrategias (aplicaciones/ventas)` --conceptually_related_to--> `Módulo Batch`  [INFERRED]
  Cierre de Ventas - Monografía - Entrega Final.pdf → graphify-out/converted/Cierre de ventas - Módulo Batch - Entregable Final_2bf098dc.md
- `Batch: Consulta Crítica de Ventas por Tipo Producto` --shares_data_with--> `Maestra - Productos`  [EXTRACTED]
  Diagrama Batch - Consulta crítica.png → graphify-out/converted/Cierre de Ventas - Módulo Online_ae77b07b.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Diseño Físico con Cálculo de Capacidad (IC/AC/N)** — converted_cierre_de_ventas_modulo_online_ae77b07b_maestra_productos, converted_cierre_de_ventas_modulo_online_ae77b07b_maestra_clientes, converted_cierre_de_ventas_modulo_online_ae77b07b_maestra_estrategias, converted_cierre_de_ventas_modulo_online_ae77b07b_bitacora_interacciones, converted_cierre_de_ventas_modulo_online_ae77b07b_bitacora_ventas, converted_cierre_de_ventas_modulo_online_ae77b07b_bitacora_detalle_venta, converted_modulo_online_cierre_de_ventas_d96ebae3_consulta_critica_tipo_producto [INFERRED 0.80]
- **Flujo de Datos del Protocolo de Venta Online** — converted_cierre_de_ventas_modulo_online_ae77b07b_bitacora_interacciones, converted_cierre_de_ventas_modulo_online_ae77b07b_bitacora_ventas, converted_cierre_de_ventas_modulo_online_ae77b07b_bitacora_detalle_venta, converted_cierre_de_ventas_modulo_online_ae77b07b_protocolo_venta, converted_cierre_de_ventas_modulo_online_ae77b07b_modulo_online [INFERRED 0.75]
- **Módulo Batch: Actualización y Reporte de KPIs** — converted_cierre_de_ventas_modulo_batch_entregable_final_2bf098dc_modulo_batch, converted_cierre_de_ventas_modulo_batch_entregable_final_2bf098dc_actualizacion_tablas_maestras, converted_cierre_de_ventas_modulo_batch_entregable_final_2bf098dc_kpi_cierre_ventas_mes, converted_cierre_de_ventas_modulo_batch_entregable_final_2bf098dc_kpi_ventas_sin_producto_alternativo, converted_cierre_de_ventas_modulo_batch_entregable_final_2bf098dc_kpi_efectividad_estrategia [INFERRED 0.80]
- **Unificación de id_proceso_persuasion entre interacciones y ventas** — docs_esquema_corregido_g1_id_proceso_persuasion, docs_esquema_corregido_c1_id_proceso_persuasion, converted_cierre_de_ventas_modulo_online_ae77b07b_bitacora_ventas, converted_cierre_de_ventas_modulo_online_ae77b07b_bitacora_interacciones [EXTRACTED 1.00]
- **Mecanismo de actualización batch de atributos derivados (BatchDao/WorkManager)** — docs_modelo_android_room_atributos_derivados_batch_vs_vistas, docs_modelo_android_room_batch_dao_workmanager, converted_cierre_de_ventas_modulo_online_ae77b07b_maestra_clientes, converted_cierre_de_ventas_modulo_online_ae77b07b_maestra_productos, converted_cierre_de_ventas_modulo_online_ae77b07b_maestra_estrategias [INFERRED 0.85]
- **Corrección 1NF de la consulta crítica: grupo repetitivo reemplazado por vista** — docs_esquema_corregido_g8_grupo_repetitivo_1nf, docs_esquema_corregido_c10_vista_normalizada, docs_modelo_android_room_consulta_critica_vista, converted_cierre_de_ventas_modulo_online_ae77b07b_bitacora_detalle_venta [EXTRACTED 1.00]
- **AppModule conecta Database, DAOs, Repositories y componentes del pipeline (DI planeada)** — app_src_main_java_com_tuapp_tiendaadaptativa_di_appmodule_appmodule, app_src_main_java_com_tuapp_tiendaadaptativa_data_database_appdatabase_appdatabase, app_src_main_java_com_tuapp_tiendaadaptativa_data_database_dao_userdao_userdao, app_src_main_java_com_tuapp_tiendaadaptativa_data_database_dao_productdao_productdao, app_src_main_java_com_tuapp_tiendaadaptativa_data_database_dao_offerdao_offerdao, app_src_main_java_com_tuapp_tiendaadaptativa_data_database_dao_emotiondao_emotiondao, app_src_main_java_com_tuapp_tiendaadaptativa_data_repositories_userrepository_userrepository, app_src_main_java_com_tuapp_tiendaadaptativa_data_repositories_productrepository_productrepository, app_src_main_java_com_tuapp_tiendaadaptativa_context_emotiondetector_emotiondetector, app_src_main_java_com_tuapp_tiendaadaptativa_processing_emotionprocessor_emotionprocessor, app_src_main_java_com_tuapp_tiendaadaptativa_decision_learning_banditoptimizer_banditoptimizer, app_src_main_java_com_tuapp_tiendaadaptativa_decision_adaptationengine_adaptationengine [EXTRACTED 1.00]
- **Pipeline CONTEXTO -> PROCESAMIENTO -> DECISION -> ADAPTACION** — app_src_main_java_com_tuapp_tiendaadaptativa_context_cameramanager_cameramanager, app_src_main_java_com_tuapp_tiendaadaptativa_context_emotiondetector_emotiondetector, app_src_main_java_com_tuapp_tiendaadaptativa_processing_emotionprocessor_emotionprocessor, app_src_main_java_com_tuapp_tiendaadaptativa_decision_adaptationengine_adaptationengine, app_src_main_java_com_tuapp_tiendaadaptativa_decision_learning_banditoptimizer_banditoptimizer, app_src_main_java_com_tuapp_tiendaadaptativa_ui_productdetailactivity_productdetailactivity [EXTRACTED 1.00]
- **Tabla de reglas de adaptacion por emocion en AdaptationEngine** — app_src_main_java_com_tuapp_tiendaadaptativa_decision_adaptationengine_regla_triste, app_src_main_java_com_tuapp_tiendaadaptativa_decision_adaptationengine_regla_sorpresa, app_src_main_java_com_tuapp_tiendaadaptativa_decision_adaptationengine_regla_felicidad, app_src_main_java_com_tuapp_tiendaadaptativa_decision_adaptationengine_regla_neutral, app_src_main_java_com_tuapp_tiendaadaptativa_decision_adaptationengine_regla_enojo, app_src_main_java_com_tuapp_tiendaadaptativa_decision_adaptationengine_decide [EXTRACTED 1.00]
- **Pipeline Batch: Actualización de Maestras y Cálculo de KPI** — batch_actualizacion_maestra_clientes, batch_actualizacion_maestra_estrategias, kpi_efectividad_estrategia_segmento [INFERRED 0.75]
- **Módulo Online: Seguridad + Gerencial + Tienda** — modulo_seguridad_reconocimiento_facial, modulo_gerencial_mantenimiento_parametros, tienda_web_online_cierre_ventas [INFERRED 0.75]

## Communities (83 total, 44 thin omitted)

### Community 0 - "Esquema Corregido y KPIs de Ventas"
Cohesion: 0.13
Nodes (38): Bitácora - Detalle Venta, Bitácora - Interacciones, Bitácora - Ventas, Cierre de Ventas - Módulo Online (Documento), Maestra - Clientes, Maestra - Estrategias, Maestra - Productos, Módulo Online (+30 more)

### Community 1 - "Capa de Datos y DI (planeada)"
Cohesion: 0.09
Nodes (17): AppDatabase.emotionDao() [planned], AppDatabase.offerDao() [planned], AppDatabase.productDao() [planned], AppDatabase.userDao() [planned], EmotionDao, OfferDao, ProductDao, UserDao (+9 more)

### Community 2 - "Pipeline de Decision y Adaptacion"
Cohesion: 0.10
Nodes (15): EmotionDetector.detectEmotion(), EmotionResult, AdaptationResult, AdaptationEngine.decide() [planned], Regla: enojo/disgusto -> cambiar categoria + descuento, BanditOptimizer.calculateUCB1() [planned], BanditOptimizer.selectOffer() [planned], UCB1 (Upper Confidence Bound) algorithm (+7 more)

### Community 3 - "Deteccion Facial y Clasificacion TFLite"
Cohesion: 0.19
Nodes (11): EmotionDetector, ImageProxy, TfliteClassifier, Bitmap, ByteBuffer, Closeable, Context, Face (+3 more)

### Community 4 - "Diseno Externo y Modulos UI"
Cohesion: 0.18
Nodes (18): Arquitectura del Sistema de Cierre de Ventas, Batch: Actualización Maestra Clientes (cierres/entradas), Batch: Actualización Maestra Estrategias (aplicaciones/ventas), Cierre de Ventas – Diseño Externo, Módulo Online – Entregable Final (PDF), Monografía Final – Sistema Cierre de Ventas, Primer KPI: Efectividad de Estrategia, Segundo KPI: Ventas por Día (Propuesta 1) (+10 more)

### Community 5 - "Proceso Batch y Correccion de KPIs"
Cohesion: 0.15
Nodes (18): Batch: Consulta Crítica de Ventas por Tipo Producto, Actualización de Maestra de Clientes, Actualización de Maestra de Estrategias, Actualización de Tablas Maestras (Proceso Batch), Cierre de ventas - Módulo Batch - Entregable Final (Documento), KPI: Porcentaje de Cierre de Ventas x Mes, KPI: Porcentaje de Efectividad por Estrategia, KPI: Porcentaje de Ventas sin Productos Alternativos (+10 more)

### Community 6 - "Modelos de Datos y Bandit (planeados)"
Cohesion: 0.24
Nodes (10): AppDatabase, EmotionHistory, Offer, Product, User, OfferStats, BanditOptimizer.updateReward() [planned], DynamicOfferCard.OfferCard() [planned] (+2 more)

### Community 7 - "Captura de Camara (CameraX)"
Cohesion: 0.27
Nodes (4): CameraManager, ImageProxy, ProductDetailActivity.initCamera() [planned], ProcessCameraProvider

### Community 8 - "Temas de Color por Emocion"
Cohesion: 0.33
Nodes (6): DynamicOfferCard.getEmotionColor() [planned], AdaptiveTheme.getColorScheme() [planned], AdaptiveTheme.happyTheme [planned], AdaptiveTheme.neutralTheme [planned], AdaptiveTheme.sadTheme [planned], AdaptiveTheme.surprisedTheme [planned]

### Community 9 - "Estadisticas de Historial"
Cohesion: 0.67
Nodes (3): EmotionDao.countByEmotion() [planned], EmotionCount (concept), HistoryActivity.showStats() [planned]

### Community 10 - "Reglas de Oferta por Emocion (planeadas)"
Cohesion: 0.67
Nodes (3): OfferDao.getByEmotion() [planned], ProductRepository.getOffersForEmotion() [planned], AdaptationEngine.getOffersByEmotion() [planned]

### Community 11 - "Autenticacion de Usuario (planeada)"
Cohesion: 0.67
Nodes (3): UserDao.insert() [planned], UserRepository.register() [planned], MainActivity.handleRegister() [planned]

### Community 12 - "Vista Normalizada 1NF (G8/C10)"
Cohesion: 1.00
Nodes (3): C10 — reemplazar grupo repetitivo por vista normalizada, G8 — tabla consulta viola 1NF (grupo repetitivo ventas 1-99), v_cierres_por_tipo_producto — @DatabaseView reemplazando el grupo repetitivo (C10/G8)

### Community 13 - "Catalogo Maestra-Gestos (G2/C2)"
Cohesion: 0.67
Nodes (3): C2 — nueva tabla MAESTRA-GESTOS, G2 — cod_gesto FK sin tabla maestra, MAESTRA-GESTOS (cod_gesto PK, nombre_gesto, descripcion)

### Community 14 - "Catalogo Maestra-Tipo-Transaccion (G4/C4)"
Cohesion: 0.67
Nodes (3): C4 — nueva tabla MAESTRA-TIPO-TRANSACCION, G4 — tipo_transaccion sin catálogo, MAESTRA-TIPO-TRANSACCION (cod_transaccion PK, tipo_trx, cod_protocolo, estado)

### Community 15 - "Unificacion de Nombres FK (N1-N4/C7-C8)"
Cohesion: 0.67
Nodes (3): C7 — unificar canal_venta→canal y cod_producto→cod_lote_producto, C8 — nombre único BITACORA_INTERACCIONES, N1-N4 — inconsistencias de nomenclatura (canal/canal_venta, cod_producto/cod_lote_producto, cant_lecturas/cant_entradas)

## Ambiguous Edges - Review These
- `AdaptationEngine.decide() [planned]` → `Regla: enojo/disgusto -> cambiar categoria + descuento`  [AMBIGUOUS]
  app/src/main/java/com/tuapp/tiendaadaptativa/decision/AdaptationEngine.kt · relation: rationale_for

## Knowledge Gaps
- **86 isolated node(s):** `MainActivity`, `Arquitectura`, `Modelo Externo`, `KPI: Porcentaje de Ventas por Día de la Semana`, `G9 — valores centinela 00000000 en columnas FK` (+81 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 129 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **44 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `AdaptationEngine.decide() [planned]` and `Regla: enojo/disgusto -> cambiar categoria + descuento`?**
  _Edge tagged AMBIGUOUS (relation: rationale_for) - confidence is low._
- **Why does `AppModule` connect `Capa de Datos y DI (planeada)` to `Pipeline de Decision y Adaptacion`, `Deteccion Facial y Clasificacion TFLite`, `Modelos de Datos y Bandit (planeados)`?**
  _High betweenness centrality (0.068) - this node is a cross-community bridge._
- **Why does `EmotionDetector` connect `Deteccion Facial y Clasificacion TFLite` to `Capa de Datos y DI (planeada)`?**
  _High betweenness centrality (0.036) - this node is a cross-community bridge._
- **Why does `EmotionResult` connect `Pipeline de Decision y Adaptacion` to `Capa de Datos y DI (planeada)`, `Deteccion Facial y Clasificacion TFLite`?**
  _High betweenness centrality (0.033) - this node is a cross-community bridge._
- **What connects `MainActivity`, `Arquitectura`, `Modelo Externo` to the rest of the system?**
  _86 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Esquema Corregido y KPIs de Ventas` be split into smaller, more focused modules?**
  _Cohesion score 0.13086770981507823 - nodes in this community are weakly interconnected._
- **Should `Capa de Datos y DI (planeada)` be split into smaller, more focused modules?**
  _Cohesion score 0.08923076923076922 - nodes in this community are weakly interconnected._