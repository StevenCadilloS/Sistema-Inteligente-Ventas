# Tienda Adaptativa — Requisitos por Integrante

**Taller 1 · Desarrollo de una Aplicación Adaptativa · UNI FIIS · 2026-2**

Documento complementario de [REQUISITOS.md](REQUISITOS.md). Mientras aquel define *qué*
debe hacer el sistema, este define *quién* se hizo responsable de cada requisito y con qué
evidencia se sustenta. Los identificadores `RF-*`, `RNF-*` y `LIM-*` son los de
[REQUISITOS.md](REQUISITOS.md).

---

## 1. Método de atribución

La asignación no se declara: se **verifica contra el historial del repositorio**. Cada
responsable se determinó cruzando tres fuentes:

1. `git log --all --author` (autoría real de los commits, sobre todas las ramas).
2. Autoría por archivo (`git log --all -- <archivo>`), para distinguir quién **creó** un
   componente de quién lo **refinó** después.
3. Los roles declarados en `README.md`.

Cuando la creación y el refinamiento corresponden a personas distintas, ambas quedan
registradas: la primera como **autor** y la segunda como **integrador**.

### Volumen de contribución

Medido con `git log --all --format="%ae" | sort | uniq -c`:

| Integrante | Commits | Identidades git | Área principal |
|---|---:|---|---|
| Elvis Arboleda | 124 | `3lvisarboleda7-ctrl`, `Elvis Arboleda` | Datos, decisión, backend, integración final |
| Juan Medina | 36 | `Juan Medina`, `bastianperrogordo-cell` | Modelo de emociones y clasificación |
| Steven Cadillo | 21 | `StevenCadilloS`, `Steven Cadillo` | Interfaz, widgets y puente del lado Flutter |

(Un commit adicional es de `github-actions[bot]`.)

---

## 2. Elvis Arboleda — Datos, decisión e integración

**Fases del pipeline a cargo:** DECISIÓN y persistencia; refinamiento de PROCESAMIENTO;
integración final de todas las capas.

### 2.1 Requisitos bajo su responsabilidad

| ID | Requisito | Entregable |
|---|---|---|
| RF-12 – RF-15 | Clasificar la racha de lecturas en una respuesta, con umbral de votos y desempate favorable | `ClasificadorRespuesta` en `lib/decision/negociacion.dart` |
| RF-16 – RF-19 | Avanzar por la escalera solo ante respuesta desfavorable, en un sentido, empezando en precio normal (**requisito eliminatorio**) | `Negociacion` en `lib/decision/negociacion.dart` |
| RF-20 – RF-22 | Ciclo de la negociación: pedir escalera, encender y apagar la cámara, no encenderla si viene vacía | `lib/ui/tienda_screen.dart` |
| RF-27 – RF-30 | Registro, ingreso, sesión persistida y aislamiento del historial por cliente | `0004_autenticacion.sql`, `lib/data/remote/sesion_service.dart` |
| RF-31 – RF-34 | Persistencia, precio congelado, centavos enteros, FK activas, una venta por confirmación | `0001_esquema.sql`, `0011_carrito.sql` |
| RF-36 – RF-40 | Base compartida; alta de productos y ofertas con vigencia y orden único | `0001_esquema.sql`, `0002_funciones.sql`, `supabase/README.md` |
| RF-41, RF-42 | Propagación en tiempo real del catálogo y del stock | `supabase_tienda_repository.dart` (Realtime) |
| RF-43, RF-44 | Venta y descuento de stock atómicos (`FOR UPDATE`); rechazo por agotado | `fn_confirmar_carrito()`, `SinStockException` |
| RF-45, RF-46 | Una sola oferta al día por cliente, con el día en `America/Lima` | `0013_limite_oferta_unica.sql`, `fn_zona_negocio()` |
| RF-47, RF-48 | La app no escribe tablas; el servidor recalcula el total y saca el cliente del token | RLS de `0001_esquema.sql`, `supabase/tests/04_seguridad.sql` |
| RNF-06 – RNF-09 | Aritmética exacta, integridad por el motor, terminación de la negociación, sin timers colgados | `0001_esquema.sql`, `negociacion.dart`, `tienda_screen_test.dart` |
| RNF-12, RNF-13 | Clave pública de solo lectura; la `service_role` nunca en el APK | `0001_esquema.sql`, `README.md` |
| RNF-19 – RNF-22 | Desacoplamiento de capas, esquema versionado, sin SQL en cadenas, cobertura automatizada | `supabase/migrations/`, `tienda_repository.dart`, `test/` |
| RNF-27 | Backend sobre PostgreSQL estándar, sin extensiones propietarias | `supabase/migrations/`, CI en `backend-sql.yml` |

### 2.2 Archivos de los que es autor principal

