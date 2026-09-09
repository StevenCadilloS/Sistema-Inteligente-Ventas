# Tienda Adaptativa — Requisitos por Integrante

**Taller 1 · Desarrollo de una Aplicación Adaptativa · UNI FIIS · 2026**

Documento complementario de [REQUISITOS.md](REQUISITOS.md). Mientras aquel define *qué*
debe hacer el sistema, este define *quién* se hizo responsable de cada requisito y con
qué evidencia se sustenta.

---

## 1. Método de atribución

La asignación no se declara: se **verifica contra el historial del repositorio**. Cada
responsable se determinó cruzando tres fuentes:

1. `git log --author` sobre todas las ramas (autoría real de los commits).
2. Autoría por archivo (`git log -- <archivo>`), para distinguir quién **creó** un
   componente de quién lo **refinó** después.
3. Los roles declarados en `README.md` y `docs/PLAN_ELVIS.md`.

Cuando la creación y el refinamiento corresponden a personas distintas, ambas quedan
registradas: la primera como **autor** y la segunda como **integrador**.

### Volumen de contribución

| Integrante | Commits | Identidades git | Área principal |
|---|---:|---|---|
| Elvis Arboleda | 87 | `3lvisarboleda7-ctrl` | Datos, decisión, aprendizaje, batch, integración final |
| Juan Medina | 25 | `Juan Medina`, `bastianperrogordo-cell` | Modelo de emociones y clasificación |
| Steven Cadillo | 14 | `StevenCadilloS`, `Steven Cadillo` | Interfaz, widgets y puente del lado Flutter |

---

## 2. Elvis Arboleda — Datos, decisión, aprendizaje e integración

**Fases del pipeline a cargo:** DECISIÓN y persistencia; refinamiento de PROCESAMIENTO;
integración final de todas las capas.

### 2.1 Requisitos bajo su responsabilidad

| ID | Requisito | Entregable |
|---|---|---|
| RF-11 | Reordenar el catálogo según la emoción estable | `lib/decision/adaptation_engine.dart` |
| RF-12 | Asignar descuento por emoción (10% / 0% / 15% / 0% / 25%) | `adaptation_engine.dart` |
| RF-13 | Ejecutar el reordenamiento sin intervención manual (**requisito eliminatorio**) | `adaptation_engine.dart` + prueba que lo fija |
| RF-14 | Seleccionar estrategia comercial mediante UCB1 | `lib/decision/learning/bandit_optimizer.dart` |
| RF-15 | Priorizar estrategias nunca aplicadas (exploración forzada) | `bandit_optimizer.dart` |
| RF-16 – RF-20 | Negociación acotada de 3 peldaños, monótona y finita | `adaptation_engine.dart`, `tienda_screen.dart` |
| RF-22 | Registrar aceptación/rechazo y realimentar el aprendizaje | `bandit_optimizer.dart` |
| RF-23 – RF-25 | Registro, inicio de sesión y persistencia de sesión | `lib/data/repositories/cliente_repository.dart` |
| RF-26 – RF-30 | Persistencia, trazabilidad, centavos enteros, FK activas, seed de catálogos | `supabase/migrations/0001_esquema.sql`, `0003_semilla.sql` |
| RF-31 – RF-33 | Cierre diario batch: 6 procesos en una transacción | `fn_cierre_diario()` en `supabase/migrations/0002_funciones.sql`, `cierre_diario_scheduler.dart` |
| RF-36 – RF-39 | Base compartida; alta de productos y ofertas con vigencia desde el panel | `supabase/migrations/0001_esquema.sql` (tabla `ofertas`), `supabase/README.md` |
| RF-40, RF-41 | Propagación en tiempo real del catálogo y del stock a todos los dispositivos | `supabase_tienda_repository.dart` (Realtime), `tienda_screen.dart` |
| RF-42, RF-43 | Venta y descuento de stock atómicos; rechazo por agotado | `fn_registrar_venta()`, `SinStockException` |
| RF-44 | Composición de descuentos: el mayor entre promoción y emoción, nunca la suma | `adaptation_engine.dart`, vista `v_catalogo` |
| RF-45 | Códigos y correlativos asignados por el servidor | `fn_siguiente_correlativo()`, `fn_siguiente_proceso()` |
| RF-46 | Aprendizaje UCB1 sobre las interacciones de todos los usuarios | vista `v_estrategia_desempeno`, `bandit_optimizer.dart` |
| RF-47 | La app no escribe tablas: solo funciones validadas del servidor | políticas RLS de `0001_esquema.sql`, `supabase/tests/04_seguridad.sql` |
| RNF-05 | Aritmética monetaria exacta en centavos | `0001_esquema.sql`, `adaptation_engine.dart` |
| RNF-06 | Atomicidad del cierre batch | `fn_cierre_diario()` (una función plpgsql es una transacción) |
| RNF-10b, RNF-22 | Clave pública de solo lectura; backend sobre PostgreSQL estándar | `0001_esquema.sql`, `supabase/docker-compose.yml` |
| RNF-07 | Integridad referencial garantizada por el motor | `0001_esquema.sql` (claves foráneas de PostgreSQL, siempre activas) |
| RNF-08 | Terminación garantizada de la negociación | `adaptation_engine.dart` |
| RNF-15 | Desacoplamiento entre capas | Arquitectura general |
| RNF-16 | Esquema versionado en migraciones SQL; la app no arma SQL en cadenas | `supabase/migrations/`, `tienda_repository.dart` |
| RNF-17 | Cobertura automatizada de reglas críticas, en la capa donde vive cada una | `test/` (39 casos Dart) + `supabase/tests/` (4 suites SQL) |

