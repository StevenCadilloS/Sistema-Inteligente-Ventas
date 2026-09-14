# Retos técnicos en vivo — Taller 1

Guía de defensa oral. El PDF (§8) dice que el reto **se define en función de la solución
presentada por cada equipo** y que puede ser de cinco tipos. Este documento está
organizado por esos cinco tipos.

Formato: **qué te pueden pedir → dónde está → cómo lo haces delante del docente.**
Solo texto y tablas, imprimible.

---

## 0. Antes de entrar al aula

| Acción | Comando |
|---|---|
| Dejar la app corriendo con hot reload | `flutter run --dart-define-from-file=env.json` (la tecla `r` recarga en 1 s) |
| Confirmar que partes en verde | `flutter test` |
| Panel de la base | Abrir Supabase → Table Editor → `productos` |
| Ver la escalera de un producto | `select * from v_secuencia_ofertas where id_producto = 1;` |
| Ver qué ofertas están vigentes hoy | `select * from v_ofertas_vigentes;` |

**Qué APK llevar.** La de la **release de GitHub**, no un build local. Android solo instala
una APK encima de otra si comparten firma, y los builds locales usan la clave de
depuración, distinta en cada máquina.

**Dos atajos que valen oro en vivo:**

- **Hot reload** (`r` en la terminal de `flutter run`) aplica un cambio de Dart en ~1 s sin
  perder la sesión. Todo lo que esté en `lib/` se puede cambiar así.
- **Cambiar un dato en el panel de Supabase** se ve en el celular al instante, sin
  recompilar nada: es Realtime. Sirve para "cambia una oferta" sin tocar código.

> **Cuidado:** un cambio en Kotlin (`android/`) **no** entra por hot reload. Requiere
> `flutter run` completo, ~1-2 min. Si el reto es sobre `EmotionProcessor`, dilo antes de
> empezar para que el docente sepa por qué esperas.

---

## Tipo 1 — Cambio funcional

> *"Modificar una característica del comportamiento adaptativo."*

### F1. "Haz que la escalera avance más rápido / más despacio"

