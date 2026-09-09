# Tienda Adaptativa — Requisitos, Alcances y Limitaciones

**Taller 1 · Desarrollo de una Aplicación Adaptativa · UNI FIIS · 2026**
Equipo: Elvis Arboleda (base de datos, motor de reglas, autenticación) · Juan Medina
(modelo de emociones) · Steven Cadillo (frontend e integración con la cámara)

---

## 1. Objetivos

### 1.1 Objetivo general

Construir una aplicación móvil Android que **adapte su oferta comercial en tiempo real
según la expresión facial del cliente**, sin que este emita ninguna orden explícita,
demostrando el pipeline adaptativo *contexto → procesamiento → decisión → adaptación*
del curso.

### 1.2 Objetivos específicos

| ID | Objetivo | Verificable en |
|---|---|---|
| OE-01 | Capturar la expresión facial del cliente desde la cámara frontal, en segundo plano y sin previsualización | `CameraManager.kt`, `EmotionDetector.kt` |
| OE-02 | Estabilizar la señal ruidosa del clasificador para que la adaptación no oscile frame a frame | `EmotionProcessor.kt` |
| OE-03 | Reordenar el catálogo y calcular descuentos automáticamente a partir de la emoción estable | `adaptation_engine.dart` |
| OE-04 | Aprender qué estrategia comercial convierte mejor y redistribuir oportunidades en consecuencia | `bandit_optimizer.dart` (UCB1) |
| OE-05 | Registrar cada oferta junto a la emoción que la disparó, de modo que la adaptación sea auditable | Tabla `interacciones` (PostgreSQL) |
| OE-06 | Procesar el rostro íntegramente en el dispositivo: ninguna imagen sale del teléfono, solo la etiqueta de emoción | `CameraManager.kt`, `EmotionProcessor.kt` |
| OE-07 | Mantener catálogo, stock y ofertas en una base compartida, de modo que lo que publica el administrador llegue a todos los usuarios sin refrescar | `supabase/migrations/`, `SupabaseTiendaRepository` |
| OE-08 | Permitir que una persona administre la tienda (altas de producto, ofertas con vigencia, reposición de stock) sin tocar el código ni recompilar | Panel de Supabase, tabla `ofertas` |

### 1.3 Requisito eliminatorio del taller

> **La oferta debe cambiar sola, sin intervención manual del usuario.**

Se cumple porque el disparador de la adaptación es el cambio de emoción estable, no un
botón. Está fijado por prueba automatizada.

---

## 2. Alcances

### 2.1 Dentro del alcance

| ID | Alcance |
|---|---|
| AL-01 | Aplicación Android nativa-híbrida (Flutter + módulo Kotlin), `minSdk` 26 (Android 8.0+) |
| AL-02 | Reconocimiento de **5 emociones**: `triste`, `feliz`, `sorpresa`, `neutral`, `enojo` |
| AL-03 | Catálogo de productos administrable, con reordenamiento adaptativo por emoción en el dispositivo |
| AL-04 | Negociación acotada de hasta 3 peldaños (precio de lista → contraoferta con descuento → bien sustituto) |
| AL-05 | Registro de clientes (nombre + apellido) con código asignado por el servidor, y sesión persistida en el dispositivo |
| AL-06 | Persistencia completa: catálogos, maestras y bitácoras (12 tablas con claves foráneas activas), más las vistas de los 4 KPIs |
| AL-07 | Aprendizaje en vivo por Multi-Armed Bandit (UCB1) sobre 4 estrategias comerciales |
| AL-08 | Módulo batch de cierre diario: 6 procesos derivados en una única transacción |
| AL-09 | Pantalla de historial con estadísticas de interacciones y compras del cliente |
| AL-10 | Suite de pruebas automatizadas: 39 casos Dart (`flutter_test`), 4 suites SQL sobre PostgreSQL real y 9 casos JUnit (JVM) |
| AL-11 | Base de datos compartida en PostgreSQL: 12 tablas, integridad referencial, políticas de acceso por rol y escrituras atómicas por funciones del servidor |
| AL-12 | Administración desde el panel de Supabase: alta de productos, ofertas con vigencia y reposición de stock, sin recompilar la app |
| AL-13 | Propagación en tiempo real (WebSocket) de cambios de catálogo, stock y ofertas a todos los dispositivos conectados |
| AL-14 | Proyecto de código abierto (licencia MIT) y backend autohospedable, sin dependencia de ningún servicio propietario |

### 2.2 Fuera del alcance

