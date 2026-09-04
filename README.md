# Sistema Inteligente de Ventas - Tienda Adaptativa

Aplicación Android nativa que detecta emociones faciales en tiempo real y adapta automáticamente las ofertas comerciales para maximizar la persuasión de ventas.

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

## Stack Tecnológico

| Componente | Tecnología | Propósito |
|------------|------------|-----------|
| **Lenguaje** | Kotlin | Desarrollo Android nativo |
| **UI** | Jetpack Compose | Interfaz declarativa moderna |
| **Base de datos** | Room (SQLite) | Persistencia local (usuarios, productos, historial) |
| **Cámara** | CameraX | Captura de video en tiempo real |
| **Detección facial** | Google ML Kit | Detectar rostro y landmarks faciales |
| **Clasificación de emociones** | TensorFlow Lite (FER-2013) | Clasificar emoción desde imagen de cara |
| **Aprendizaje** | Multi-Armed Bandit (UCB1) | Seleccionar la mejor oferta según historial |
| **Arquitectura** | Clean Architecture + Pipeline | Separación de responsabilidades |
| **DI** | Hilt (o inyección manual) | Conectar componentes sin acoplamiento |

---

## Arquitectura del Sistema

El sistema sigue el **pipeline adaptativo obligatorio** del curso:

```
CONTEXTO → PROCESAMIENTO → DECISIÓN → ADAPTACIÓN
```

### Diagrama de componentes

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PIPELINE ADAPTATIVO                          │
├─────────────┬──────────────┬────────────────┬──────────────────────┤
│  CONTEXTO   │ PROCESAMIENTO│    DECISIÓN    │     ADAPTACIÓN      │
│             │              │                │                      │
│ CameraManager│EmotionProcessor│ AdaptationEngine│ DynamicOfferCard  │
│ EmotionDetector│ (estabiliza)│ BanditOptimizer│ Theme (colores)    │
│             │              │                │ ProductRepository   │
├─────────────┼──────────────┼────────────────┼──────────────────────┤
│ CameraX     │ Buffer N     │ Reglas de      │ UI Cambia sola      │
│ ML Kit      │ frames       │ negocio +      │ Colores, ofertas,   │
│ TFLite      │              │ Aprendizaje    │ textos              │
└─────────────┴──────────────┴────────────────┴──────────────────────┘
```

### Flujo de ejecución completo

```
1. Cámara captura frame (30 fps)
        ↓
2. ML Kit detecta cara en el frame
        ↓
3. TFLite clasifica emoción (triste/feliz/sorpresa/neutral/enojo)
        ↓
4. EmotionProcessor estabiliza (exige N frames consecutivos)
        ↓
5. AdaptationEngine aplica reglas según emoción
        ↓
6. BanditOptimizer selecciona mejor oferta (exploración vs explotación)
        ↓
7. UI se actualiza automáticamente (nueva oferta, nuevo color, nuevo texto)
        ↓
8. Usuario acepta o rechaza → se guarda en historial → Bandit aprende
```

---

## Estructura del Proyecto

```
app/src/main/java/com/tuapp/tiendaadaptativa/
│
├── data/                              # CAPA DE DATOS
│   ├── database/
│   │   ├── AppDatabase.kt            # Configuración Room/SQLite
│   │   └── dao/
│   │       ├── UserDao.kt            # Consultas de usuarios
│   │       ├── ProductDao.kt         # Consultas de productos
│   │       ├── OfferDao.kt           # Consultas de ofertas
│   │       └── EmotionDao.kt         # Consultas de historial
│   ├── models/
│   │   ├── User.kt                   # Modelo de usuario
│   │   ├── Product.kt                # Modelo de producto
│   │   ├── Offer.kt                  # Modelo de oferta adaptativa
│   │   └── EmotionHistory.kt         # Modelo de historial
│   └── repositories/
│       ├── UserRepository.kt         # Lógica de acceso a usuarios
│       └── ProductRepository.kt      # Lógica de acceso a productos/ofertas
│
├── context/                          # FASE 1: CAPTURA DEL CONTEXTO
│   ├── CameraManager.kt             # Control de cámara y permisos
│   └── EmotionDetector.kt           # Detección facial + clasificación
│
├── processing/                       # FASE 2: PROCESAMIENTO
│   └── EmotionProcessor.kt          # Filtro de estabilidad (N frames)
│
├── decision/                         # FASE 3: DECISIÓN
│   ├── AdaptationEngine.kt          # Motor de reglas de adaptación
│   └── learning/
│       └── BanditOptimizer.kt       # Aprendizaje Multi-Armed Bandit
│
├── ui/                               # CAPA DE PRESENTACIÓN
│   ├── MainActivity.kt              # Registro / Login de usuario
│   ├── ProductDetailActivity.kt     # Pantalla principal adaptativa
│   ├── HistoryActivity.kt           # Historial de interacciones
│   ├── components/
│   │   └── DynamicOfferCard.kt      # Tarjeta de oferta reactiva
│   └── theme/
│       └── Theme.kt                 # Tema visual adaptativo
│
└── di/                               # INYECCIÓN DE DEPENDENCIAS
    └── AppModule.kt                  # Módulo de configuración