**Dónde:** [`lib/ui/tienda_screen.dart:36`](../lib/ui/tienda_screen.dart#L36)

```dart
this.ventanaObservacion = const Duration(seconds: 8),
```

**Qué decir mientras lo cambias:** que 8 s no es arbitrario. El módulo nativo no entrega
una lectura por frame: exige 26 frames de la misma emoción, y a ~20 fps eso es ~1,3 s por
lectura. Con 4 s apenas caben dos, y a veces ninguna — la ventana se cerraba sin votos y
la escalera no avanzaba nunca.

**Si lo bajas a 3 s en vivo:** avisa de que probablemente verá `sinSenal` seguido, y que
eso es exactamente el fallo que llevó a subirlo a 8.

### F2. "Que `neutral` ya no baje el precio"

**Dónde:** [`lib/decision/negociacion.dart:42-45`](../lib/decision/negociacion.dart#L42-L45)

```dart
static const _favorables = {'feliz', 'sorpresa', 'happy', 'surprise'};
static const _desfavorables = {'neutral', 'triste', 'enojo', 'sad', 'angry'};
```

Mover `'neutral'` de un conjunto a otro es una línea. **Predice el efecto antes de
ejecutar** (el PDF dice que te lo pueden pedir): con `neutral` fuera de desfavorable, casi
ningún cliente verá avanzar la escalera, porque la cara en reposo se clasifica así. La
tienda protege margen pero deja de negociar casi siempre.

Si lo sacas de **ambos** conjuntos, `neutral` deja de votar: la ventana puede cerrarse con
menos de 2 votos y devolver `sinSenal`.

### F3. "Que el empate se resuelva al revés"

**Dónde:** [`lib/decision/negociacion.dart:65`](../lib/decision/negociacion.dart#L65)

```dart
return desfavorable > favorable ? Respuesta.desfavorable : Respuesta.favorable;
```

Cambiar `>` por `>=` hace que un empate avance la escalera. La decisión actual —empate =
favorable— es "ante la duda no se regala margen".

### F4. "Que el botón 'No, gracias' cierre la negociación"

**Dónde:** [`lib/ui/tienda_screen.dart:414`](../lib/ui/tienda_screen.dart#L414) (`_rechazar`)

Hoy hace lo mismo que una cara desfavorable: avanza un escalón. Antes cerraba todo, y era
un error — el cliente que rechaza el precio normal es justo al que hay que ofrecerle el
descuento.

---

## Tipo 2 — Cambio de contexto

> *"Incorporar o modificar una condición utilizada para tomar decisiones."*

### C1. "Agrega la confianza a la decisión"

Hoy la confianza (`EmocionDetectada.confidence`) **se muestra pero no decide**: solo
alimenta el chip de la interfaz.

**Dónde tocarlo:** [`lib/ui/tienda_screen.dart:322`](../lib/ui/tienda_screen.dart#L322),
donde se hace `_lecturas.add(e.emotion)`. Filtrar ahí:

```dart
if (e.confidence >= 0.6) _lecturas.add(e.emotion);
```

**Por qué es el sitio correcto:** `ClasificadorRespuesta` recibe una lista de etiquetas, no
de objetos. Filtrar antes de la lista mantiene la capa de decisión libre de la forma que
tenga el evento del canal — que es justo la separación que defendemos.

**Predice el efecto:** con el umbral alto entran menos lecturas, así que más ventanas
cerrarán con menos de 2 votos → `sinSenal` → el precio no se mueve.

### C2. "Que el número de votos mínimo dependa de algo"

**Dónde:** [`lib/decision/negociacion.dart:31`](../lib/decision/negociacion.dart#L31)

```dart
const ClasificadorRespuesta({this.minimoVotos = 2});
```

Es un parámetro con valor por defecto, así que se puede inyectar desde `TiendaScreen` sin
tocar la clase. Ese diseño es a propósito: es lo que permite probarlo.

### C3. "Usa otra variable de contexto: batería, luz, hora"

Respuesta honesta: **no está implementado**, y decirlo es mejor que improvisar. Pero sí se
puede explicar **dónde entraría sin romper nada**, que es lo que evalúa la pregunta:

| Variable | Dónde se capturaría | Dónde decidiría |
|---|---|---|
| Batería | Un `BatteryManager` en `android/.../context/`, hermano de `CameraManager` | Apagar la cámara y quedarse en precio normal bajo cierto nivel |
| Hora | Dart puro, sin capa nativa | `fn_zona_negocio()` ya define el día del negocio en `America/Lima` |
| Luz ambiental | Sensor en `context/` | Si no hay luz, ML Kit no encuentra rostro: ya degrada solo a `sinSenal` |

La forma del pipeline no cambiaría: una fase de contexto nueva, su estabilización, y una
entrada más a `ClasificadorRespuesta`.

---

## Tipo 3 — Incidencia

> *"Identificar y solucionar un problema introducido en el sistema."*

Aquí el docente rompe algo a propósito. La estrategia no es adivinar: es **aislar la capa**.

### El árbol de diagnóstico (memorízalo)

```
¿El chip de emoción muestra algo?
├── NO → el problema está ANTES de Dart
│        ¿permiso de cámara? ¿el EventChannel emite?
│        → android/.../channel/EmotionChannelHandler.kt
│        → ¿hay un onError? TiendaScreen lo muestra como aviso
└── SÍ → la emoción llega; el problema está en la DECISIÓN o la ESCALERA
         ¿el precio no se mueve?
         ├── ¿la escalera venía vacía? → fn_ofertas_de() devolvió 0 filas
         │    causas: producto sin ofertas · vigencia vencida · cupo del día gastado
         └── ¿la escalera tiene filas pero no avanza?
              → ClasificadorRespuesta devuelve favorable o sinSenal
              → mira cuántas lecturas entraron en la ventana
```

### Las averías más fáciles de introducir

| Síntoma | Causa probable | Dónde mirar |
|---|---|---|
| El precio nunca baja, con cara neutra | `neutral` sacado de `_desfavorables` | `negociacion.dart:43` |
| El precio baja de golpe hasta el último escalón | La ventana se reabre demasiado rápido, o `minimoVotos` en 1 | `tienda_screen.dart:36`, `negociacion.dart:31` |
| La emoción parpadea en el chip | `MARGEN_PARA_CAMBIAR` o `MAYORIA_MINIMA` alterados | `EmotionProcessor.kt:158`, `:166` |
| Todo a precio normal, cámara apagada | La escalera vino vacía: cupo del día gastado | `fn_puede_usar_oferta()` en el SQL Editor |

**Comprobación rápida en el SQL Editor**, útil si sospechas del backend:

```sql
select fn_puede_usar_oferta();          -- ¿le queda cupo a quien llama?
select * from fn_ofertas_de(1);          -- ¿qué escalera devuelve de verdad?
```

---

## Tipo 4 — Comportamiento inesperado

> *"Analizar por qué la aplicación produce determinado resultado y corregirlo."*

Estos son los resultados "raros" que el sistema produce **a propósito**. Si el docente
señala uno, la respuesta no es corregirlo: es explicar por qué está así.

| Lo que verá | Por qué pasa |
|---|---|
| Sonreír **no** consigue descuento | Sonreír es respuesta favorable: mantiene el precio. Lo que avanza la escalera es no responder bien. El incentivo va al revés de lo que la gente supone |
| Casi cualquiera hace avanzar la escalera | `neutral` cuenta como desfavorable, y la cara en reposo frente a una pantalla se clasifica así. Decisión de producto, documentada en `negociacion.dart:10-16` |
| Un producto no baja de precio pase lo que pase | No tiene escalera configurada. Es el caso de control de la demo |
| La segunda compra del día se queda a precio normal | La regla de 0013: una sola oferta al día, y solo las compras **con** oferta gastan el cupo |
| El rostro sale de cuadro y no pasa nada | La ventana solo se descarta tras 5 frames seguidos sin rostro. Antes se limpiaba en el primero y la emoción no llegaba a estabilizarse |
| El popup dice "Oferta 2" pero no "de 3" | A propósito: si el cliente supiera que hay tres, esperaría al 30% y no aceptaría el 10% (`popup_oferta.dart:122-126`) |
| En el navegador la oferta nunca cambia | No hay módulo nativo: `EmotionChannel.disponible` es `false` y la negociación se queda en precio normal |

---

## Tipo 5 — Modificación de código

> *"Modificar una parte determinada de la solución manteniendo el funcionamiento
> existente."*

Lo que evalúa esto es si la arquitectura aguanta un cambio sin romperse. Dos ejemplos
probables:

### M1. "Agrega un campo al producto y muéstralo"

| Paso | Dónde |
|---|---|
| 1. Columna en la base | `alter table productos add column material text;` en el SQL Editor |
| 2. Exponerla | La vista `v_catalogo` (migración `0002_funciones.sql`) |
| 3. Modelo Dart | `Producto.desdeFila` en `lib/data/modelos/modelos.dart` |
| 4. Pintarla | `lib/ui/widgets/producto_card.dart` |

**Qué destacar:** no hay que recompilar para que el dato exista, y la app no arma SQL en
cadenas — habla con vistas y funciones nombradas.

### M2. "Cambia la fuente del contexto por una simulada"

Este es el que mejor demuestra la separación de capas, y ya está hecho: las pruebas de pantalla
usan un `EmotionChannel` falso — `_CanalFalso` en
[`test/ui/tienda_screen_test.dart:18`](../test/ui/tienda_screen_test.dart#L18), que implementa la
misma interfaz y empuja emociones por un `StreamController`. Ábrelo y enséñalo.

```
La decisión no sabe si la emoción viene de una cámara o de una lista en una prueba.
Por eso 158 pruebas corren sin cámara, sin emulador y sin backend.
```

---

## Preguntas conceptuales (sin tocar código)

### "¿Por qué esto es adaptativo y no simplemente reactivo?"

Un sistema reactivo responde a una **orden**: pulsas y pasa algo. Este responde a una
**condición del contexto que el usuario no emite a propósito** — nadie pone cara neutra
*para* pedir un descuento. No hay botón que dispare la adaptación, y el PDF lo exige
textualmente: *"cambiar manualmente una configuración no constituye comportamiento
adaptativo"*.

### "¿Dónde está la inteligencia, si los descuentos los pone una persona?"

En **cuándo** se juega cada uno. Publicar un 30% para todos es una promoción; jugarlo solo
con quien no aceptó el 10% es negociar. La escalera es el catálogo de jugadas; el sistema
decide el ritmo. Y esa separación es deliberada: si el código inventara descuentos, nadie
podría auditarlos ni el administrador controlaría su margen.

### "¿Por qué dos filtros de ruido?"

El de Kotlin estabiliza la **señal** (que la etiqueta no parpadee). El de Dart estabiliza la
**decisión** (que un instante de duda no mueva el precio). Números medidos: sin filtro, 16
cambios de emoción en 20 s con el usuario quieto; con mayoría e histéresis, 7.

### "¿Por qué el dinero es entero?"

Centavos en `int`. Con `double`, `0.1 + 0.2` no da `0.3`, y el total de una venta no puede
depender de eso. La base lo guarda igual (`precio_centavos`), y `fn_confirmar_carrito`
recalcula el total en aritmética entera.

### "¿Dónde queda registrado que el cliente rechazó?"

**En ningún sitio, y es deliberado.** No hay tabla de interacciones: la etiqueta de emoción
se consume en pantalla y se descarta. El precio de cada línea sí queda congelado en
`detalle_venta`, así que se sabe con qué descuento cerró — pero no qué cara lo provocó. El
costo es que no hay analítica de conversión por emoción; la ganancia es que ningún dato
derivado del rostro queda almacenado.

---

## Puntos débiles conocidos (dilos tú primero)

| Debilidad | Cómo presentarla |
|---|---|
| El modelo confunde `triste` con `enojo` | Es el techo del modelo (48×48 px), no del pipeline. Ambas caen en el mismo grupo *desfavorable*, así que **la confusión no altera la decisión** |
| `neutral` como desfavorable regala margen | Decisión de producto consciente, documentada en el código. Es el primer parámetro a revisar si la tienda pierde margen |
| Depende de la luz | Sin luz ML Kit no encuentra rostro → `sinSenal` → el precio no se mueve. Degrada a lo seguro, no a lo caro |
| Sin conexión no funciona | Deliberado: una copia local del catálogo solo puede estar desactualizada |
| No hay analítica de la adaptación | Consecuencia de no persistir la emoción. Es un intercambio, no un olvido |

---

## Resumen de una hoja

```
PIPELINE
  CameraManager.kt        → frames de la cámara frontal
  EmotionDetector.kt      → ML Kit ubica el rostro; TFLite clasifica 48x48
  EmotionProcessor.kt     → 26 frames, mayoría 45%, histéresis 6 → emoción estable
  EventChannel            → {emotion, confidence} cruza a Dart
  ClasificadorRespuesta   → vota las lecturas de 8 s → favorable/desfavorable/sinSenal
  Negociacion             → mantener / avanzar / terminar
  TiendaScreen            → repinta el precio y reabre la ventana

LA FRASE
  La emoción no calcula el descuento: decide si el puntero avanza.
  Los precios los publica un administrador en PostgreSQL.

LOS NÚMEROS
  26 frames · mayoría 45% · margen 6 · ventana 8 s · mínimo 2 votos
  16 → 7 cambios de emoción en 20 s     error "enojo" 49% → 5%
  158 pruebas Dart · 9 JUnit · 3 suites SQL · 14 migraciones

SI NO SABES ALGO
  Di dónde lo buscarías. La arquitectura es la respuesta:
  contexto en android/context, procesamiento en android/processing,
  decisión en lib/decision, adaptación en lib/ui, reglas en supabase/migrations.
```