| ID | Exclusión | Motivo |
|---|---|---|
| FA-01 | Pantalla de administración dentro de la app Android | El administrador opera desde el panel web de Supabase, que ya ofrece tablas, filtros y edición; duplicarlo en Flutter no agregaba nada |
| FA-02 | Pasarela de pago o transacción financiera real | La venta se registra en la base y descuenta stock; no se cobra dinero |
| FA-03 | Versión iOS, web o escritorio | El pipeline depende de CameraX/ML Kit/TFLite en Android |
| FA-04 | Funcionamiento sin conexión | Decisión explícita, alineada con el dominio: ninguna tienda en línea real (Temu, Shein, Mercado Libre) opera sin conexión, porque el precio y el stock que muestra deben ser los vigentes. Una copia local del catálogo solo puede estar desactualizada: mostraría un producto agotado o un precio que ya cambió. Una sola fuente de verdad elimina esa clase de error y los conflictos de sincronización, a costa de exigir red |
| FA-05 | Entrenamiento o reentrenamiento del modelo de emociones | Se consume un modelo FER-2013 preentrenado |
| FA-06 | Orientación horizontal de pantalla | En horizontal el rostro sale del encuadre; sin rostro no hay contexto |
| FA-07 | Identificación biométrica o almacenamiento de imágenes del rostro | Solo se persiste la etiqueta de emoción, nunca el frame |

---

## 3. Requisitos funcionales

### 3.1 Contexto — captura (Kotlin nativo)

| ID | Requisito |
|---|---|
| RF-01 | El sistema debe capturar frames de la cámara **frontal** de forma continua mediante CameraX (`ImageAnalysis`) |
| RF-02 | El sistema debe localizar el rostro en cada frame usando ML Kit Face Detection |
| RF-03 | El sistema debe clasificar la expresión facial en una de las 5 emociones mediante TensorFlow Lite (entrada 48×48 px) |
| RF-04 | El sistema debe emitir, junto a cada emoción, un **nivel de interés** de 0 a 100 derivado de la confianza del clasificador |
| RF-05 | La captura debe operar **sin previsualización visible**: el cliente navega el catálogo, no posa para una foto |
| RF-06 | El sistema debe solicitar el permiso `CAMERA` en tiempo de ejecución antes de iniciar la captura |

### 3.2 Procesamiento — estabilización

| ID | Requisito |
|---|---|
| RF-07 | El sistema debe acumular una ventana deslizante de 26 frames antes de declarar una emoción como estable |
| RF-08 | El sistema debe resolver la emoción estable por **voto de mayoría** con umbral del 45% de la ventana |
| RF-09 | El sistema debe aplicar **histéresis**: una emoción vigente solo es reemplazada si la candidata supera el umbral, evitando oscilación |
| RF-10 | El sistema debe publicar la emoción estable hacia la capa Flutter mediante un `EventChannel` de flujo continuo |

### 3.3 Decisión — reglas de adaptación

| ID | Requisito |
|---|---|
| RF-11 | El sistema debe reordenar el catálogo aplicando la regla correspondiente a la emoción estable vigente |
| RF-12 | El sistema debe asignar a cada emoción un porcentaje de descuento según la tabla de reglas |
| RF-13 | El reordenamiento debe ejecutarse **automáticamente** al cambiar la emoción, sin acción del usuario |
| RF-14 | El sistema debe seleccionar la estrategia comercial aplicada mediante el algoritmo UCB1 |
| RF-15 | Toda estrategia nunca aplicada debe priorizarse automáticamente, forzando su exploración antes de explotar la mejor |

**Tabla de reglas por emoción** (implementada en `AdaptationEngine`):

| Emoción | Orden del catálogo | Descuento |
|---|---|---|
| `triste` | Precio ascendente (sustituto económico) | 10% |
| `feliz` | Precio descendente (premium) | 0% |
| `sorpresa` | Menos mostrado (novedad) | 15% |
| `neutral` | Más mostrado (estándar) | 0% |
| `enojo` | Otra categoría, la más económica | 25% |

**Fórmula UCB1:** `score = (éxitos / intentos) + √(2 × ln(N) / intentos)`

### 3.4 Adaptación — negociación e interfaz

