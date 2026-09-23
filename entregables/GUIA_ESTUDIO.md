# Guía de estudio — Tienda Adaptativa (Taller 1)

Documento para repasar antes de la sustentación. Solo texto y cuadros (sin diagramas) para
que se pueda imprimir. Basado en `Taller 0001.pdf` y en el código fuente actual.

---

## 0. Cómo es la sustentación

El PDF (§7) la divide en cuatro partes:

| Parte | Duración | Qué pide |
|---|---|---|
| 1. Presentación | 3 min | Problema + solución + comportamiento adaptativo |
| 2. Demostración | 5 min | La app corriendo, adaptándose **en tiempo real** |
| 3. Revisión técnica | — | Cualquier integrante explica una sección, ubica una operación, describe el flujo o predice el efecto de un cambio |
| 4. Reto técnico | — | Una modificación, incidencia o condición nueva sobre nuestra propia solución |

Para la parte 4 hay un documento aparte: [RETOS_EN_VIVO.md](RETOS_EN_VIVO.md).

**La frase eliminatoria del PDF (§4, textual):**

> *"Cambiar manualmente una configuración de la aplicación no constituye comportamiento
> adaptativo."*

Y las tres condiciones que exige, también textuales:

> *"La condición debe ser detectada por el software · La decisión debe producirse
> automáticamente · La adaptación debe ser observable y demostrable."*

**Cómo las cumplimos, en una línea cada una:**

| Condición | Cómo se cumple |
|---|---|
| Detectada por el software | La cámara clasifica la expresión; el cliente no declara nada |
| Decisión automática | Al cerrarse la ventana de 8 s el sistema avanza o no, sin que nadie pulse |
| Observable y demostrable | El precio en pantalla baja solo, y el chip muestra la emoción que lo causó |

---

## 1. El pipeline obligatorio, mapeado a archivos reales

El PDF exige el flujo **CONTEXTO → PROCESAMIENTO → DECISIÓN → ADAPTACIÓN**. Esto es lo
que hay que poder señalar en pantalla:

| Fase | Archivo | Qué hace exactamente |
|---|---|---|
| **CONTEXTO** | `android/.../context/CameraManager.kt` | CameraX abre la cámara frontal y entrega `ImageProxy` por frame |
| | `android/.../context/EmotionDetector.kt` | ML Kit ubica el rostro; TFLite clasifica el recorte 48×48 y devuelve `EmotionResult` |
| **PROCESAMIENTO** | `android/.../processing/EmotionProcessor.kt` | Ventana de 26 frames, voto por mayoría (45%) e histéresis (margen 6) → emoción estable |
| **puente** | `channel/EmotionChannelHandler.kt` → `lib/services/emotion_channel.dart` | `EventChannel`: `{emotion, confidence}` cruza de Kotlin a Dart |
| **DECISIÓN** | `lib/decision/negociacion.dart` | `ClasificadorRespuesta` cuenta votos → `Negociacion` devuelve `mantener` / `avanzar` / `terminar` |
| **ADAPTACIÓN** | `lib/ui/tienda_screen.dart` | `_evaluarVentana()` aplica el paso: repinta el precio y reabre la ventana |

**El recorrido en voz alta (memorízalo así):**

> "La cámara entrega frames; ML Kit encuentra la cara y TensorFlow Lite la clasifica. Como
> el clasificador es ruidoso, `EmotionProcessor` vota sobre 26 frames antes de declarar una
> emoción estable. Esa emoción cruza a Dart por un `EventChannel`. En Dart abrimos una
> ventana de 8 segundos, juntamos las lecturas y `ClasificadorRespuesta` las resume en una
> sola respuesta: favorable, desfavorable o sin señal. Si es desfavorable, `Negociacion`
> avanza un escalón de la escalera de ofertas y la pantalla repinta el precio. Nadie tocó
> nada."

---

## 2. La decisión (el corazón del taller)

Esto es lo que más te van a preguntar. Está entero en `lib/decision/negociacion.dart`,
que son unas 150 líneas y no depende de Flutter ni de la cámara.

### 2.1 Clasificación de la respuesta

