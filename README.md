# Sistema Inteligente de Ventas — Modelo binario

> Rama: `arbol-5.1(MODELO-BINARIO)`

## Descargar APK

[Descargar APK del modelo binario](https://github.com/StevenCadilloS/Sistema-Inteligente-Ventas/releases/download/arbol-5-1-modelo-binario-latest/Sistema-Inteligente-Ventas-modelo-binario.apk)

[Descargar APK solo para probar el detector](https://github.com/StevenCadilloS/Sistema-Inteligente-Ventas/releases/download/arbol-5-1-modelo-binario-latest/Sistema-Inteligente-Ventas-solo-detector.apk)

Cada actualización de esta rama ejecuta las pruebas, compila las versiones
release y debug, y reemplaza la descarga permanente. La ejecución también se
puede iniciar manualmente desde
[GitHub Actions](https://github.com/StevenCadilloS/Sistema-Inteligente-Ventas/actions/workflows/build-arbol-5-1-binario-apk.yml).

> La descarga aparecerá cuando la primera ejecución termine correctamente. Si
> los secretos `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` no están configurados
> en GitHub, la APK normal mostrará la pantalla de backend faltante. Desde esa
> pantalla se puede pulsar **Probar detector sin backend**. La APK **solo
> detector** abre la prueba directamente y nunca necesita esos secretos.

### Probar únicamente el detector

Instala `Sistema-Inteligente-Ventas-solo-detector.apk`. Esta variante:

- abre la cámara frontal directamente;
- muestra favorable, desfavorable, incierto o sin rostro;
- muestra la probabilidad de sonrisa y la confianza en tiempo real;
- avisa si el rostro está lejos, girado o fuera del encuadre;
- funciona sin Supabase y sin conexión a internet;
- no guarda ni envía imágenes.

La APK de prueba y la APK normal comparten identificador Android, por lo que no
se instalan simultáneamente: una reemplaza a la otra.

Aplicación Android (Flutter + Kotlin) que clasifica la respuesta facial del
cliente con la cámara frontal y la usa para avanzar por una secuencia de
ofertas que un administrador configuró antes.

> **La respuesta facial no calcula el descuento.** Decide si el sistema se queda donde
> está o pasa al siguiente escalón de una escalera que vive en la base de
> datos. La app no inventa precios.

---

## Descripción

El problema: mostrar la oferta correcta, en el momento correcto, sin regalar
margen ni depender de que el cliente pulse "ver ofertas".

Cómo funciona:

1. El cliente navega el catálogo con la **cámara apagada**
2. Al **seleccionar un producto** empieza la interacción y se enciende la cámara
3. Se muestra el **precio normal** y se observa su respuesta durante unos segundos
4. Respuesta **favorable** → se mantiene el precio. **Desfavorable** → se avanza al siguiente escalón
5. La interacción termina al comprar, al abandonar o al agotarse la escalera. La cámara **se apaga**

### Ejemplo de escalera

```
Laptop Lenovo IdeaPad — S/2500.00

  precio normal   S/2500.00   ← empieza aquí
  orden 1 → 10%   S/2250.00
  orden 2 → 20%   S/2000.00
  orden 3 → 30%   S/1750.00   ← último escalón
```

Los descuentos, su orden y su vigencia los define una persona desde el panel,
no el código.

### Clasificación de la respuesta

| Resultado | Criterio | Efecto |
|---|---|---|
| **Favorable** | Sonrisa ≥ 65% | Mantiene el precio actual |
| **Desfavorable** | Sonrisa ≤ 35% | Avanza un escalón |
| **Incierto** | Zona intermedia, mala pose o rostro pequeño | No hace nada |
| **Sin señal** | `no_face` | No hace nada |

Se cuentan votos en una ventana de observación, no una sola lectura. La franja
incierta evita convertir una lectura ambigua en descuento.

### Detector binario

Esta rama reemplaza el antiguo clasificador FER-2013 de cinco emociones por un
detector binario alineado con la decisión que realmente necesita la tienda:

```text
CameraX
  → ML Kit detecta el rostro y sus puntos faciales
  → valida tamaño y posición de la cabeza
  → obtiene smilingProbability
  → favorable / desfavorable / incierto
  → EmotionProcessor estabiliza 12 fotogramas
  → EventChannel entrega el resultado a Flutter
```

El detector no afirma conocer el estado emocional interno de una persona.
Interpreta una señal facial observable —principalmente la probabilidad de
sonrisa— como respuesta comercial favorable o desfavorable. Esta distinción es
importante: ausencia de sonrisa no demuestra tristeza, enojo ni rechazo.

#### Controles de calidad

| Control | Valor actual | Motivo |
|---|---:|---|
| Rostro mínimo | 96 × 96 px | Evitar clasificar caras sin suficiente detalle |
| Yaw máximo | ±18° | ML Kit clasifica mejor rostros frontales |
| Roll máximo | ±18° | Evitar lecturas con la cabeza inclinada |
| Pitch máximo | ±20° | Evitar lecturas mirando demasiado arriba o abajo |
| Umbral favorable | ≥ 0.65 | Exigir una sonrisa suficientemente clara |
| Umbral desfavorable | ≤ 0.35 | Exigir ausencia suficientemente clara de sonrisa |
| Zona incierta | 0.35–0.65 | No forzar señales ambiguas |
| Ventana nativa | 12 fotogramas | Filtrar parpadeos sin introducir mucha demora |
| Observación en Flutter | 3 segundos | Reunir varias lecturas estables antes de decidir |

Los parámetros del primer bloque están centralizados en
`BinaryResponseClassifier.kt`. No deben ajustarse usando solamente una persona:
hay que probar distintas personas, distancias, tonos de piel, gafas y
condiciones de iluminación.

---

## Estado actual

| Parte | Estado |
|---|---|
| Backend: esquema, funciones validadas, RLS, Storage | ✅ 7 migraciones, 3 suites SQL sobre PostgreSQL real |
| Identidad: registro e ingreso con Supabase Auth | ✅ Cada cliente ve solo sus compras |
| Motor de negociación (escalera de ofertas) | ✅ Pruebas Dart incluidas |
| Detección facial y clasificación binaria (Kotlin nativo) | ✅ ML Kit, en el dispositivo |
| Pruebas del clasificador y estabilizador binario | ✅ Pruebas JVM incluidas |
| Puente Flutter ↔ Kotlin | ✅ EventChannel, degrada donde no hay detector |
| Pantallas: login, tienda, historial | ✅ |
| Catálogo de demostración | ✅ 20 productos en 7 categorías |
| Imágenes de producto | ⏳ El bucket existe; faltan subir las fotos |

---

## Cómo se reparte el trabajo

| Vive en el APK (celular) | Vive en el servidor |
|---|---|
| Las pantallas | El catálogo, precios y stock |
| **La clasificación de respuesta facial** (sin subir imágenes) | Las ofertas y **su orden** |
| Decidir *cuándo* pedir el siguiente escalón | El registro de ventas |
| | Las reglas: límite diario, stock, que el total cuadre |

La cámara nunca sale del teléfono: lo que viaja por la red es "dame las ofertas
del producto 3", con el token que dice quién pregunta.

**El APK solo puede leer.** Su clave va dentro del paquete y cualquiera la
extrae, así que las escrituras pasan por funciones que validan las reglas.
`fn_registrar_venta` no recibe ni el precio (lo recalcula) ni el id del cliente
(lo saca del token).

---

## Reglas de negocio

1. **La cámara solo se enciende durante una interacción** con un producto seleccionado
2. **Se apaga automáticamente** al terminar
3. **El precio normal se muestra primero**; la primera oferta se juega cuando el cliente no responde bien
4. **Las ofertas se muestran solas**, sin botón
5. **Un cliente puede usar ofertas solo en sus dos primeras compras del día** — se cuentan las compras, no las que llevaron oferta
6. **No todos los productos tienen ofertas**: sin escalera, el precio no se mueve
7. **Las ofertas respetan su orden, vigencia y estado activo**
8. **La interacción termina** al comprar, al abandonar o al agotarse la escalera

---

## Stack tecnológico

| Componente | Tecnología |
|---|---|
| Framework | Flutter 3.47.x (Dart 3.13.x) |
| Módulo nativo | Kotlin — CameraX y ML Kit |
| Base de datos | PostgreSQL vía [Supabase](https://supabase.com) (Apache-2.0, autohospedable) |
| Identidad | Supabase Auth — bcrypt en un esquema al que la app no accede |
| Tiempo real | Supabase Realtime (WebSocket) |
| Imágenes | Supabase Storage, bucket público de lectura |
| Administración | Panel de Supabase (Table Editor) |
| Sesión | El SDK de Supabase, en el almacenamiento seguro del dispositivo |

---

## Arquitectura

```
CONTEXTO → PROCESAMIENTO → DECISIÓN → ADAPTACIÓN
```

Las dos primeras fases corren en **Kotlin** (son las que necesitan APIs de
Android); las dos últimas en **Dart**.

```
┌──────────────── CELULAR ────────────────┐     ┌──── SERVIDOR ────┐
│                                          │     │                  │
│  CameraX ──> ML Kit (clasif. binaria)     │     │  v_catalogo      │
│                   │                      │     │  v_secuencia_    │
│                   v                      │     │    ofertas       │
│         EmotionProcessor                 │     │                  │
│    (12 frames para estabilizar)          │     │  fn_ofertas_de   │
│                   │                      │     │  fn_registrar_   │
│          EventChannel                    │     │    venta         │
│                   │                      │     │  fn_historial    │
│                   v                      │     │                  │
│   ClasificadorRespuesta ──> Negociacion  │<───>│  RLS en las 10   │
│         (votos)         (puntero sobre   │     │  tablas          │
│                          la escalera)    │     │                  │
└──────────────────────────────────────────┘     └──────────────────┘
```

---

## Estructura del proyecto

```
├── lib/
│   ├── main.dart                                 arranque y rutas
│   ├── data/
│   │   ├── modelos/modelos.dart                  Producto, EscalonOferta, CompraHistorial
│   │   ├── remote/
│   │   │   ├── supabase_config.dart              URL y clave, inyectadas al compilar
│   │   │   └── sesion_service.dart               registro, ingreso, recuperar clave
│   │   └── repositories/
│   │       ├── tienda_repository.dart            el puerto: lo que la app pide al backend
│   │       └── supabase_tienda_repository.dart   PostgREST + RPC + Realtime
│   ├── decision/
│   │   └── negociacion.dart                      ClasificadorRespuesta y Negociacion
│   ├── services/emotion_channel.dart             puente con el módulo nativo
│   └── ui/                                       login, tienda, historial y widgets
│
├── android/app/src/main/
│   ├── kotlin/com/tuapp/tienda_adaptativa/
│   │   ├── context/CameraManager.kt              FASE 1: captura
│   │   ├── context/EmotionDetector.kt            integración con ML Kit
│   │   ├── context/BinaryResponseClassifier.kt   umbrales, pose y clase binaria
│   │   ├── context/EmotionResult.kt               contrato de resultados
│   │   ├── processing/EmotionProcessor.kt        FASE 2: filtro de estabilidad
│   │   └── channel/EmotionChannelHandler.kt      expone el pipeline a Flutter
│   └── assets/emotion_model.tflite               legado, ya no se carga
│
├── supabase/
│   ├── migrations/                               0001 a 0007
│   ├── tests/                                    3 suites SQL + ejecutar.sh
│   └── README.md                                 guía del backend y administración
│
└── test/                                         46 pruebas Dart
```

---

## Requisitos

| | |
|---|---|
| Flutter SDK | 3.47.x (incluye Dart 3.13.x) |
| JDK | 17 o superior |
| Android SDK | platform-tools, `platforms;android-36`, `build-tools;36.0.0` |
| Celular | Android 8.0+ (API 26) con cámara frontal |
| Backend | Un proyecto en supabase.com (plan gratuito) |

Los detalles están en [requirements.txt](requirements.txt).

---

## Instalación

```bash
# 1. Clonar
git clone https://github.com/StevenCadilloS/Sistema-Inteligente-Ventas.git
cd Sistema-Inteligente-Ventas
git switch "arbol-5.1(MODELO-BINARIO)"

# 2. Dependencias de Flutter
flutter pub get

# 3. Backend: crear el proyecto en Supabase y aplicar las 7 migraciones
#    de supabase/migrations/ en orden (ver supabase/README.md)

# 4. Credenciales: copiar env.example.json a env.json y poner ahí la URL y
#    la publishable key del proyecto
cp env.example.json env.json

# 5. Pruebas Dart (no necesitan celular, emulador ni backend)
flutter test

# 6. Compilar Android: también valida el código Kotlin del detector
flutter build apk --debug --dart-define-from-file=env.json

# 7. Ejecutar
flutter run --dart-define-from-file=env.json              # en celular
flutter run -d chrome --dart-define-from-file=env.json    # en navegador
```

> En navegador funciona el catálogo, el login y la compra, pero **no la
> clasificación de respuesta facial**: es un módulo nativo de Android. La negociación se
> queda en el precio normal.

### Pruebas del backend

```bash
bash supabase/tests/ejecutar.sh    # necesita podman, docker o psql
```

---

## Permisos

| Permiso | Para qué |
|---|---|
| `CAMERA` | Leer la respuesta del cliente durante una negociación |
| `INTERNET` | Consultar el catálogo y registrar las ventas |

La cámara se pide al iniciar la primera interacción, no al abrir la app.

---

## Cómo demostrar la adaptación

1. Entrar con una cuenta y seleccionar la **Laptop Lenovo IdeaPad** (tiene los tres escalones)
2. Mantener el rostro frontal y sin sonreír → la respuesta puede clasificarse como desfavorable
3. Sonreír claramente → se clasifica como favorable y mantiene el precio
4. Pulsar **"No, gracias"** → avanza al siguiente escalón, igual que una cara desfavorable
5. Seleccionar la **Laptop HP Pavilion** → no tiene ofertas, el precio no se mueve pase lo que pase

Durante la prueba, una mala pose, un rostro lejano o una probabilidad intermedia
debe mostrarse como **Lectura incierta** y no debe avanzar la oferta.

Para ver el límite diario: comprar dos veces y seleccionar un tercer producto.
La escalera viene vacía y todo se queda a precio normal.

Para ver el tiempo real: cambiar un precio o un stock desde el panel de
Supabase y mirar cómo se actualiza en el celular sin refrescar.

---

## Administración

El **Table Editor** de Supabase es la vista de administración: alta de
productos, publicación de ofertas, reposición de stock y subida de imágenes,
todo sin recompilar el APK.

El procedimiento está en [supabase/README.md](supabase/README.md).