```
lib/decision/negociacion.dart                    ( 4 commits)
lib/ui/tienda_screen.dart                        (23 commits)
lib/main.dart
lib/data/repositories/tienda_repository.dart, supabase_tienda_repository.dart
lib/data/modelos/modelos.dart
lib/data/remote/  (supabase_config, sesion_service, actualizacion_service, build_info)
lib/ui/login_screen.dart                         (11 commits)
supabase/migrations/                             (las 14)
supabase/tests/                                  ( 3 suites SQL + ejecutar.sh)
android/.../context/CameraManager.kt
```

### 2.3 Aportes de integración sobre trabajo de terceros

| Componente | Autor original | Aporte de Elvis |
|---|---|---|
| `EmotionDetector.kt` | Juan | Preprocesamiento (grises, ecualización de histograma, recorte cuadrado): el error de "enojo" con rostro neutral bajó del **49% al 5%**. Corrección del orden de clases del modelo (alfabético de Keras, no el canónico de FER-2013) |
| `EmotionProcessor.kt` | Juan | Sustituyó unanimidad por **voto de mayoría al 45% con histéresis** sobre ventana de 26 frames: los cambios de emoción bajaron de **16 a 7 en 20 s**. Tolerancia a pérdidas momentáneas del rostro |
| `emotion_channel.dart` | Steven | Degradación cuando no hay detector (`disponible == false`) y propagación de errores de cámara |
| `lib/ui/tienda_screen.dart` | Steven (`principal_screen.dart`) | Reescritura para soportar la ventana de observación y la escalera de ofertas |

### 2.4 Documentación a su cargo

`README.md` · `INFORME_TECNICO.md` · `ARQUITECTURA.md` · `REQUISITOS.md` ·
`GUIA_ESTUDIO.md` · `RETOS_EN_VIVO.md` · `supabase/README.md` · `ESQUEMA_CORREGIDO.md`

---

## 3. Juan Medina — Modelo de emociones y clasificación

**Fases del pipeline a cargo:** CONTEXTO (detección y clasificación) y la primera versión
de PROCESAMIENTO.

### 3.1 Requisitos bajo su responsabilidad

| ID | Requisito | Entregable |
|---|---|---|
| RF-02 | Localizar el rostro en cada frame mediante ML Kit Face Detection | `android/.../context/EmotionDetector.kt` |
| RF-03 | Clasificar la expresión en 5 emociones con TensorFlow Lite (48×48 px) | `EmotionDetector.kt` |
| RF-04 | Emitir la confianza del clasificador junto a cada emoción | `EmotionDetector.kt` |
| RF-07, RF-08 | Ventana deslizante y resolución de la emoción estable | `EmotionProcessor.kt` (versión inicial) |
| RNF-01 | Coste de procesamiento por frame acotado (~30 ms) | Modelo TFLite cuantizado, 48×48 |
| RNF-10, RNF-11 | No persistir ni transmitir frames; procesamiento íntegro en el dispositivo | Modelo empaquetado como asset local |

### 3.2 Archivos de los que es autor principal

```
android/.../context/EmotionDetector.kt            ( 7 commits)
android/.../processing/EmotionProcessor.kt        ( 3 commits, versión inicial)
android/app/src/main/assets/emotion_model.tflite  (modelo FER-2013)
android/app/src/main/assets/LICENSE-emotiscan-face-api.txt
android/app/build.gradle.kts                      (dependencias ML)
android/app/src/test/.../EmotionProcessorTest.kt  (9 pruebas JUnit)
tools/ferplus/convert_ferplus.py                  (conversión del dataset FER+)
```

### 3.3 Infraestructura de build

Automatizó la obtención del modelo y la generación de APK vía GitHub Actions (la descarga
del `.tflite` fuera del repo, y los workflows de APK por rama).

### 3.4 Limitaciones documentadas por su área

| ID | Limitación |
|---|---|
| LIM-01 | El clasificador confunde `triste` con `enojo`: ambas expresiones bajan las cejas |
| LIM-02 | FER-2013 es un dataset genérico; la precisión varía con iluminación y ángulo |
| LIM-03 | La señal es ruidosa frame a frame por naturaleza del clasificador |
| LIM-04 | `disgust` y `fear` no tienen regla propia y se pliegan a `enojo` y `neutral` |

---

## 4. Steven Cadillo — Interfaz, widgets y puente del lado Flutter

**Fase del pipeline a cargo:** ADAPTACIÓN (interfaz) y el extremo Dart del puente nativo.

### 4.1 Requisitos bajo su responsabilidad

| ID | Requisito | Entregable |
|---|---|---|
| RF-11 | Recibir la emoción estable desde Kotlin por `EventChannel` | `lib/services/emotion_channel.dart` |
| RF-23 | Mostrar en todo momento la emoción detectada vigente y su confianza | `lib/ui/widgets/chip_emocion.dart` |
| RF-24 | Mostrar el escalón vigente sin revelar cuántos quedan | `lib/ui/widgets/popup_oferta.dart` |
| RF-25 | "No, gracias" avanza un escalón en vez de cerrar la negociación | `popup_oferta.dart`, `tienda_screen.dart` |
| RF-35 | Historial por venta con pantalla de detalle | `lib/ui/historial_screen.dart`, `lib/ui/detalle_venta_screen.dart` |
| RNF-15 – RNF-17 | Adaptación sin controles que aprender, Material 3, grilla responsiva de 2 a 4 columnas | Widgets y pantallas |