| ID | Requisito |
|---|---|
| RF-16 | Al tocar un producto, el sistema debe ofrecerlo primero **a precio de lista** |
| RF-17 | Ante un rechazo, el sistema debe presentar una contraoferta del mismo producto con el descuento que determina la emoción vigente |
| RF-18 | Ante un segundo rechazo, el sistema debe proponer un **bien sustituto**: misma categoría, precio menor |
| RF-19 | Ante el rechazo del sustituto, el sistema debe **dejar de insistir** y vetar ese producto hasta que cambie la expresión |
| RF-20 | La negociación debe avanzar en un solo sentido: el peldaño nunca retrocede y la tienda queda bloqueada durante el proceso |
| RF-21 | La interfaz debe mostrar en todo momento la emoción detectada vigente |
| RF-22 | El sistema debe registrar la respuesta (aceptación o rechazo) y realimentar el aprendizaje |

### 3.5 Autenticación y sesión

| ID | Requisito |
|---|---|
| RF-23 | El sistema debe permitir registrar un cliente con nombre y apellido, generando un código único |
| RF-24 | El sistema debe permitir iniciar sesión con un cliente ya registrado |
| RF-25 | La sesión activa debe persistir entre reinicios de la aplicación (`shared_preferences`) |

### 3.6 Persistencia y trazabilidad

| ID | Requisito |
|---|---|
| RF-26 | El sistema debe registrar cada interacción junto a la emoción que la originó, con marca de tiempo |
| RF-27 | El sistema debe registrar cada venta con su detalle de línea, congelando el precio efectivamente pactado |
| RF-28 | Todo importe monetario debe almacenarse como **entero en centavos**, nunca en punto flotante |
| RF-29 | El sistema debe mantener activas las restricciones de clave foránea (`PRAGMA foreign_keys = ON`) en toda conexión |
| RF-30 | El sistema debe precargar los catálogos base (tipos de cliente, gestos, tipos de transacción) al crear la base de datos |

### 3.7 Módulo batch

| ID | Requisito |
|---|---|
| RF-31 | El sistema debe ejecutar un cierre diario programado que recalcule los contadores derivados de estrategias, clientes y productos |
| RF-32 | Los 6 procesos del cierre deben ejecutarse en **una única transacción**: se actualizan todos o ninguno |
| RF-33 | El cierre batch debe ser independiente del aprendizaje UCB1, que se recalcula en vivo y no comparte columnas |

### 3.8 Historial

| ID | Requisito |
|---|---|
| RF-34 | El sistema debe mostrar el historial de compras realizadas por el cliente activo |
| RF-35 | El sistema debe mostrar estadísticas agregadas de emociones detectadas y ofertas aceptadas |

### 3.9 Base compartida y administración

| ID | Requisito |
|---|---|
| RF-36 | El catálogo, el stock y las ofertas deben residir en una única base compartida, no en cada dispositivo |
| RF-37 | El administrador debe poder dar de alta un producto sin recompilar la aplicación ni inventar su código: el servidor lo asigna |
| RF-38 | El administrador debe poder publicar una oferta sobre un producto, con porcentaje de descuento y fecha de vigencia |
| RF-39 | Una oferta debe dejar de aplicarse por sí sola al vencer su vigencia, sin intervención manual |
| RF-40 | Los cambios de catálogo, stock y ofertas deben llegar a los dispositivos conectados **sin que el usuario refresque**, mediante notificación del servidor |
| RF-41 | El stock mostrado debe reflejar el inventario real compartido: una compra en un dispositivo debe reducir la cantidad visible en los demás |
| RF-42 | La venta y el descuento de stock deben ejecutarse en una única transacción del servidor, de modo que dos compras simultáneas no puedan vender la misma unidad |
| RF-43 | El sistema debe rechazar la venta de un producto agotado e informar al cliente que se agotó mientras decidía |
| RF-44 | El descuento publicado por el administrador y el descuento adaptativo deben componerse tomando **el mayor de los dos**, nunca la suma |
| RF-45 | Los códigos de negocio (`codCliente`, `idProcesoPersuasion`, correlativos de bitácora) debe asignarlos el servidor, para que dos dispositivos concurrentes no generen el mismo |
| RF-46 | El aprendizaje UCB1 debe alimentarse de las interacciones de todos los usuarios, no solo de las del dispositivo |
| RF-47 | La aplicación no debe poder escribir directamente en ninguna tabla: sus escrituras deben pasar por funciones validadas del servidor |

---

## 4. Requisitos no funcionales

### 4.1 Rendimiento