### 2.2 Archivos de los que es autor principal

```
lib/decision/adaptation_engine.dart              (18 commits)
lib/decision/learning/bandit_optimizer.dart      ( 8 commits)
supabase/migrations/0001_esquema.sql, 0002_funciones.sql, 0003_semilla.sql
supabase/tests/                                  (4 suites SQL)
lib/data/repositories/tienda_repository.dart, supabase_tienda_repository.dart
lib/data/repositories/cliente_repository.dart
lib/data/modelos/modelos.dart
lib/data/batch/cierre_diario_scheduler.dart
lib/ui/tienda_screen.dart                        (12 commits)
lib/main.dart                                    (12 commits)
lib/theme/app_theme.dart
android/.../context/CameraManager.kt
tools/ver_base.py
```

### 2.3 Aportes de integración sobre trabajo de terceros

Además de sus componentes, cerró la integración de las piezas de los otros dos
integrantes:

| Componente | Autor original | Aporte de Elvis |
|---|---|---|
| `EmotionDetector.kt` | Juan | Preprocesamiento (escala de grises, ecualización de histograma, recorte cuadrado): el error de "enojo" con rostro neutral bajó del **49% al 5%** |
| `EmotionProcessor.kt` | Juan | Sustituyó unanimidad por **voto de mayoría al 45% con histéresis** sobre ventana de 26 frames: los cambios de emoción bajaron de **16 a 7 en 20 s** |
| `EmotionChannelHandler.kt` | Steven / Juan | Estabilización del `EventChannel` y contrato definitivo del evento |
| `lib/ui/tienda_screen.dart` | Steven (`principal_screen.dart`) | Reescritura para soportar la negociación acotada y el bloqueo de tienda |

### 2.4 Documentación a su cargo

`PLAN_ELVIS.md` (20 commits) · `ESQUEMA_CORREGIDO.md` · `GUIA_ESTUDIO.md` ·
`RETOS_EN_VIVO.md` · `INFORME_TECNICO.md` · `README.md`

---

## 3. Juan Medina — Modelo de emociones y clasificación

**Fases del pipeline a cargo:** CONTEXTO (detección y clasificación) y la primera versión
de PROCESAMIENTO.

### 3.1 Requisitos bajo su responsabilidad

