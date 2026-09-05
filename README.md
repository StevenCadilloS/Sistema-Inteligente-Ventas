# Sistema Inteligente de Ventas - Tienda Adaptativa

Aplicación Android (Flutter + Kotlin) que detecta emociones faciales en tiempo real y adapta automáticamente las ofertas comerciales para maximizar la persuasión de ventas.

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
| Sorpresa | Aplica descuento especial o sugiere un combo |
| Felicidad | Ofrece producto premium (sin descuento) |
| Neutral | Muestra oferta estándar del catálogo |
| Enojo | Cambia de categoría y ofrece descuento agresivo |

---

## Equipo y Responsabilidades

| Área | Responsable(s) | Detalle |
|------|-----------------|---------|
| Base de datos | Elvis | Modelado y persistencia local con SQLite (`sqflite`) |
| Backend (lógica de negocio, Flutter/Dart) | Elvis, Juan, Steven | Trabajo compartido entre los tres integrantes |
| — Integración con la cámara | Steven | Puente Flutter ↔ módulo nativo Kotlin (CameraX) |
| — Modelo de emociones | Juan | Detección facial (ML Kit) y clasificación (TensorFlow Lite) |
| — Reglas de ofertas y autenticación | Elvis | `AdaptationEngine`, `BanditOptimizer`, login/registro |
| Frontend (pantallas, UI) | Steven | Pantallas Flutter (registro, producto, historial) |

---

## Stack Tecnológico

| Componente | Tecnología | Propósito |
|------------|------------|-----------|
| **Framework principal** | Flutter (Dart) | App orientada a Android, UI declarativa y lógica de negocio |
| **Módulo nativo** | Kotlin | Cámara, ML Kit y TensorFlow Lite, expuestos a Flutter vía Platform Channels |
| **UI** | Flutter Widgets | Interfaz declarativa moderna |
| **Base de datos** | SQLite (`sqflite`) | Persistencia local (usuarios, productos, historial) |
| **Cámara** | CameraX (Kotlin) | Captura de video en tiempo real |
| **Detección facial** | Google ML Kit (Kotlin) | Detectar rostro y landmarks faciales |
| **Clasificación de emociones** | TensorFlow Lite - FER-2013 (Kotlin) | Clasificar emoción desde imagen de cara |
| **Aprendizaje** | Multi-Armed Bandit - UCB1 (Dart) | Seleccionar la mejor oferta según historial |
| **Arquitectura** | Clean Architecture + Pipeline | Separación de responsabilidades entre Flutter y el módulo nativo |
| **DI** | Provider / GetIt (Dart) | Conectar componentes sin acoplamiento |
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
│             │              │                │                      │
│ CameraManager│EmotionProcessor│ AdaptationEngine│ DynamicOfferCard  │
│ EmotionDetector│ (estabiliza)│ BanditOptimizer│ AdaptiveTheme      │
│             │              │                │ ProductRepository   │
├─────────────┼──────────────┼────────────────┼──────────────────────┤
│ CameraX     │ Buffer N     │ Reglas de      │ UI Cambia sola      │
│ ML Kit      │ frames       │ negocio +      │ Colores, ofertas,   │
│ TFLite      │              │ Aprendizaje    │ textos              │
└──────┬──────┴──────┬───────┴────────────────┴──────────────────────┘
       └──────────────┘
     EmotionChannel (Platform Channel Flutter ↔ Kotlin)
```

### Flujo de ejecución completo

```
1. Cámara captura frame (30 fps)                         ┐
        ↓                                                 │
2. ML Kit detecta cara en el frame                        │  Kotlin
        ↓                                                 │  (nativo)
3. TFLite clasifica emoción (triste/feliz/sorpresa/neutral/enojo)
        ↓                                                 │
4. EmotionProcessor estabiliza (exige N frames consecutivos) ┘
        ↓
   [Platform Channel envía ProcessedEmotion a Flutter]
        ↓                                                 ┐
5. AdaptationEngine aplica reglas según emoción            │
        ↓                                                 │  Dart
6. BanditOptimizer selecciona mejor oferta (exploración vs explotación)
        ↓                                                 │  (Flutter)
7. UI se actualiza automáticamente (nueva oferta, nuevo color, nuevo texto)
        ↓                                                 │