```

---

## Tabla de Ubicación del Pipeline

| Elemento del Pipeline | Archivo / Clase |
|-----------------------|-----------------|
| **Captura del contexto** | `context/CameraManager.kt` |
| **Detección de emoción** | `context/EmotionDetector.kt` |
| **Procesamiento** | `processing/EmotionProcessor.kt` |
| **Decisión** | `decision/AdaptationEngine.kt` |
| **Aprendizaje** | `decision/learning/BanditOptimizer.kt` |
| **Adaptación (UI)** | `ui/components/DynamicOfferCard.kt` |
| **Adaptación (Tema)** | `ui/theme/Theme.kt` |
| **Persistencia** | `data/database/`, `data/repositories/` |

---

## Estado del módulo de detección de emociones

La rama `feature/emotion-detector` mantiene la estructura original del proyecto y concentra la implementación en los archivos ya definidos para las fases de contexto y procesamiento.

| Archivo | Implementación |
|---------|----------------|
| `context/EmotionDetector.kt` | Detección de rostro con ML Kit, recorte facial, preprocesamiento 48×48 en escala de grises, inferencia TensorFlow Lite y generación de `EmotionResult` |
| `processing/EmotionProcessor.kt` | Buffer de 10 frames, confirmación de emoción estable y cálculo de confianza promedio |

El modelo utilizado por `EmotionDetector.kt` se incluye como recurso Android en:

```text
app/src/main/assets/emotion_model.tflite
```

`assets` almacena únicamente el archivo del modelo y no agrega una nueva capa ni modifica la organización de paquetes Java/Kotlin mostrada arriba.

El modelo utiliza siete clases FER-2013 (`angry`, `disgust`, `fear`, `happy`, `sad`, `surprise`, `neutral`) y `EmotionDetector.kt` las adapta a las emociones utilizadas por el proyecto: `enojo`, `feliz`, `triste`, `sorpresa` y `neutral`. Cuando ML Kit no encuentra un rostro, devuelve `no_face`.

La integración y prueba completa en un dispositivo Android queda pendiente de contar con la configuración Gradle/Manifest necesaria para compilar el proyecto completo.

---

## Algoritmo de Aprendizaje: Multi-Armed Bandit

El sistema no solo sigue reglas fijas, sino que **aprende** con el tiempo:

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

- **Android Studio** (última versión)
- **JDK 17** (viene con Android Studio)
- **Celular Android** con Android 8.0+ (API 26+) y cámara frontal
- **Git**

---

## Instalación y Ejecución

```bash
# 1. Clonar el repositorio
git clone https://github.com/tu-usuario/sistema-inteligente-ventas.git

# 2. Abrir en Android Studio
# File → Open → seleccionar la carpeta sistema-inteligente-ventas

# 3. Esperar a que Gradle sincronice las dependencias

# 4. Conectar celular Android vía USB (con depuración USB activada)

# 5. Ejecutar ▶️
# Seleccionar tu celular como dispositivo de destino
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

### Comandos adb (para demostrar sensores):

```bash
# Simular batería baja (cambia modo visual)
adb shell dumpsys battery set level 10

# Restaurar batería
adb shell dumpsys battery reset

# Ver logs de la app
adb logcat | grep "EmotionDetector"
```

---

## Tecnologías y Versiones

| Dependencia | Versión | Uso |
|-------------|---------|-----|
| Kotlin | 1.9.x | Lenguaje principal |
| Jetpack Compose | 1.5.x | UI declarativa |
| Room | 2.6.x | Base de datos SQLite |
| CameraX | 1.3.x | Captura de cámara |
| ML Kit Face Detection | 16.x | Detección de rostro |
| TensorFlow Lite | 2.14.x | Clasificación de emociones |
| Hilt | 2.48.x | Inyección de dependencias |

---

## Créditos

- **Dataset de emociones**: [FER-2013](https://www.kaggle.com/datasets/msambare/fer2013) (Facial Expression Recognition)
- **Modelo TensorFlow Lite**: `maftuh-main/meme-emotion-detector` (MIT)
- **Modelo de detección facial**: Google ML Kit
- **Algoritmo de aprendizaje**: Multi-Armed Bandit con UCB1

---

## Licencia

Proyecto académico — Universidad Nacional de Ingeniería, Ciclo 2026-2.
