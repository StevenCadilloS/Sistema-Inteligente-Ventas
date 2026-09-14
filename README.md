# Sistema Inteligente de Ventas - Tienda Adaptativa

Aplicación Android (Flutter + Kotlin) que lee la respuesta emocional del
cliente con la cámara frontal y la usa para avanzar por una secuencia de
ofertas que un administrador configuró antes.

> **La emoción no calcula el descuento.** Decide si el sistema se queda donde
> está o pasa al siguiente escalón de una escalera que vive en la base de
> datos. La app no inventa precios.

---

## APK automática

Cada push a una rama de trabajo ejecuta las pruebas, compila la APK y
actualiza su descarga permanente:

| Rama | Descarga |
|---|---|
| `arbol5-modelo-ofertas` | [APK más reciente](https://github.com/StevenCadilloS/Sistema-Inteligente-Ventas/releases/download/arbol5-modelo-ofertas-latest/Sistema-Inteligente-Ventas-arbol5-modelo-ofertas.apk) |
| `steven1.1` | [APK más reciente](https://github.com/StevenCadilloS/Sistema-Inteligente-Ventas/releases/download/steven1-1-latest/Sistema-Inteligente-Ventas-steven1-1.apk) |

### Secretos del repositorio

Todos en **Settings → Secrets and variables → Actions**. Los dos primeros son
imprescindibles; sin los otros tres la APK se compila igual, pero pierde
funciones:

| Secreto | De dónde sale | Si falta |
|---|---|---|
| `SUPABASE_URL` | Project Settings → API → *Project URL* | La app arranca en la pantalla de "falta el backend" |
| `SUPABASE_PUBLISHABLE_KEY` | Project Settings → API → *publishable key* (o *anon public*) | Igual que el anterior |
| `SUPABASE_SERVICE_KEY` | Project Settings → API → *service_role* | No se avisa de versiones nuevas (ver abajo) |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w 0 android/app/upload-keystore.jks` | La APK no se puede instalar como actualización |
| `ANDROID_KEYSTORE_PASSWORD` | La contraseña del keystore | Igual que el anterior |

La `service_role` key ignora todas las políticas de seguridad, así que **solo**
vive aquí: la usa el runner para escribir en `app_config`, nunca viaja dentro
de la APK. Lo que sí va en la APK es la publishable key, que solo concede
lectura.

### Firma de la APK

Las APK se firman con una clave fija que el runner reconstruye desde
`ANDROID_KEYSTORE_BASE64`. No es un detalle administrativo: Android solo
instala una APK encima de otra si ambas comparten firma. Antes se firmaba con
la clave de depuración, que cada máquina genera sola —cada runner arrancaba
limpio y producía una firma distinta—, así que cada actualización obligaba a
desinstalar primero.

El keystore **no está en git** (ver `android/.gitignore`). Quien clone el
repositorio sin él compila con la clave de depuración: sirve para probar en
local, no para distribuir. **La APK que se instala siempre sale de la release
de GitHub**, no del build local de nadie, o cada quien tendría una firma
distinta.

> Guardar un respaldo del keystore fuera de git (Drive del equipo, gestor de
> contraseñas). GitHub no deja volver a leer un secreto una vez guardado: si se
> pierde la única copia, no se puede publicar ninguna actualización instalable
> sobre las ya instaladas.

### Aviso de actualización

Al terminar cada build, el workflow escribe en la tabla `app_config` el commit
con el que se compiló y la URL de descarga. La app compara ese valor contra el
suyo —inyectado al compilar— al arrancar y al volver de segundo plano, y
muestra una franja con botón **Actualizar** cuando no coinciden.

Una APK compilada sin `BUILD_SHA` (un `flutter run` local) no avisa de nada: no
tiene con qué compararse.

---

## Descripción

El problema: mostrar la oferta correcta, en el momento correcto, sin regalar
margen ni depender de que el cliente pulse "ver ofertas".

Cómo funciona:

1. El cliente navega el catálogo con la **cámara apagada**
2. Al **seleccionar un producto** empieza la interacción y se enciende la cámara
3. Se muestra el **precio normal** y se observa su respuesta durante unos segundos
4. Respuesta **favorable** → se mantiene el precio. **Desfavorable** → se avanza al siguiente escalón
5. La interacción termina al **agregar al carrito**, al abandonar o al agotarse la escalera. La cámara **se apaga**
6. El precio acordado queda **congelado en la línea del carrito**: lo que se vio en pantalla es lo que se cobra
7. Confirmar el carrito es **una sola venta con N líneas**, y es ahí donde se consume la oportunidad de oferta del día

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

| Grupo | Emociones | Efecto |
|---|---|---|
| **Favorable** | `feliz`, `sorpresa` | Mantiene el precio actual |
| **Desfavorable** | `neutral`, `triste`, `enojo` | Avanza un escalón |
| **Sin señal** | `no_face`, o menos de 2 lecturas | No hace nada |

Se cuentan votos en una ventana de observación, no una sola lectura. `neutral`
cuenta como desfavorable por decisión de producto — conviene saber que eso hace
que la mayoría de clientes vea avanzar la escalera, porque la cara en reposo
frente a una pantalla suele clasificarse así.

---

## Estado actual

| Parte | Estado |
|---|---|
| Backend: esquema, funciones validadas, RLS, Storage | ✅ 14 migraciones, 3 suites SQL sobre PostgreSQL real |
| Identidad: registro e ingreso con Supabase Auth | ✅ Cada cliente ve solo sus compras |
| Motor de negociación (escalera de ofertas) | ✅ 158 pruebas Dart |
| Detección facial y clasificación (Kotlin nativo) | ✅ ML Kit + TensorFlow Lite, en el dispositivo |
| Puente Flutter ↔ Kotlin | ✅ EventChannel, degrada donde no hay detector |
| Pantallas: login, tienda, historial | ✅ |
| Carrito y detalle de venta | ✅ Una confirmacion = una venta con N lineas, precio congelado por linea |
| Catálogo de demostración | ✅ 50 productos en 8 categorías, con escaleras de oferta mixtas |
| Imágenes de producto | ✅ 16 fotos en el bucket; los otros 34 caen al icono de su categoría |
| Stock en tiempo real entre dispositivos | ✅ Realtime + relectura al volver de segundo plano |
| Productos agotados | ✅ Se quedan en el feed con franja "AGOTADO", no se pueden seleccionar |
| Aviso de versión nueva dentro de la app | ✅ Franja con botón *Actualizar* (ver arriba) |

---

## Cómo se reparte el trabajo

| Vive en el APK (celular) | Vive en el servidor |
|---|---|
| Las pantallas | El catálogo, precios y stock |
| **La detección de emociones** (sin subir imágenes) | Las ofertas y **su orden** |
| Decidir *cuándo* pedir el siguiente escalón | El registro de ventas |
| | Las reglas: límite diario, stock, que el total cuadre |

La cámara nunca sale del teléfono: lo que viaja por la red es "dame las ofertas
del producto 3", con el token que dice quién pregunta.

**El APK solo puede leer.** Su clave va dentro del paquete y cualquiera la
extrae, así que las escrituras pasan por funciones que validan las reglas.
`fn_confirmar_carrito` no recibe ni el total (lo recalcula desde el catálogo) ni el
id del cliente (lo saca del token).

---

## Reglas de negocio

1. **La cámara solo se enciende durante una interacción** con un producto seleccionado
2. **Se apaga automáticamente** al terminar
3. **El precio normal se muestra primero**; la primera oferta se juega cuando el cliente no responde bien
4. **Las ofertas se muestran solas**, sin botón
5. **Un cliente tiene una sola oportunidad de oferta al día** — solo cuentan las compras que *usaron* oferta; pagar precio de lista no consume el cupo
6. **No todos los productos tienen ofertas**: sin escalera, el precio no se mueve
7. **Las ofertas respetan su orden, vigencia y estado activo**
8. **La interacción termina** al agregar al carrito, al abandonar o al agotarse la escalera
9. **El precio negociado se congela** al agregar al carrito; renegociar un producto que ya está dentro no se permite
10. **Una confirmación de carrito es una venta**, aunque lleve varios productos

---

## Stack tecnológico

| Componente | Tecnología |
|---|---|
| Framework | Flutter 3.47.x (Dart 3.13.x) |
| Módulo nativo | Kotlin — CameraX, ML Kit, TensorFlow Lite |
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
│  CameraX ──> ML Kit ──> TensorFlow Lite  │     │  v_catalogo      │
│                   │                      │     │  v_secuencia_    │
│                   v                      │     │    ofertas       │
│         EmotionProcessor                 │     │                  │
│    (26 frames para estabilizar)          │     │  fn_ofertas_de   │
│                   │                      │     │  fn_confirmar_   │
│          EventChannel                    │     │    carrito       │
│                   │                      │     │  fn_historial    │
│                   v                      │     │                  │
│   ClasificadorRespuesta ──> Negociacion  │<───>│  RLS en las 11   │
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
│   │   │   ├── build_info.dart                   commit y rama de este build
│   │   │   ├── actualizacion_service.dart        compara el build contra app_config
│   │   │   ├── descarga_apk.dart                 baja e instala la actualización
│   │   │   ├── autenticacion.dart                errores de Auth en castellano
│   │   │   └── sesion_service.dart               registro, ingreso, recuperar clave
│   │   └── repositories/
│   │       ├── tienda_repository.dart            el puerto: lo que la app pide al backend
│   │       └── supabase_tienda_repository.dart   PostgREST + RPC + Realtime
│   ├── decision/
│   │   └── negociacion.dart                      ClasificadorRespuesta y Negociacion
│   ├── services/emotion_channel.dart             puente con el módulo nativo
│   ├── theme/app_theme.dart                      tipografía y color
│   └── ui/                                       login, tienda, carrito, historial, detalle
│
├── android/app/src/main/
│   ├── kotlin/com/tuapp/tienda_adaptativa/
│   │   ├── context/CameraManager.kt              FASE 1: captura
│   │   ├── context/EmotionDetector.kt            FASE 1: ML Kit + TFLite
│   │   ├── processing/EmotionProcessor.kt        FASE 2: filtro de estabilidad
│   │   └── channel/EmotionChannelHandler.kt      expone el pipeline a Flutter
│   └── assets/emotion_model.tflite               modelo FER-2013
│
├── supabase/
│   ├── migrations/                               0001 a 0014 (0006 va en tres partes)
│   ├── tests/                                    3 suites SQL + ejecutar.sh
│   └── README.md                                 guía del backend y administración
│
├── entregables/                                  documentación del taller (ver abajo)
├── docs/                                         material de origen del curso (PDF, docx)
│
└── test/                                         158 pruebas Dart
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

# 2. Dependencias de Flutter
flutter pub get

# 3. Backend: crear el proyecto en Supabase y aplicar las 14 migraciones
#    de supabase/migrations/ en orden (ver supabase/README.md)

# 4. Credenciales: copiar env.example.json a env.json y poner ahí la URL y
#    la publishable key del proyecto
cp env.example.json env.json

# 5. Pruebas (no necesitan celular, emulador ni backend)
flutter test

# 6. Ejecutar
flutter run --dart-define-from-file=env.json              # en celular
flutter run -d chrome --dart-define-from-file=env.json    # en navegador
```

> En navegador funciona el catálogo, el login y la compra, pero **no la
> detección de emociones**: es un módulo nativo de Android. La negociación se
> queda en el precio normal.

### Pruebas del backend

```bash
# Contra cualquier PostgreSQL vacío: aplica las migraciones y corre las suites.
PGURL=postgresql://usuario:clave@host:5432/basedatos bash supabase/tests/ejecutar.sh
```

Es lo mismo que hace CI en cada push ([backend-sql.yml](.github/workflows/backend-sql.yml)),
contra un PostgreSQL 16 real. Cada suite vive en una transacción que termina en `ROLLBACK`,
así que no deja datos.

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
2. Mirar la cámara con expresión neutra → la escalera avanza sola
3. Sonreír → se queda donde está
4. Pulsar **"No, gracias"** → avanza al siguiente escalón, igual que una cara desfavorable
5. Seleccionar la **Laptop HP Pavilion** → no tiene ofertas, el precio no se mueve pase lo que pase

Para ver el límite diario: agregar al carrito con oferta, **confirmar la compra** y
seleccionar otro producto.
La escalera viene vacía y todo se queda a precio normal hasta mañana. Comprar a precio
de lista no gasta el cupo: se puede repetir sin perder la oportunidad.

Para ver el tiempo real: cambiar un precio o un stock desde el panel de
Supabase y mirar cómo se actualiza en el celular sin refrescar.

---

## Documentación

La documentación del taller vive en **[entregables/](entregables/)**:

| Documento | Qué es |
|---|---|
| [INFORME_TECNICO.md](entregables/INFORME_TECNICO.md) | **El documento técnico del taller**: pipeline, arquitectura y verificación |
| [ARQUITECTURA.md](entregables/ARQUITECTURA.md) | Componentes, diagramas de flujo y decisiones |
| [REQUISITOS.md](entregables/REQUISITOS.md) | Objetivos, alcances, requisitos y limitaciones |
| [GUIA_ESTUDIO.md](entregables/GUIA_ESTUDIO.md) · [RETOS_EN_VIVO.md](entregables/RETOS_EN_VIVO.md) | Preparación de la sustentación |

En [docs/](docs/) queda el material de origen del curso (los PDF del taller y los
documentos del diseño de base de datos).

---

## Administración

El **Table Editor** de Supabase es la vista de administración: alta de
productos, publicación de ofertas, reposición de stock y subida de imágenes,
todo sin recompilar el APK.

El procedimiento está en [supabase/README.md](supabase/README.md).