| ID | Requisito | Entregable |
|---|---|---|
| RF-02 | Localizar el rostro en cada frame mediante ML Kit Face Detection | `android/.../context/EmotionDetector.kt` |
| RF-03 | Clasificar la expresión en 5 emociones con TensorFlow Lite (48×48 px) | `EmotionDetector.kt`, `TfliteEmotionClassifier.kt` |
| RF-04 | Emitir el nivel de interés 0–100 desde la confianza del clasificador | `EmotionDetector.kt` |
| RF-07 | Ventana deslizante de frames previa a declarar emoción estable | `EmotionProcessor.kt` (versión inicial) |
| RF-08 | Resolución de la emoción estable por consenso de la ventana | `EmotionProcessor.kt` (versión inicial) |
| RNF-01 | Coste de procesamiento por frame acotado (~30 ms) | Modelo TFLite cuantizado, 48×48 |
| RNF-09 | No persistir ni transmitir frames: solo la etiqueta de emoción | `EmotionDetector.kt` |
| RNF-10 | Procesamiento íntegro en el dispositivo, sin servicios externos | Modelo empaquetado como asset local |

### 3.2 Archivos de los que es autor principal

```
android/app/src/main/kotlin/.../context/EmotionDetector.kt      ( 8 commits)
android/app/src/main/kotlin/.../processing/EmotionProcessor.kt  (versión inicial)
android/app/src/main/assets/emotion_model.tflite                (modelo FER-2013)
android/app/src/main/assets/LICENSE-emotiscan-face-api.txt
android/app/build.gradle.kts                                    (dependencias ML)
app/src/main/java/.../context/TfliteEmotionClassifier.kt
app/src/main/java/.../context/EmotionLabels.kt
android/app/src/test/kotlin/.../EmotionProcessorTest.kt         (JUnit)
```

### 3.3 Infraestructura de build

Automatizó la obtención del modelo y la generación de APK vía GitHub Actions:

```
.github/workflows/fetch-emotion-model.yml     — descarga el .tflite fuera del repo
.github/workflows/build-steven1-1-apk.yml     — APK automática de la rama de integración
.github/workflows/build-steven1-apk.yml
.github/workflows/build-nuevo-modelo-apk.yml
```

### 3.4 Limitaciones documentadas por su área

| ID | Limitación |
|---|---|
| LIM-01 | El clasificador confunde `triste` con `enojo`: ambas expresiones bajan las cejas |
| LIM-02 | FER-2013 es un dataset genérico; la precisión varía con iluminación y ángulo |
| LIM-03 | La señal es ruidosa frame a frame por naturaleza del clasificador |
| LIM-04 | Los datos de prueba originales contemplaban un gesto fuera de las 5 clases soportadas |

---

## 4. Steven Cadillo — Interfaz, widgets y puente del lado Flutter

**Fase del pipeline a cargo:** ADAPTACIÓN (interfaz) y el extremo Dart del puente nativo.

### 4.1 Requisitos bajo su responsabilidad

| ID | Requisito | Entregable |
|---|---|---|
| RF-10 | Recibir la emoción estable desde Kotlin por `EventChannel` | `lib/services/emotion_channel.dart` |
| RF-21 | Mostrar en todo momento la emoción detectada vigente | `lib/ui/widgets/chip_emocion.dart` |
| RF-23 – RF-24 | Pantallas de registro e inicio de sesión | `lib/ui/login_screen.dart` |
| RF-34 | Mostrar el historial de compras del cliente activo | `lib/ui/historial_screen.dart`, `widgets/compras_realizadas.dart` |
| RF-35 | Mostrar estadísticas agregadas de emociones y ofertas aceptadas | `lib/ui/historial_screen.dart` |
| RNF-12 | Adaptación sin controles que el usuario deba aprender a operar | Diseño de la interfaz |
| RNF-13 | Consistencia visual bajo Material 3 | Widgets y pantallas |
| RNF-14 | Grilla responsiva de 2 a 4 columnas según ancho real | `LayoutBuilder` en la vista de catálogo |

### 4.2 Archivos de los que es autor principal

```
lib/services/emotion_channel.dart          — extremo Dart del puente nativo
lib/ui/login_screen.dart
lib/ui/historial_screen.dart
lib/ui/principal_screen.dart               ( 8 commits; base de tienda_screen.dart)
lib/ui/widgets/producto_card.dart
lib/ui/widgets/popup_oferta.dart
lib/ui/widgets/chip_emocion.dart
lib/ui/widgets/banner_esperando.dart
lib/ui/widgets/titulo_feed.dart
lib/ui/widgets/compras_realizadas.dart
assets/products/*.jpg                      — 16 imágenes del catálogo
tools/ferplus/convert_ferplus.py           — conversión del dataset FER+
```

### 4.3 Aporte transversal