| Grupo | Emociones | Efecto |
|---|---|---|
| Favorable | `feliz`, `sorpresa` | Mantiene el precio actual |
| Desfavorable | `neutral`, `triste`, `enojo` | **Avanza un escalón** |
| Sin señal | `no_face`, o menos de 2 lecturas | No hace nada |

Tres detalles que hay que saber defender:

- **Empate → favorable.** "Ante la duda no se regala margen."
- **`minimoVotos = 2`, no 3.** Cada lectura ya viene filtrada por los 26 frames del lado
  Kotlin (~1,3 s de cara sostenida), así que 2 lecturas no son 2 fotogramas. Con 3, había
  ventanas enteras que se cerraban sin poder decidir.
- **`neutral` cuenta como desfavorable.** Es decisión de producto. Si preguntan por el
  riesgo: la cara en reposo frente a una pantalla suele clasificarse como neutral, así que
  la mayoría de clientes verá avanzar la escalera. Es el primer sitio donde mirar si la
  tienda regala más margen del que quiere.

### 2.2 La escalera

`Negociacion` es un **puntero**, no un generador de descuentos:

```
_posicion = -1  → precio normal        (siempre empieza aquí)
_posicion =  0  → escalón 1 (10%)
_posicion =  1  → escalón 2 (20%)
_posicion =  2  → escalón 3 (30%)      → quedanEscalones == false
```

| Método | Devuelve |
|---|---|
| `siguientePaso(respuesta)` | `mantener` · `avanzar` · `terminar` |
| `precioActualCentavos` | El precio del escalón vigente, o el normal |
| `quedanEscalones` | Si aún hay a dónde avanzar |

**La frase que resume el proyecto entero:**

> "La emoción no calcula el descuento. Decide si el puntero se queda o avanza. Los
> porcentajes, su orden y su vigencia los publicó un administrador en la base de datos."

---

## 3. Por qué hay DOS filtros de ruido

Pregunta probable: *"¿No es redundante votar dos veces?"* No, y hay que saber por qué:

| Filtro | Dónde | Qué estabiliza |
|---|---|---|
| Ventana de 26 frames, mayoría 45%, histéresis 6 | `EmotionProcessor.kt` (Kotlin) | La **señal**: que la etiqueta no parpadee entre dos clases |
| Ventana de 8 s, conteo de votos, mínimo 2 | `ClasificadorRespuesta` (Dart) | La **decisión**: que un instante de duda no mueva el precio |

Números medidos en dispositivo, no estimados:

| Medición | Valor |
|---|---|
| El clasificador alterna entre dos clases sobre la misma cara quieta | 48% / 42% |
| Cambios de emoción en 20 s, sin filtro | 16 |
| Cambios de emoción en 20 s, con mayoría + histéresis | 7 |
| Frames sin rostro en 20 s de uso normal | 143 de ~430 |
| Error de "enojo" con rostro neutral, antes / después del preprocesamiento | 49% → 5% |

---

## 4. Persistencia y backend

| Qué | Dónde |
|---|---|
| 11 tablas, 3 vistas, 13 funciones | `supabase/migrations/` (14 archivos) |
| Lo que ve la tienda | vista `v_catalogo` |
| La escalera de un producto, para quien llama | `fn_ofertas_de()` |
| Cerrar la compra | `fn_confirmar_carrito()` |
| El historial y su detalle | `fn_historial()`, `fn_venta_detalle()` |

**Tres cosas que hay que poder decir de memoria:**

1. **La app no puede escribir en ninguna tabla.** Su clave va dentro del APK y cualquiera
   la extrae; si pudiera hacer `INSERT`, podría hacer `UPDATE` de precios. Las escrituras
   pasan por funciones `SECURITY DEFINER`.
2. **`fn_confirmar_carrito` no recibe el total ni el id del cliente.** Recalcula el total
   desde el catálogo y saca el cliente del token. Mientras el id venía como parámetro,
   cualquiera podía registrar compras a nombre de otro.
3. **El descuento de stock va bajo `FOR UPDATE`.** Es lo único que impide que dos clientes
   se lleven la misma última unidad.

### La regla de la oferta única (migración 0013)

Un cliente tiene **una sola oportunidad de oferta al día**. Solo cuentan las compras que
*usaron* oferta: pagar precio de lista no consume el cupo. "Hoy" es el día en
`America/Lima`, no en UTC — con UTC, una compra a las 8 de la noche contaría como del día
siguiente.