8. Usuario acepta o rechaza → se guarda en historial → Bandit aprende ┘
```

---

## Estructura del Proyecto

Estructura objetivo del proyecto Flutter (pendiente de scaffolding — ver [Estado del módulo de detección de emociones](#estado-del-módulo-de-detección-de-emociones)):

```
tienda_adaptativa/
│
├── lib/                                        # FLUTTER / DART - App principal
│   ├── main.dart                               # Punto de entrada
│   │
│   ├── data/                                   # CAPA DE DATOS
│   │   ├── database/
│   │   │   └── app_database.dart              # Configuración SQLite (sqflite)
│   │   ├── models/
│   │   │   ├── user.dart                       # Modelo de usuario
│   │   │   ├── product.dart                    # Modelo de producto
│   │   │   ├── offer.dart                      # Modelo de oferta adaptativa
│   │   │   └── emotion_history.dart            # Modelo de historial
│   │   └── repositories/
│   │       ├── user_repository.dart            # Lógica de acceso a usuarios
│   │       └── product_repository.dart         # Lógica de acceso a productos/ofertas
│   │
│   ├── decision/                               # FASE 3: DECISIÓN
│   │   ├── adaptation_engine.dart              # Motor de reglas + autenticación
│   │   └── learning/
│   │       └── bandit_optimizer.dart           # Aprendizaje Multi-Armed Bandit
│   │
│   ├── services/                               # PUENTE HACIA EL MÓDULO NATIVO
│   │   └── emotion_channel.dart                # Wrapper del Platform Channel
│   │
│   └── ui/                                     # CAPA DE PRESENTACIÓN (FASE 4: ADAPTACIÓN)
│       ├── screens/
│       │   ├── main_screen.dart                # Registro / Login
│       │   ├── product_detail_screen.dart      # Pantalla principal adaptativa
│       │   └── history_screen.dart             # Historial de interacciones
│       ├── widgets/
│       │   └── dynamic_offer_card.dart         # Tarjeta de oferta reactiva
│       └── theme/
│           └── adaptive_theme.dart             # Tema visual adaptativo
│
├── android/                                    # MÓDULO NATIVO (FASES 1 Y 2 DEL PIPELINE)
│   └── app/src/main/
│       ├── kotlin/com/tuapp/tiendaadaptativa/
│       │   ├── context/                        # FASE 1: CONTEXTO
│       │   │   ├── CameraManager.kt            # Control de cámara y permisos
│       │   │   └── EmotionDetector.kt          # Detección facial + clasificación
│       │   ├── processing/                     # FASE 2: PROCESAMIENTO
│       │   │   └── EmotionProcessor.kt         # Filtro de estabilidad (N frames)
│       │   └── channel/
│       │       └── EmotionChannelHandler.kt    # Expone el pipeline nativo a Flutter
│       └── assets/
│           └── emotion_model.tflite            # Modelo FER-2013
│
└── pubspec.yaml                                # Dependencias Flutter/Dart
```

---

## Tabla de Ubicación del Pipeline

| Elemento del Pipeline | Archivo / Clase | Lenguaje |
|-----------------------|-----------------|----------|
| **Captura del contexto** | `context/CameraManager.kt` | Kotlin (nativo) |
| **Detección de emoción** | `context/EmotionDetector.kt` | Kotlin (nativo) |
| **Procesamiento** | `processing/EmotionProcessor.kt` | Kotlin (nativo) |
| **Puente Flutter ↔ Kotlin** | `channel/EmotionChannelHandler.kt` / `lib/services/emotion_channel.dart` | Kotlin + Dart |
| **Decisión** | `lib/decision/adaptation_engine.dart` | Dart (Flutter) |
| **Aprendizaje** | `lib/decision/learning/bandit_optimizer.dart` | Dart (Flutter) |
| **Adaptación (UI)** | `lib/ui/widgets/dynamic_offer_card.dart` | Dart (Flutter) |
| **Adaptación (Tema)** | `lib/ui/theme/adaptive_theme.dart` | Dart (Flutter) |
| **Persistencia** | `lib/data/database/`, `lib/data/repositories/` | Dart (Flutter) |

---

## Estado del módulo de detección de emociones

La rama `feature/emotion-detector` mantiene la implementación nativa Kotlin de las fases de contexto y procesamiento. Es el único código del proyecto con lógica real ya escrita, por lo que se conserva tal cual y se expondrá a Flutter mediante un Platform Channel en lugar de reescribirse en Dart.

| Archivo | Implementación |
|---------|----------------|
| `context/EmotionDetector.kt` | Detección de rostro con ML Kit, recorte facial, preprocesamiento 48×48 en escala de grises, inferencia TensorFlow Lite y generación de `EmotionResult` |
| `processing/EmotionProcessor.kt` | Buffer de 10 frames, confirmación de emoción estable y cálculo de confianza promedio |

El modelo utilizado por `EmotionDetector.kt` se incluye como recurso Android en:

```text
app/src/main/assets/emotion_model.tflite
```

`assets` almacena únicamente el archivo del modelo y no agrega una nueva capa ni modifica la organización de paquetes Kotlin mostrada arriba.

El modelo utiliza siete clases FER-2013 (`angry`, `disgust`, `fear`, `happy`, `sad`, `surprise`, `neutral`) y `EmotionDetector.kt` las adapta a las emociones utilizadas por el proyecto: `enojo`, `feliz`, `triste`, `sorpresa` y `neutral`. Cuando ML Kit no encuentra un rostro, devuelve `no_face`.

Pendiente:

- Inicializar el proyecto Flutter (`pubspec.yaml`, `lib/`) y mover el módulo Kotlin existente a `android/app/src/main/kotlin/...`.
- Implementar `EmotionChannelHandler.kt` y `lib/services/emotion_channel.dart` para conectar el pipeline nativo con la capa Dart.
- Escribir en Dart todo lo que hoy son clases esqueleto (`AdaptationEngine`, `BanditOptimizer`, `AppDatabase`, repositorios, pantallas UI).

---

## Algoritmo de Aprendizaje: Multi-Armed Bandit

El sistema no solo sigue reglas fijas, sino que **aprende** con el tiempo (implementado en Dart, dentro de `lib/decision/learning/bandit_optimizer.dart`):

```
Para cada emoción, se mantiene un registro de:
  - Cuántas veces se mostró cada oferta
  - Cuántas veces fue aceptada
  - Cuántas veces fue rechazada