### 4.2 Archivos de los que es autor principal

```
lib/services/emotion_channel.dart          — extremo Dart del puente nativo
lib/ui/detalle_venta_screen.dart           — detalle línea a línea de una venta
lib/ui/widgets/carrito_hoja.dart           — hoja del carrito
lib/ui/widgets/producto_card.dart
lib/ui/widgets/popup_oferta.dart
lib/ui/widgets/chip_emocion.dart
lib/ui/widgets/banner_esperando.dart
lib/ui/widgets/titulo_feed.dart
lib/ui/widgets/imagen_producto.dart
assets/products/*.jpg                      — imágenes del catálogo
```

### 4.3 Aporte transversal

- **Contrato del puente:** definió la forma del evento que cruza de Kotlin a Dart
  (`{emoción, confianza}`), consumido después por `TiendaScreen`.
- **Catálogo visual:** las imágenes de producto hacen visible la rebaja en pantalla; sin
  ellas la adaptación es un número que cambia, no algo que se ve.
- **Carrito y detalle de venta:** las dos pantallas que convierten "una compra" en un
  objeto con líneas, base de la regla de una sola oferta por confirmación.

---

## 5. Requisitos de responsabilidad compartida

| ID | Requisito | Reparto |
|---|---|---|
| RF-01 | Captura continua con CameraX frontal | Elvis (`CameraManager.kt`) sobre el diseño de contexto de Juan |
| RF-05 | Captura sin previsualización visible | Juan (nativo) + Steven (la UI nunca muestra el frame) |
| RF-06 | Permiso `CAMERA` pedido al iniciar la negociación | Elvis + Steven (`MainActivity.kt`, `AndroidManifest.xml`) |
| RF-09, RF-10 | Histéresis y tolerancia a pérdida del rostro | Juan (versión inicial) → Elvis (mayoría con histéresis) |
| RF-26 | Degradación donde no hay módulo nativo | Steven (puente) + Elvis (`tienda_screen.dart`) |
| RNF-02 – RNF-04 | Latencia de la emoción estable y de la ventana | Depende de la cadena completa: modelo, ventana y puente |
| RNF-23 | `flutter analyze` sin observaciones | Los tres, sobre sus propios archivos |
| RNF-24 | Compilar sin Android Studio (VS Code + command-line tools) | Decisión de equipo, sostenida por los tres |

---

## 6. Matriz de trazabilidad requisito → responsable

| Bloque de requisitos | Elvis | Juan | Steven |
|---|:---:|:---:|:---:|
| RF-01 – RF-06 · Contexto y captura | ◐ | ● | ◐ |
| RF-07 – RF-11 · Procesamiento y puente | ● | ◐ | ◐ |
| RF-12 – RF-19 · Decisión y escalera | ● | | |
| RF-20 – RF-26 · Adaptación e interfaz | ● | | ● |
| RF-27 – RF-30 · Autenticación y sesión | ● | | ◐ |
| RF-31 – RF-35 · Persistencia e historial | ● | | ◐ |
| RF-36 – RF-48 · Base compartida y administración | ● | | |
| RNF-01 – RNF-05 · Rendimiento | ◐ | ● | |
| RNF-06 – RNF-09 · Confiabilidad e integridad | ● | | |
| RNF-10 – RNF-14 · Privacidad y seguridad | ● | ● | |
| RNF-15 – RNF-18 · Usabilidad | | | ● |
| RNF-19 – RNF-24 · Mantenibilidad y calidad | ● | ◐ | ◐ |
| RNF-25 – RNF-27 · Portabilidad | ● | ◐ | |

**●** responsable principal  ·  **◐** contribución parcial

---

## 7. Evidencia por integrante

| Integrante | Evidencia verificable |
|---|---|
| Elvis | 158 pruebas Dart en `test/` (clasificador, negociación, pantallas, carrito) y 3 suites SQL en `supabase/tests/` (ciclo de venta, catálogo y ofertas, seguridad) que corren contra un PostgreSQL 16 real en CI |
| Juan | 9 pruebas JUnit sobre `EmotionProcessor`; medición del preprocesamiento (error 49% → 5%); modelo TFLite empaquetado y flujo de CI que lo descarga |
| Steven | Aplicación ejecutándose en dispositivo físico (Xiaomi Redmi, Android 12); APK publicada automáticamente por rama; imágenes del catálogo; carrito y detalle de venta |

**Verificación conjunta:** la regla eliminatoria del taller —*la oferta avanza sola, sin
intervención manual*— está fijada por una prueba de widget que no pulsa ningún botón
(`test/ui/tienda_screen_test.dart`), y la separación de capas está fijada por el hecho de
que las 158 pruebas Dart corren sin cámara, sin emulador y sin backend. Detalle en
[REQUISITOS.md §6](REQUISITOS.md) e [INFORME_TECNICO.md](INFORME_TECNICO.md).
