# Sistema Inteligente de Ventas - Tienda Adaptativa

Aplicación Android (Flutter + Kotlin) que detecta emociones faciales en tiempo real y adapta automáticamente las ofertas comerciales para maximizar la persuasión de ventas.

## APK automática de la rama `nuevo-modelo`

Cada cambio enviado a `nuevo-modelo` ejecuta las pruebas, compila una APK Android y
actualiza esta descarga:

[Descargar la APK más reciente de `nuevo-modelo`](https://github.com/StevenCadilloS/Sistema-Inteligente-Ventas/releases/download/nuevo-modelo-latest/Sistema-Inteligente-Ventas-nuevo-modelo.apk)

La automatización también se puede ejecutar manualmente desde la pestaña
**Actions**, eligiendo **Generar APK de nuevo-modelo** y luego **Run workflow**.

---

## Descripción

Esta app resuelve un problema concreto del comercio electrónico: **mostrar la oferta correcta, en el momento correcto, a la persona correcta**.

En lugar de mostrar las mismas ofertas a todos los usuarios, el sistema:

1. **Detecta la emoción** del usuario mediante la cámara frontal
2. **Procesa y estabiliza** la emoción para evitar falsos positivos
3. **Decide automáticamente** qué oferta mostrar según la emoción
4. **Aprende** de las aceptaciones/rechazos para mejorar con el tiempo

### Ejemplo de adaptación

| Emoción detectada | Acción automática |
|-------------------|-------------------|
| Tristeza | Muestra producto sustituto más económico con tono empático |
| Sorpresa | Muestra el producto menos exhibido (novedad) |
| Felicidad | Ofrece producto premium (el más caro, sin descuento) |
| Neutral | Muestra el producto más exhibido (oferta estándar) |
| Enojo | Cambia de categoría respecto al último producto mostrado + el más económico de esa categoría |

---

## Estado actual (2026-09-06)

| Parte | Estado | Dueño |
|---|---|---|
| Base de datos, autenticación, motor de reglas, aprendizaje, batch | ✅ **Hecho y probado** (35 tests, build Android verificado) | Elvis |
| Detección facial y clasificación de emociones (Kotlin nativo) | ✅ **Hecho**, compila dentro del proyecto Flutter | Juan |
| Puente Flutter ↔ Kotlin (Platform Channel) | ⏳ **Pendiente** — nada lo conecta todavía | Steven |
| Pantallas (login, producto/oferta, historial) | ⏳ **Pendiente** — `lib/main.dart` sigue siendo la plantilla de `flutter create` | Steven |

**En una frase:** todo lo que decide *qué* mostrar y *cómo* aprender ya existe y está probado con tests automáticos; lo que falta es *mostrarlo en pantalla* y *conectarlo a la cámara real*. Ver [Cómo continuar](#cómo-continuar-por-persona) más abajo para los pasos concretos de cada quien.

---

## Equipo y Responsabilidades

| Área | Responsable(s) | Detalle |
|------|-----------------|---------|
| Base de datos | Elvis | Esquema, migraciones, persistencia local con `drift` (SQLite) |
| Backend (lógica de negocio, Flutter/Dart) | Elvis, Juan, Steven | Trabajo compartido entre los tres integrantes |
| — Integración con la cámara | Steven | Puente Flutter ↔ módulo nativo Kotlin (CameraX) |
| — Modelo de emociones | Juan | Detección facial (ML Kit) y clasificación (TensorFlow Lite) |
| — Reglas de ofertas, aprendizaje y autenticación | Elvis | `AdaptationEngine`, `BanditOptimizer`, `ClienteRepository` |
| Frontend (pantallas, UI) | Steven | Pantallas Flutter (registro, producto, historial) |

---

## Stack Tecnológico

| Componente | Tecnología | Propósito |
|------------|------------|-----------|
| **Framework principal** | Flutter (Dart) | App orientada a Android, UI declarativa y lógica de negocio |
| **Módulo nativo** | Kotlin | Cámara, ML Kit y TensorFlow Lite, expuestos a Flutter vía Platform Channels |
| **UI** | Flutter Widgets | Interfaz declarativa moderna |
| **Base de datos** | SQLite vía [`drift`](https://drift.simonbinder.eu/) | Persistencia local (clientes, productos, estrategias, historial) — tablas tipadas, DAOs por codegen, migraciones |
| **Cámara** | CameraX (Kotlin) | Captura de video en tiempo real |
| **Detección facial** | Google ML Kit (Kotlin) | Detectar rostro y landmarks faciales |
| **Clasificación de emociones** | TensorFlow Lite - FER-2013 (Kotlin) | Clasificar emoción desde imagen de cara |
| **Aprendizaje** | Multi-Armed Bandit - UCB1 (Dart) | Seleccionar la mejor estrategia según historial, recalculado en vivo |
| **Sesión** | `shared_preferences` (Dart) | Cliente activo, persistido en el dispositivo |
| **Batch periódico** | `workmanager` (Dart) | Cierre diario de KPIs, una vez al día |
| **Arquitectura** | Clean Architecture + Pipeline | Separación de responsabilidades entre Flutter y el módulo nativo |
| **Editor** | VS Code + extensiones Flutter/Dart | No se usa Android Studio |

---

## Arquitectura del Sistema

El sistema sigue el **pipeline adaptativo obligatorio** del curso:

```
CONTEXTO → PROCESAMIENTO → DECISIÓN → ADAPTACIÓN
```

Las dos primeras fases corren en el **módulo nativo Kotlin** (única parte del pipeline que necesita APIs Android específicas: CameraX, ML Kit, TensorFlow Lite). Las dos últimas corren en **Flutter/Dart**, que es también quien contiene la UI y la persistencia local.

### Diagrama de componentes

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PIPELINE ADAPTATIVO                          │
├─────────────┬──────────────┬────────────────┬──────────────────────┤
│  CONTEXTO   │ PROCESAMIENTO│    DECISIÓN    │     ADAPTACIÓN      │
│   (Kotlin)  │   (Kotlin)   │     (Dart)     │       (Dart)         │
│   ✅ listo  │   ✅ listo   │   ✅ listo     │   ⏳ pendiente (UI)  │
│             │              │                │                      │
│ CameraManager│EmotionProcessor│ AdaptationEngine│ Pantallas Flutter │
│ EmotionDetector│ (estabiliza)│ BanditOptimizer│ (Steven)           │
│             │              │ ClienteRepository│                     │
├─────────────┼──────────────┼────────────────┼──────────────────────┤
│ CameraX     │ Buffer N     │ Reglas de      │ UI Cambia sola      │
│ ML Kit      │ frames       │ negocio +      │ Colores, ofertas,   │
│ TFLite      │              │ Aprendizaje    │ textos              │
└──────┬──────┴──────┬───────┴────────────────┴──────────────────────┘
       └──────────────┘
     ⏳ Platform Channel Flutter ↔ Kotlin (pendiente — ver "Cómo continuar")
```

### Flujo de ejecución completo

```
1. Cámara captura frame (30 fps)                         ┐
        ↓                                                 │
2. ML Kit detecta cara en el frame                        │  Kotlin
        ↓                                                 │  (nativo, ✅ listo)
3. TFLite clasifica emoción (triste/feliz/sorpresa/neutral/enojo)
        ↓                                                 │
4. EmotionProcessor estabiliza (exige N frames consecutivos) ┘
        ↓
   [Platform Channel envía ProcessedEmotion a Flutter]  ⏳ pendiente
        ↓                                                 ┐
5. AdaptationEngine.decidirOferta(emocion) aplica reglas   │
        ↓                                                 │  Dart
6. BanditOptimizer selecciona mejor estrategia (UCB1)      │  (✅ listo,
        ↓                                                 │   sin UI)
7. UI se actualiza automáticamente con la Oferta           │  ⏳ pendiente
        ↓                                                 │
8. Usuario acepta/rechaza → BanditOptimizer.registrarRespuesta ┘
```

---

## Estructura del Proyecto

Estructura real del repositorio (`flutter create` ya ejecutado, esquema y lógica de negocio ya implementados):

```
PROYECTO01/
│
├── lib/                                        # FLUTTER / DART
│   ├── main.dart                               # Punto de entrada — arranca el batch; UI pendiente
│   │
│   ├── data/
│   │   ├── database/
│   │   │   ├── app_database.dart              # Conexión drift, seed de catálogos, migraciones
│   │   │   ├── tables.dart                     # Las 11 tablas (catálogos, maestras, bitácoras)
│   │   │   └── queries.drift                   # Vista de consulta crítica + 4 KPIs + queries del batch
│   │   ├── repositories/
│   │   │   └── cliente_repository.dart         # registrar() / iniciarSesion() / sesión activa
│   │   └── batch/
│   │       ├── batch_runner.dart               # Cierre diario (6 procesos, 1 sola transacción)
│   │       └── cierre_diario_scheduler.dart     # Programador periódico (workmanager)
│   │
│   └── decision/                               # FASE 3: DECISIÓN
│       ├── adaptation_engine.dart              # decidirOferta(emocion) → Oferta
│       └── learning/
│           └── bandit_optimizer.dart           # UCB1: seleccionarEstrategia() / registrarRespuesta()
│
├── android/                                    # MÓDULO NATIVO (FASES 1 Y 2 DEL PIPELINE)
│   └── app/src/main/
│       ├── kotlin/com/tuapp/tienda_adaptativa/
│       │   ├── context/                        # FASE 1: CONTEXTO — ✅ listo
│       │   │   ├── CameraManager.kt            # Control de cámara y permisos
│       │   │   └── EmotionDetector.kt          # Detección facial + clasificación
│       │   ├── processing/                     # FASE 2: PROCESAMIENTO — ✅ listo
│       │   │   └── EmotionProcessor.kt         # Filtro de estabilidad (N frames)
│       │   └── channel/                        # ⏳ PENDIENTE (Steven)
│       │       └── EmotionChannelHandler.kt    # Expondría el pipeline nativo a Flutter
│       └── assets/
│           ├── emotion_model.tflite            # FER MobileNetV2 calibrado
│           └── README.md                       # Fuente, licencia y contrato
│
├── test/                                       # Espejo de lib/ — 35 tests, todos en verde
│
├── docs/
│   ├── ESQUEMA_CORREGIDO.md                    # Hallazgos G1-G9, correcciones C1-C11, decisiones D1-D5
│   ├── MODELO_ANDROID_ROOM.md                  # Diseño conceptual (apunta a la implementación real)
│   └── PLAN_ELVIS.md                           # Plan de trabajo, contratos entre partes, auditoría
│
└── pubspec.yaml                                # Dependencias Flutter/Dart
```

**Lo que falta crear:** `lib/services/emotion_channel.dart` y `android/.../channel/EmotionChannelHandler.kt` (el puente), y todo `lib/ui/` (pantallas) — ninguno existe todavía.

---

## Tabla de Ubicación del Pipeline

| Elemento del Pipeline | Archivo / Clase | Lenguaje | Estado |
|-----------------------|-----------------|----------|--------|
| **Captura del contexto** | `context/CameraManager.kt` | Kotlin (nativo) | ✅ |
| **Detección de emoción** | `context/EmotionDetector.kt` | Kotlin (nativo) | ✅ |
| **Procesamiento** | `processing/EmotionProcessor.kt` | Kotlin (nativo) | ✅ |
| **Puente Flutter ↔ Kotlin** | `channel/EmotionChannelHandler.kt` / `lib/services/emotion_channel.dart` | Kotlin + Dart | ⏳ |
| **Autenticación** | `lib/data/repositories/cliente_repository.dart` | Dart (Flutter) | ✅ |
| **Decisión** | `lib/decision/adaptation_engine.dart` | Dart (Flutter) | ✅ |
| **Aprendizaje** | `lib/decision/learning/bandit_optimizer.dart` | Dart (Flutter) | ✅ |
| **Batch / KPIs** | `lib/data/batch/batch_runner.dart` | Dart (Flutter) | ✅ |
| **Persistencia** | `lib/data/database/` | Dart (Flutter) | ✅ |
| **Adaptación (UI)** | `lib/ui/` | Dart (Flutter) | ⏳ |

---

## Cómo continuar (por persona)

### Steven — puente + pantallas

Guía completa, con el código del puente Kotlin↔Flutter, las 3 pantallas y una checklist antes de dar por conectado: **[docs/GUIA_STEVEN.md](docs/GUIA_STEVEN.md)**.

Resumen de las firmas que ya existen y están probadas:

```dart
// ClienteRepository
final codCliente = await clienteRepository.registrar(nombre: ..., apellido: ...); // tipoCliente opcional
final activo = clienteRepository.clienteActivo(); // null si nadie inicio sesion

// AdaptationEngine — "emocion" es el string tal cual llega de Kotlin ("triste", "feliz"...)
final oferta = await adaptationEngine.decidirOferta(
  codCliente: activo!, emocion: e.emotion, nivelDeInteres: (e.confidence * 100).round(),
);

// BanditOptimizer
await banditOptimizer.registrarRespuesta(idProcesoPersuasion: oferta.idProcesoPersuasion, aceptada: true);
```

### Juan — modelo de emociones

Tu parte (`EmotionDetector.kt`, `EmotionProcessor.kt`) ya compila y está integrada al proyecto Flutter. Dos cosas útiles mientras Steven arma el puente:
- Ayudar a definir la forma exacta del evento que cruza el channel (qué campos de `ProcessedEmotion` necesita Steven).
- Si tienes tiempo: los datos reales de prueba (`docs/TABLAS.docx`) usan un gesto (`G0000008`) fuera de las 5 emociones básicas — vale la pena revisar si el clasificador debería reconocer algo más que triste/feliz/sorpresa/neutral/enojo.

### Elvis — tu tramo

Las 7 fases del plan están cerradas y auditadas (ver `docs/PLAN_ELVIS.md`). Disponible para ajustar cualquier función de `AdaptationEngine`/`BanditOptimizer`/`ClienteRepository` según lo que Steven necesite al integrar la UI real.

---

## Algoritmo de Aprendizaje: Multi-Armed Bandit

El sistema no solo sigue reglas fijas, sino que **aprende** con el tiempo (`lib/decision/learning/bandit_optimizer.dart`, recalculado en vivo desde la base de datos en cada decisión):

```
Para cada estrategia, se cuenta (COUNT DISTINCT sobre procesos, no filas):
  - Cuántas veces se aplicó (intentos)
  - Cuántas veces terminó en venta (éxitos)

Se usa UCB1 (Upper Confidence Bound) para balancear:
  - EXPLORACIÓN: probar estrategias que no se han aplicado mucho
  - EXPLOTACIÓN: usar la que mejor funciona

Fórmula: score = (éxitos / intentos) + √(2 × ln(N) / intentos)
```

Una estrategia nunca aplicada se prioriza automáticamente (evita dividir entre cero y fuerza que todas se prueben antes de explotar la mejor).

---

## Requisitos

- **Flutter SDK** 3.47+ (`flutter --version`)
- **Dart SDK** (incluido con Flutter)
- **JDK 17+** (para compilar el módulo nativo Android vía Gradle, usado internamente por Flutter)
- **Android SDK** (platform-tools, plataformas 34/36, NDK, build-tools) — se puede instalar sin Android Studio con `sdkmanager` de las command-line tools
- **VS Code** + extensiones Flutter y Dart — no se usa Android Studio
- **Celular Android** con Android 8.0+ (API 26+) y cámara frontal
- **Git**

---

## Instalación y Ejecución

```bash
# 1. Clonar el repositorio
git clone https://github.com/StevenCadilloS/Sistema-Inteligente-Ventas.git
cd Sistema-Inteligente-Ventas

# 2. Instalar las dependencias de Flutter
flutter pub get

# 3. Generar el código de drift (tablas, queries) - necesario tras clonar
#    y despues de CUALQUIER cambio en tables.dart o queries.drift
dart run build_runner build

# 4. Correr los tests (no requiere celular ni emulador)
flutter test

# 5. Conectar el celular Android vía USB (con depuración USB activada)
flutter devices

# 6. Ejecutar la app
flutter run
```

---

## Permisos Requeridos

| Permiso | Razón |
|---------|-------|
| `CAMERA` | Capturar video para detectar emociones |

---

## Cómo Demostrar la Adaptación

> Requiere el puente Flutter↔Kotlin y las pantallas de Steven (ver [Cómo continuar](#cómo-continuar-por-persona)). Mientras tanto, la lógica se puede demostrar corriendo `flutter test` — cada regla y cada aprendizaje tiene un test que la ejercita punta a punta.

### Con el celular (una vez conectado el puente):

1. **Abrir la app** → registrarse
2. **Mostrar cara** → la app detecta emoción y muestra oferta
3. **Cambiar expresión** → la oferta cambia automáticamente
4. **Aceptar/rechazar** → el sistema registra y aprende
5. **Ver historial** → muestra estadísticas de emociones y aceptaciones

### Comandos para revisar logs:

```bash
# Ver logs de la app Flutter
flutter logs

# Ver logs específicos del módulo nativo de emociones
adb logcat | grep "EmotionDetector"
```

---

## Tecnologías y Versiones

| Dependencia | Versión | Uso |
|-------------|---------|-----|
| Flutter | 3.47.x | Framework principal de la app |
| Dart | 3.13.x | Lenguaje de la capa Flutter |
| Kotlin | 1.9.x | Módulo nativo (cámara, ML Kit, TensorFlow Lite) |
| drift | 2.34.x | Base de datos SQLite tipada en Dart |
| shared_preferences | 2.5.x | Sesión del cliente activo |
| workmanager | 0.10.x | Programador del cierre diario |
| CameraX | 1.3.x | Captura de cámara (Kotlin) |
| ML Kit Face Detection | 16.x | Detección de rostro (Kotlin) |
| TensorFlow Lite | 2.16.x | Clasificación de emociones (Kotlin) |

---

## Créditos

- **Dataset de emociones**: [FER-2013](https://www.kaggle.com/datasets/msambare/fer2013) (Facial Expression Recognition)
- **Modelo TensorFlow Lite**: `maftuh-main/meme-emotion-detector` (MIT)
- **Modelo de detección facial**: Google ML Kit
- **Algoritmo de aprendizaje**: Multi-Armed Bandit con UCB1

---

## Licencia

Proyecto académico — Universidad Nacional de Ingeniería, Ciclo 2026-2.