| ID | Requisito | Medida objetivo |
|---|---|---|
| RNF-01 | El procesamiento por frame no debe degradar la fluidez de la interfaz | ~30 ms por frame |
| RNF-02 | La emoción estable debe estar disponible con latencia acotada desde el cambio real de expresión | 1–2 segundos |
| RNF-03 | La estabilización debe reducir la oscilación de emociones respecto a la señal cruda | De 16 a 7 cambios en 20 s |
| RNF-04 | La decisión de oferta debe resolverse sin bloquear el hilo de interfaz | Operaciones asíncronas |

### 4.2 Confiabilidad e integridad

| ID | Requisito |
|---|---|
| RNF-05 | La aritmética monetaria debe ser exacta: enteros en centavos, sin error de redondeo binario |
| RNF-06 | El cierre batch debe ser atómico; una falla parcial no puede dejar contadores inconsistentes |
| RNF-07 | La integridad referencial debe ser garantizada por el motor, no por convención de código |
| RNF-08 | La negociación debe terminar siempre: la escalada es monótona y finita, sin ciclos de insistencia |

### 4.3 Privacidad y seguridad

| ID | Requisito |
|---|---|
| RNF-09 | Ningún frame ni imagen de rostro debe persistirse ni transmitirse; solo la etiqueta de emoción resultante |
| RNF-10 | El procesamiento del rostro debe ocurrir **en el dispositivo**: al servidor solo viaja la etiqueta de emoción resultante (`triste`, `feliz`, …), nunca la imagen |
| RNF-10b | La clave que viaja dentro del APK debe conceder **solo lectura**: ninguna operación de escritura puede ejecutarse sin pasar por una función validada del servidor |
| RNF-11 | La aplicación debe requerir un único permiso sensible (`CAMERA`), justificado por la funcionalidad central |

### 4.4 Usabilidad

| ID | Requisito |
|---|---|
| RNF-12 | La adaptación no debe exigir aprendizaje previo del usuario: no hay controles que operar |
| RNF-13 | La interfaz debe seguir Material 3 y mantener consistencia visual en toda la aplicación |
| RNF-14 | La grilla del catálogo debe ser responsiva, recalculando de 2 a 4 columnas según el ancho real (`LayoutBuilder`) |

### 4.5 Mantenibilidad y calidad

| ID | Requisito |
|---|---|
| RNF-15 | Las capas deben permanecer desacopladas: el módulo nativo solo produce emoción; el motor de decisión no conoce widgets ni cámara; la interfaz decide *cuándo* preguntar, nunca *qué* ofrecer |
| RNF-16 | El esquema debe estar versionado en migraciones SQL revisables y aplicables en orden, y la aplicación no debe construir SQL en cadenas: se comunica con el backend mediante funciones y vistas nombradas |
| RNF-17 | El proyecto debe mantener cobertura automatizada de las reglas de negocio críticas, en la capa donde vive cada una | 39 pruebas Dart (reglas de adaptación y aprendizaje) + 4 suites SQL (esquema, venta atómica, batch, KPIs y permisos) + 9 JUnit |
| RNF-18 | El código debe pasar `flutter analyze` sin observaciones |
| RNF-19 | El proyecto debe compilar y ejecutarse sin Android Studio, usando VS Code y las command-line tools del SDK |

### 4.6 Portabilidad

| ID | Requisito |
|---|---|
| RNF-20 | La aplicación debe ejecutarse en Android 8.0 (API 26) o superior, en dispositivos con cámara frontal |
| RNF-21 | La aplicación requiere conexión de red para operar; sin ella debe explicarlo en pantalla, no quedar en blanco |
| RNF-22 | El backend debe poder ejecutarse en un PostgreSQL estándar, sin extensiones ni servicios propietarios, para no atar el proyecto a un proveedor |

---

## 5. Limitaciones

### 5.1 Limitaciones del modelo de emociones

| ID | Limitación | Impacto y mitigación |
|---|---|---|
| LIM-01 | El clasificador opera sobre imágenes de 48×48 px y **confunde `triste` con `enojo`**, ya que ambas expresiones bajan las cejas | Es el techo del modelo, no del pipeline. El preprocesamiento (escala de grises, ecualización de histograma, recorte cuadrado) redujo el error de "enojo" con rostro neutral del 49% al 5% |
| LIM-02 | El modelo FER-2013 fue entrenado con un dataset genérico, no con usuarios del contexto de uso real | La precisión puede variar según iluminación, tono de piel y ángulo |
| LIM-03 | La señal es intrínsecamente ruidosa frame a frame | Se compensa con ventana de 26 frames, voto por mayoría e histéresis (RF-07 a RF-09) |
| LIM-04 | Los datos de prueba originales (`docs/TABLAS.docx`) contemplan un gesto fuera de las 5 emociones básicas | El catálogo de gestos quedó acotado a las 5 clases que el clasificador produce |