- **Contrato del puente:** definió la forma del evento que cruza de Kotlin a Dart
  (`{emoción, confianza}`), consumido después por `AdaptationEngine`.
- **Catálogo visual:** las 16 imágenes de producto son el insumo que hace visible el
  reordenamiento adaptativo; sin ellas la adaptación no sería demostrable en pantalla.
- **Rama de integración:** `steven1.1` es la rama sobre la que converge el trabajo de los
  tres y desde la que se publica la APK.

---

## 5. Requisitos de responsabilidad compartida

Estos requisitos no pertenecen a una sola persona: se cumplen por la interacción correcta
de las tres capas.

| ID | Requisito | Reparto |
|---|---|---|
| RF-01 | Captura continua con CameraX frontal | Elvis (`CameraManager.kt`) sobre el diseño de contexto de Juan |
| RF-05 | Captura sin previsualización visible | Juan (nativo) + Steven (la UI nunca muestra el frame) |
| RF-06 | Solicitud del permiso `CAMERA` en tiempo de ejecución | Elvis + Steven (`MainActivity.kt`, `AndroidManifest.xml`) |
| RF-09 | Histéresis en la estabilización | Juan (versión inicial) → Elvis (voto por mayoría con histéresis) |
| RNF-02 | Emoción estable disponible en 1–2 s | Depende de la cadena completa: modelo, ventana y puente |
| RNF-18 | `flutter analyze` sin observaciones | Los tres, sobre sus propios archivos |
| RNF-19 | Compilar sin Android Studio (VS Code + command-line tools) | Decisión de equipo, sostenida por los tres |

---

## 6. Matriz de trazabilidad requisito → responsable

| Bloque de requisitos | Elvis | Juan | Steven |
|---|:---:|:---:|:---:|
| RF-01 – RF-06 · Contexto y captura | ◐ | ● | ◐ |
| RF-07 – RF-10 · Procesamiento y puente | ● | ◐ | ◐ |
| RF-11 – RF-15 · Decisión y aprendizaje | ● | | |
| RF-16 – RF-22 · Negociación y adaptación | ● | | ◐ |
| RF-23 – RF-25 · Autenticación y sesión | ● | | ◐ |
| RF-26 – RF-30 · Persistencia y trazabilidad | ● | | |
| RF-31 – RF-33 · Módulo batch | ● | | |
| RF-34 – RF-35 · Historial | ◐ | | ● |
| RNF-01 – RNF-04 · Rendimiento | ◐ | ● | |
| RNF-05 – RNF-08 · Confiabilidad e integridad | ● | | |
| RNF-09 – RNF-11 · Privacidad y seguridad | ◐ | ● | |
| RNF-12 – RNF-14 · Usabilidad | | | ● |
| RNF-15 – RNF-19 · Mantenibilidad y calidad | ● | ◐ | ◐ |
| RNF-20 – RNF-21 · Portabilidad | ● | ◐ | |

**●** responsable principal  ·  **◐** contribución parcial

---

## 7. Evidencia por integrante

| Integrante | Evidencia verificable |
|---|---|
| Elvis | 39 pruebas Dart en `test/` (motor de reglas, UCB1, sesión) y 4 suites SQL en `supabase/tests/` (esquema, venta atómica, ofertas, batch, KPIs y permisos) que corren contra un PostgreSQL real en CI; base de evidencia con interacciones y ventas reales consultable vía `tools/ver_base.py --evidencia` |
| Juan | 9 pruebas JUnit sobre `EmotionProcessor`; medición del preprocesamiento (error del 49% → 5%); modelo TFLite empaquetado y flujo de CI que lo descarga |
| Steven | Aplicación ejecutándose en dispositivo físico (Xiaomi Redmi, Android 12); APK publicada automáticamente desde la rama `steven1.1`; 16 productos con imagen en el catálogo |

**Verificación conjunta:** la adaptación es auditable porque cada oferta queda registrada
junto a la emoción que la disparó. El orden de estrategias por número de intentos coincide
exactamente con el orden por conversión — huella del aprendizaje UCB1, no de una regla
programada. Detalle en [REQUISITOS.md §6](REQUISITOS.md) e
[INFORME_TECNICO.md §5](INFORME_TECNICO.md).