Se usa UCB1 (Upper Confidence Bound) para balancear:
  - EXPLORACIÓN: probar ofertas que no se han mostrado mucho
  - EXPLOTACIÓN: usar la oferta que mejor funciona

Fórmula: score = (éxitos / total) + √(2 × ln(N) / total)
```

**Ejemplo de evolución:**

| Emoción | Oferta | Éxitos | Fracasos | Score UCB1 |
|---------|--------|--------|----------|------------|
| Triste | Audífonos | 5 | 2 | 2.45 |
| Triste | Mouse | 1 | 6 | 0.72 |
| Triste | Teclado | 3 | 3 | 1.68 |

→ El sistema favorecerá Audífonos para usuarios tristes.

---

## Requisitos

- **Flutter SDK** (última versión estable)
- **Dart SDK** (incluido con Flutter)
- **JDK 17** (para compilar el módulo nativo Android vía Gradle, usado internamente por Flutter)
- **VS Code** + extensiones Flutter y Dart — no se usa Android Studio
- **Celular Android** con Android 8.0+ (API 26+) y cámara frontal
- **Git**

---

## Instalación y Ejecución

```bash
# 1. Clonar el repositorio
git clone https://github.com/StevenCadilloS/Sistema-Inteligente-Ventas.git

# 2. Abrir la carpeta en VS Code
code Sistema-Inteligente-Ventas

# 3. Instalar las dependencias de Flutter
flutter pub get

# 4. Conectar el celular Android vía USB (con depuración USB activada)
flutter devices

# 5. Ejecutar la app
flutter run
```

---

## Permisos Requeridos

| Permiso | Razón |
|---------|-------|
| `CAMERA` | Capturar video para detectar emociones |

---

## Cómo Demostrar la Adaptación

### Con el celular:

1. **Abrir la app** → registrarse
2. **Mostrar cara** → la app detecta emoción y muestra oferta
3. **Cambiar expresión** → la oferta cambia automáticamente
4. **Aceptar/rechazar** → el sistema registra y aprende
5. **Ver historial** → muestra estadísticas de emociones y aceptaciones

### Comandos para demostrar sensores y revisar logs:

```bash
# Simular batería baja (cambia modo visual)
adb shell dumpsys battery set level 10

# Restaurar batería
adb shell dumpsys battery reset

# Ver logs de la app Flutter
flutter logs

# Ver logs específicos del módulo nativo de emociones
adb logcat | grep "EmotionDetector"
```

---

## Tecnologías y Versiones

| Dependencia | Versión | Uso |
|-------------|---------|-----|
| Flutter | 3.x | Framework principal de la app |
| Dart | 3.x | Lenguaje de la capa Flutter |
| Kotlin | 1.9.x | Módulo nativo (cámara, ML Kit, TensorFlow Lite) |
| sqflite | 2.x | Base de datos SQLite en Dart |
| CameraX | 1.3.x | Captura de cámara (Kotlin) |
| ML Kit Face Detection | 16.x | Detección de rostro (Kotlin) |
| TensorFlow Lite | 2.14.x | Clasificación de emociones (Kotlin) |
| provider / get_it | última | Inyección de dependencias (Dart) |

---

## Créditos

- **Dataset de emociones**: [FER-2013](https://www.kaggle.com/datasets/msambare/fer2013) (Facial Expression Recognition)
- **Modelo TensorFlow Lite**: `maftuh-main/meme-emotion-detector` (MIT)
- **Modelo de detección facial**: Google ML Kit
- **Algoritmo de aprendizaje**: Multi-Armed Bandit con UCB1

---

## Licencia

Proyecto académico — Universidad Nacional de Ingeniería, Ciclo 2026-2.