---

## 5. Autenticación y sesión

- Las contraseñas **no están en nuestras tablas**: `clientes` guarda un `uid` que apunta a
  `auth.users`. El hash (bcrypt), el refresco de tokens y la recuperación por correo los
  maneja Supabase Auth, en un esquema al que la app no accede.
- El correo tampoco lo manda el formulario: `fn_registrar_cliente` lo lee de `auth.users`,
  que es el que ya fue verificado.
- Si preguntan por qué no lo hicimos nosotros: escribir hashing de contraseñas es fácil de
  hacer mal, y delegarlo elimina esa categoría entera de errores.

---

## 6. Estado actual (lo que sí está y lo que no)

| Parte | Estado |
|---|---|
| Backend: esquema, funciones validadas, RLS, Storage | 17 migraciones, 3 suites SQL sobre PostgreSQL real |
| Identidad con Supabase Auth | Cada cliente ve solo sus compras |
| Motor de negociación | 181 pruebas Dart |
| Detección y clasificación (Kotlin) | ML Kit + TFLite, en el dispositivo |
| Puente Flutter ↔ Kotlin | `EventChannel`, degrada donde no hay detector |
| Pantallas | Login, tienda, carrito, historial, detalle de venta |
| Catálogo | 50 productos en 8 categorías |
| Stock en tiempo real entre dispositivos | Realtime + relectura al volver de segundo plano |
| Aviso de versión nueva dentro de la app | Franja con botón *Actualizar* |

**Lo que NO tiene** (dilo tú antes de que lo pregunten, con el motivo):

| No tiene | Motivo |
|---|---|
| Reordenamiento del catálogo por emoción | Existió en una iteración anterior; se retiró al adoptar la escalera. La emoción gobierna el ritmo, no qué producto se ve |
| Registro de la emoción por venta | No hay tabla de interacciones: la etiqueta se consume en pantalla y no se persiste. A cambio, ningún dato derivado del rostro queda almacenado |
| Funcionamiento sin conexión | Una copia local del catálogo solo puede estar desactualizada: mostraría un precio que ya cambió o un producto agotado |
| Modo horizontal | En horizontal el rostro sale del encuadre, y sin rostro no hay contexto |

---

## 7. Asincronía y ciclo de vida

| Mecanismo | Dónde | Para qué |
|---|---|---|
| `ExecutorService` de un hilo | `EmotionDetector.kt` | Clasificar fuera del hilo de UI |
| `ImageAnalysis` con `KEEP_ONLY_LATEST` | `CameraManager.kt` | Descartar frames viejos en vez de encolarlos |
| `EventChannel` (stream) | puente Kotlin↔Dart | Flujo continuo, no petición-respuesta |
| `StreamSubscription` | `TiendaScreen._emociones` | Se cancela en `_apagarCamara()` y en `dispose()` |
| `Timer` | `TiendaScreen._ventana` | La ventana de observación; se cancela antes de reabrirse |
| `WidgetsBindingObserver` | `TiendaScreen`, `MyApp` | Relee catálogo y versión al volver de segundo plano |
| `async`/`await` | `_seleccionarProducto` | Pedir la escalera sin congelar la interfaz |

Hay una prueba que fija esto: *"salir de la pantalla no deja timers vivos"*
(`test/ui/tienda_screen_test.dart`).

---

## 8. Trampas y decisiones ya resueltas

Preguntas capciosas probables, con la respuesta ya pensada:

| Pregunta | Respuesta |
|---|---|
| *"¿Y si sonrío para que baje el precio?"* | Sonreír **mantiene** el precio; lo que lo baja es no responder bien. El incentivo va al revés de lo que la gente supone |
| *"¿Esto no es solo un `if` sobre la emoción?"* | El `if` es la última línea. Lo que lo hace adaptativo es todo lo que hay antes: detectar la condición sin que el usuario la declare, y estabilizarla lo bastante como para que la decisión no sea ruido |
| *"¿Por qué 26 frames y no 5?"* | Con 5 la emoción cambiaba varias veces por segundo. 26 a ~20 fps son ~1,3 s: filtra el ruido sin que se sienta lento |
| *"¿Por qué mayoría al 45% y no al 60%?"* | Medido: la clase correcta gana con ~54% de los frames (el azar sería 20% con 5 clases). Con 0.6 no se confirmaba ninguna emoción nunca |
| *"¿Por qué el dinero es entero?"* | Centavos en `int`. Con `double`, 0.1 + 0.2 no da 0.3, y un total de venta no puede depender de eso |
| *"¿Dónde guardas la cara?"* | En ningún sitio. El frame se procesa y se descarta; solo se produce una etiqueta, y ni siquiera esa se persiste |
| *"¿Qué pasa si no hay cámara o el permiso está denegado?"* | El `onError` del stream apaga la cámara, avisa al cliente y deja la negociación en el precio normal. Sin eso, la ventana esperaba 8 s una evaluación que no iba a llegar |
| *"¿Y si el cliente sale de cuadro un segundo?"* | No pasa nada: la ventana solo se descarta tras 5 frames seguidos sin rostro. Antes se limpiaba en el primero, y la emoción no llegaba a estabilizarse nunca |

---

## 9. Glosario rápido

| Término | Significado aquí |
|---|---|
| **Escalera de ofertas** | La lista ordenada de descuentos de un producto, en la tabla `ofertas_productos` por su columna `orden` |
| **Escalón** | Un elemento de esa lista |
| **Ventana de observación** | Los 8 s durante los que se juntan lecturas antes de decidir |
| **Emoción estable** | La que superó el voto de mayoría e histéresis en `EmotionProcessor` |
| **Histéresis** | Que para desplazar a la emoción vigente no baste con ganar: hay que ganarle por 6 votos |
| **RLS** | *Row Level Security*: las políticas de PostgreSQL que deciden qué filas ve cada rol |
| **`SECURITY DEFINER`** | Función que se ejecuta con los permisos de quien la creó, no de quien la llama. Así la app escribe sin tener permiso de escritura |
| **Combo** | Oferta que fija un precio final, en vez de un porcentaje |

---

## 10. Pruebas automatizadas

| Comando | Qué corre |
|---|---|
| `flutter test` | 181 casos Dart: clasificador, negociación, pantallas, carrito, historial |
| `cd android && ./gradlew testDebugUnitTest` | 9 casos JUnit sobre `EmotionProcessor` |
| `PGURL=... bash supabase/tests/ejecutar.sh` | 3 suites SQL contra un PostgreSQL real |

Las tres corren en CI en cada push. Dos que conviene citar por su nombre:

- **La regla eliminatoria:** una prueba de widget avanza la escalera sin pulsar ningún
  botón — solo emitiendo emociones por el canal falso.
- **La seguridad:** `04_seguridad.sql` falla si la clave pública puede tocar precios,
  stock, ofertas o ventas, o si un cliente puede ver lo de otro.

Que las 181 pruebas Dart corran **sin cámara, sin emulador y sin backend** es la prueba
concreta de la separación de capas, y conviene decirlo así.

---

## 11. Checklist final antes de la presentación

- [ ] APK instalada en el celular, de la **release de GitHub** (no un build local: la firma
      debe coincidir para poder actualizar encima)
- [ ] Sesión iniciada, y **cupo de oferta del día sin gastar**
- [ ] Panel de Supabase abierto en otra pestaña, en la tabla `productos`
- [ ] Saber de memoria qué producto tiene escalera de 3 escalones y cuál no tiene ninguna
- [ ] Probar la demo una vez con luz parecida a la del aula
- [ ] `flutter test` en verde antes de salir de casa
- [ ] Tener a mano [RETOS_EN_VIVO.md](RETOS_EN_VIVO.md) para la parte 4

### El guion de 3 minutos

1. **Problema** (30 s): en una tienda física el vendedor ve que dudas y reacciona; en una
   digital esa señal se pierde.
2. **Solución** (45 s): leemos la respuesta facial con la cámara frontal y la usamos para
   avanzar por una escalera de ofertas que publicó un administrador.
3. **Lo adaptativo** (60 s): la condición la detecta el software, la decisión se toma sola
   al cerrarse la ventana, y el resultado se ve — el precio baja en pantalla.
4. **El límite honesto** (25 s): la emoción no calcula el descuento; solo decide el ritmo.
   Los precios los pone una persona.