### 5.2 Limitaciones operativas

| ID | Limitación |
|---|---|
| LIM-05 | Sin rostro visible no hay contexto: la adaptación se detiene y el catálogo conserva el último orden vigente |
| LIM-06 | La orientación está fijada en vertical de forma deliberada; en horizontal el rostro sale del encuadre |
| LIM-07 | Requiere iluminación suficiente para que ML Kit localice el rostro |
| LIM-08 | El uso continuo de cámara y clasificación tiene costo energético; no está optimizado para sesiones prolongadas |
| LIM-09 | Un solo cliente activo por dispositivo, aunque varios dispositivos operen a la vez sobre la misma tienda |
| LIM-09b | Sin conexión, la aplicación no muestra catálogo ni permite comprar: no existe copia local (FA-04) |

### 5.3 Limitaciones de alcance académico

| ID | Limitación |
|---|---|
| LIM-10 | El catálogo se administra a mano desde el panel; no se integra con un ERP ni con un sistema comercial real |
| LIM-11 | La "venta" se registra en base de datos pero no ejecuta cobro ni logística |
| LIM-12 | El aprendizaje UCB1 opera sobre 4 estrategias fijas; no descubre estrategias nuevas |
| LIM-13 | La medición de evidencia proviene de sesiones de prueba del propio equipo, no de usuarios finales independientes |

---

## 6. Evidencia de cumplimiento

La adaptación es auditable porque **cada oferta queda registrada junto a la emoción que la
disparó**. Medición sobre interacciones reales en dispositivo físico (Xiaomi Redmi,
Android 12):

| Estrategia | Intentos | Cierres | Conversión |
|---|---|---|---|
| Oferta relámpago | 100 | 10 | 10.0% |
| Envío gratis | 84 | 5 | 6.0% |
| Recomendación premium | 71 | 2 | 2.8% |
| Descuento directo | 67 | 1 | 1.5% |

El orden por intentos coincide exactamente con el orden por conversión: UCB1 reparte
oportunidades en proporción a lo que cada estrategia cierra. Esa coincidencia no fue
programada — es la huella del aprendizaje.

### Trazabilidad objetivo → verificación

| Concepto del curso | Requisitos que lo cubren | Verificación |
|---|---|---|
| Software adaptativo | RF-11, RF-13 | Prueba automatizada del requisito eliminatorio |
| Adaptación al contexto | RF-01 a RF-05 | Expresión facial como variable de entorno |
| Procesamiento en tiempo real | RNF-01, RNF-02 | ~30 ms/frame; emoción estable en 1–2 s |
| Uso de capacidades del dispositivo | RF-01, RF-02, RF-03, RNF-10 | CameraX, ML Kit y TFLite, todo local |
| Diseño responsivo | RNF-14 | Grilla de 2 a 4 columnas con `LayoutBuilder` |
| Datos compartidos y consistentes | RF-36, RF-41, RF-42 | Venta y stock en una transacción del servidor; pruebas en `supabase/tests/01_ciclo_venta.sql` |
| Adaptación también por decisión humana | RF-37 a RF-40, RF-44 | El administrador publica; la emoción sigue decidiendo. Pruebas en `supabase/tests/02_catalogo_y_ofertas.sql` |

---

## 7. Referencias internas

| Documento | Contenido |
|---|---|
| [INFORME_TECNICO.md](INFORME_TECNICO.md) | Informe técnico de entrega: pipeline, evidencia y justificación |
| [ARQUITECTURA.md](ARQUITECTURA.md) | Detalle de componentes y decisiones de arquitectura |
| [../supabase/README.md](../supabase/README.md) | Puesta en marcha del backend, guía del administrador y pruebas SQL |
| [ESQUEMA_CORREGIDO.md](ESQUEMA_CORREGIDO.md) | Hallazgos G1–G9, correcciones C1–C11 y decisiones D1–D5 del modelo de datos |
| [MODELO_ANDROID_ROOM.md](MODELO_ANDROID_ROOM.md) | Diseño conceptual del esquema |
| [PLAN_ELVIS.md](PLAN_ELVIS.md) | Plan de trabajo, contratos entre módulos y auditoría |
| [GUIA_STEVEN.md](GUIA_STEVEN.md) | Guía de integración del puente nativo y las pantallas |
