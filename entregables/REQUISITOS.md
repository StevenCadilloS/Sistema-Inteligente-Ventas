# Tienda Adaptativa — Requisitos, Alcances y Limitaciones

**Taller 1 · Desarrollo de una Aplicación Adaptativa · UNI FIIS · 2026-2**
Equipo: Elvis Arboleda (base de datos, motor de reglas, autenticación) · Juan Medina
(modelo de emociones) · Steven Cadillo (frontend e integración con la cámara)

---

## 1. Objetivos

### 1.1 Objetivo general

Construir una aplicación móvil Android que **avance automáticamente por una escalera de
ofertas según la respuesta emocional del cliente**, sin que este emita ninguna orden
explícita, demostrando el pipeline adaptativo *contexto → procesamiento → decisión →
adaptación* del curso.

> **La emoción no calcula el descuento.** Decide si el sistema se queda donde está o pasa
> al siguiente escalón de una escalera que un administrador publicó en la base de datos.

### 1.2 Objetivos específicos

| ID | Objetivo | Verificable en |
|---|---|---|
| OE-01 | Capturar la expresión facial del cliente desde la cámara frontal, sin previsualización | `CameraManager.kt`, `EmotionDetector.kt` |
| OE-02 | Estabilizar la señal ruidosa del clasificador para que la adaptación no oscile frame a frame | `EmotionProcessor.kt` |
| OE-03 | Clasificar una racha de emociones en una sola respuesta (favorable / desfavorable / sin señal) | `ClasificadorRespuesta` en `lib/decision/negociacion.dart` |
| OE-04 | Avanzar automáticamente por la escalera de ofertas cuando la respuesta es desfavorable | `Negociacion` en `lib/decision/negociacion.dart` |
| OE-05 | Encender la cámara solo durante una negociación y apagarla al terminar | `TiendaScreen._encenderCamara`, `_apagarCamara` |
| OE-06 | Procesar el rostro íntegramente en el dispositivo: ninguna imagen sale del teléfono | `CameraManager.kt`, `EmotionDetector.kt` |
| OE-07 | Mantener catálogo, stock y ofertas en una base compartida, de modo que lo que publica el administrador llegue a todos los usuarios sin refrescar | `supabase/migrations/`, `SupabaseTiendaRepository` |
| OE-08 | Permitir administrar la tienda (altas, ofertas con vigencia, reposición de stock) sin tocar el código ni recompilar | Panel de Supabase, tablas `productos` y `ofertas` |

### 1.3 Requisito eliminatorio del taller

> **La oferta debe cambiar sola, sin intervención manual del usuario.**

Se cumple porque el disparador de la adaptación es el resultado de la ventana de
observación, no un botón. Está fijado por prueba automatizada en
`test/ui/tienda_screen_test.dart`.

---

## 2. Alcances

### 2.1 Dentro del alcance

| ID | Alcance |
|---|---|
| AL-01 | Aplicación Android nativa-híbrida (Flutter + módulo Kotlin), `minSdk` 26 (Android 8.0+) |
| AL-02 | Reconocimiento de **5 emociones**: `feliz`, `sorpresa`, `neutral`, `triste`, `enojo`, más el estado `no_face` |
| AL-03 | Catálogo administrable desde un panel, con stock y precios compartidos entre dispositivos |
| AL-04 | Escalera de ofertas de longitud variable por producto, definida en la base de datos |
| AL-05 | Registro e ingreso de clientes con Supabase Auth; cada cliente ve solo sus compras |
| AL-06 | Persistencia completa en PostgreSQL: 11 tablas con claves foráneas activas, 3 vistas y 13 funciones |
| AL-07 | Carrito: una confirmación es una venta con N líneas, con el precio de cada línea congelado |
| AL-08 | Regla de negocio de una sola oportunidad de oferta por cliente y día, calculada en el servidor |
| AL-09 | Historial de compras por venta, con pantalla de detalle línea a línea |
| AL-10 | Suite de pruebas automatizadas: 181 casos Dart (`flutter_test`), 3 suites SQL sobre PostgreSQL real y 9 casos JUnit (JVM) |
| AL-11 | Políticas de acceso por rol (RLS) y escrituras atómicas mediante funciones `SECURITY DEFINER` |
| AL-12 | Administración desde el panel de Supabase, sin recompilar la app |
| AL-13 | Propagación en tiempo real (WebSocket) de cambios de catálogo, stock y ofertas |
| AL-14 | Aviso y descarga de versión nueva desde dentro de la app |
| AL-15 | Proyecto de código abierto (licencia MIT) y backend autohospedable, sin dependencia de ningún servicio propietario |

### 2.2 Fuera del alcance

| ID | Exclusión | Motivo |
|---|---|---|
| FA-01 | Pantalla de administración dentro de la app Android | El administrador opera desde el panel web de Supabase, que ya ofrece tablas, filtros y edición; duplicarlo en Flutter no agregaba nada |
| FA-02 | Pasarela de pago o transacción financiera real | La venta se registra en la base y descuenta stock; no se cobra dinero |
| FA-03 | Versión iOS o de escritorio | El pipeline depende de CameraX/ML Kit/TFLite en Android |
| FA-04 | Funcionamiento sin conexión | Decisión explícita: ninguna tienda en línea real opera sin conexión, porque el precio y el stock que muestra deben ser los vigentes. Una copia local solo puede estar desactualizada. Una sola fuente de verdad elimina esa clase de error, a costa de exigir red |
| FA-05 | Entrenamiento o reentrenamiento del modelo de emociones | Se consume un modelo FER-2013 preentrenado |
| FA-06 | Orientación horizontal de pantalla | En horizontal el rostro sale del encuadre; sin rostro no hay contexto (`main.dart` fija vertical) |
| FA-07 | Identificación biométrica o almacenamiento de imágenes del rostro | La etiqueta de emoción ni siquiera se persiste: se consume en pantalla |
| FA-08 | Reordenamiento del catálogo por emoción | Existió en una iteración anterior del proyecto y se retiró al adoptar la escalera de ofertas: hoy la emoción gobierna el ritmo de la negociación, no qué producto se ve |

---

## 3. Requisitos funcionales

### 3.1 Contexto — captura (Kotlin nativo)

| ID | Requisito |
|---|---|
| RF-01 | El sistema debe capturar frames de la cámara **frontal** mediante CameraX (`ImageAnalysis`, `KEEP_ONLY_LATEST`) |
| RF-02 | El sistema debe localizar el rostro en cada frame usando ML Kit Face Detection |
| RF-03 | El sistema debe clasificar la expresión en una de las 5 emociones mediante TensorFlow Lite (entrada 48×48 px, escala de grises) |
| RF-04 | El sistema debe emitir, junto a cada emoción, la confianza del clasificador (0–1) |
| RF-05 | La captura debe operar **sin previsualización visible**: el cliente negocia, no posa para una foto |
| RF-06 | El sistema debe solicitar el permiso `CAMERA` en tiempo de ejecución, al iniciar la primera negociación y no al abrir la app |

### 3.2 Procesamiento — estabilización

| ID | Requisito |
|---|---|
| RF-07 | El sistema debe acumular una ventana deslizante de 26 frames antes de declarar una emoción estable |
| RF-08 | El sistema debe resolver la emoción estable por **voto de mayoría**, con umbral del 45% de la ventana |
| RF-09 | El sistema debe aplicar **histéresis**: una candidata solo desplaza a la emoción vigente si le gana por 6 votos o más |
| RF-10 | El sistema debe tolerar pérdidas momentáneas del rostro: la ventana solo se descarta tras 5 frames seguidos sin rostro |
| RF-11 | El sistema debe publicar la emoción estable hacia Flutter mediante un `EventChannel` de flujo continuo |

### 3.3 Decisión — clasificación de la respuesta y escalera

| ID | Requisito |
|---|---|
| RF-12 | El sistema debe agrupar las lecturas de una ventana de observación en una sola respuesta, por conteo de votos |
| RF-13 | El sistema debe clasificar `feliz` y `sorpresa` como **favorable**, y `neutral`, `triste` y `enojo` como **desfavorable** |
| RF-14 | El sistema debe devolver **sin señal** cuando la ventana reúne menos de 2 lecturas válidas, y en ese caso no hacer nada |
| RF-15 | Un empate entre favorable y desfavorable debe resolverse como favorable: ante la duda no se regala margen |
| RF-16 | Ante una respuesta desfavorable, el sistema debe **avanzar un escalón** de la escalera, sin acción del usuario |
| RF-17 | Ante una respuesta favorable o sin señal, el sistema debe mantener el precio vigente y seguir observando |
| RF-18 | La negociación debe avanzar en un solo sentido: el puntero nunca retrocede |
| RF-19 | El sistema debe empezar siempre en el **precio normal**: la primera oferta se juega cuando el cliente no responde bien a lo que ve |

**Clasificación de la respuesta** (implementada en `ClasificadorRespuesta`):

| Grupo | Emociones | Efecto |
|---|---|---|
| Favorable | `feliz`, `sorpresa` | Mantiene el precio actual |
| Desfavorable | `neutral`, `triste`, `enojo` | Avanza un escalón |
| Sin señal | `no_face`, o menos de 2 lecturas | No hace nada |

> `neutral` cuenta como desfavorable por decisión de producto. Conviene saber lo que
> implica: la cara en reposo frente a una pantalla suele clasificarse así, de modo que la
> mayoría de clientes verá avanzar la escalera.

### 3.4 Adaptación — interfaz

| ID | Requisito |
|---|---|
| RF-20 | Al seleccionar un producto, el sistema debe pedir su escalera y mostrarlo **a precio de lista** |
| RF-21 | La cámara debe encenderse al iniciar la negociación y apagarse al comprar, al abandonar o al agotarse la escalera |
| RF-22 | Si la escalera viene vacía —sin ofertas, ninguna vigente, o cliente sin cupo— el sistema no debe encender la cámara |
| RF-23 | La interfaz debe mostrar en todo momento la emoción detectada vigente y su confianza |
| RF-24 | La interfaz debe mostrar el escalón vigente ("Oferta 2") pero **no** cuántos quedan: si el cliente supiera que hay tres, esperaría al 30% y no aceptaría el 10% |
| RF-25 | El botón "No, gracias" debe **abandonar** la negociación, no avanzar la escalera: un toque no es una emoción, y solo la lectura facial decide si corresponde ofrecer el siguiente escalón |
| RF-26 | Donde no exista módulo nativo (web, escritorio), la negociación debe quedarse en el precio normal en vez de esperar una señal que no llegará |

#### Pausa por ausencia de rostro

| ID | Requisito |
|---|---|
| RF-27 | Si pasan más de **3 segundos** sin detectar ningún rostro, la negociación debe entrar automáticamente en estado **PAUSADO** |
| RF-28 | Mientras esté pausada, las emociones que lleguen **no deben contabilizarse** |
| RF-29 | Mientras esté pausada, la ventana de observación **no debe avanzar**, y por tanto no puede generarse ningún descuento nuevo |
| RF-30 | Al volver a detectarse el rostro, la negociación debe **reanudarse sola**, desde donde quedó y sin reiniciar la ventana |
| RF-31 | El estado pausado debe ser **visible sin ambigüedad**: cartel sobre el producto, barra de la ventana congelada con su porcentaje, y el chip del AppBar en "Sin rostro" |
| RF-32 | Irse a segundo plano debe pausar también: sin frames de la cámara la ventana no puede seguir corriendo |

> El umbral se cronometra en Dart y no contando lecturas porque el módulo nativo emite
> `no_face` **una sola vez** (5.º frame sin cara, ~250 ms) y luego calla. La pausa cae
> entonces a ~3,25 s reales de ausencia: el requisito dice "más de 3 segundos", y llegar
> un pelo tarde lo cumple. La reanudación tarda ~1,3 s porque el buffer nativo se limpió
> al perder el rostro y hay que rehacer los 26 frames de la lectura estable.

### 3.5 Autenticación y sesión

| ID | Requisito |
|---|---|
| RF-27 | El sistema debe permitir registrar un cliente y recuperar su contraseña por correo, mediante Supabase Auth |
| RF-28 | La sesión debe persistir entre reinicios, en el almacenamiento seguro del dispositivo |
| RF-29 | El correo del cliente debe leerse de `auth.users`, no del formulario: es el que el proveedor ya verificó |
| RF-30 | Un cliente debe poder leer **solo sus** compras; pedir el detalle de una venta ajena debe comportarse como si no existiera |

### 3.6 Persistencia y trazabilidad

| ID | Requisito |
|---|---|
| RF-31 | El sistema debe registrar cada venta con su detalle de línea, congelando el precio efectivamente pactado |
| RF-32 | Todo importe monetario debe almacenarse como **entero en centavos**, nunca en punto flotante |
| RF-33 | La integridad referencial debe estar activa en el motor, no ser convención de código |
| RF-34 | Una confirmación de carrito debe producir **una** venta con N líneas, no N ventas |
| RF-35 | El historial debe mostrar una tarjeta por venta, con acceso a su detalle línea a línea |

### 3.7 Base compartida y administración

| ID | Requisito |
|---|---|
| RF-36 | El catálogo, el stock y las ofertas deben residir en una única base compartida, no en cada dispositivo |
| RF-37 | El administrador debe poder dar de alta un producto sin recompilar ni inventar su código: el servidor lo asigna con secuencias |
| RF-38 | El administrador debe poder publicar una oferta con porcentaje de descuento y fecha de vigencia, o un combo con precio final fijo, nunca ambas cosas |
| RF-39 | Una oferta debe dejar de aplicarse por sí sola al vencer su vigencia, sin intervención manual |
| RF-40 | Dos ofertas no deben poder ocupar el mismo `orden` del mismo producto: la secuencia debe ser reproducible |
| RF-41 | Los cambios de catálogo, stock y ofertas deben llegar a los dispositivos conectados **sin que el usuario refresque** |
| RF-42 | Una compra en un dispositivo debe reducir la cantidad visible en los demás |
| RF-43 | La venta y el descuento de stock deben ejecutarse en una única transacción con `FOR UPDATE`, de modo que dos compras simultáneas no vendan la misma unidad |
| RF-44 | El sistema debe rechazar la venta de un producto agotado e informarlo; el producto agotado permanece visible pero no seleccionable |
| RF-45 | Un cliente debe tener **una sola oportunidad de oferta al día**; solo las compras que usaron oferta consumen el cupo |
| RF-46 | El día del límite debe calcularse en `America/Lima`, no en UTC |
| RF-47 | La aplicación no debe poder escribir directamente en ninguna tabla: sus escrituras deben pasar por funciones validadas del servidor |
| RF-48 | `fn_confirmar_carrito` no debe recibir el total —lo recalcula— ni el id del cliente, que saca del token |

---

## 4. Requisitos no funcionales

### 4.1 Rendimiento

| ID | Requisito | Medida objetivo |
|---|---|---|
| RNF-01 | El procesamiento por frame no debe degradar la fluidez de la interfaz | ~30 ms por frame |
| RNF-02 | La emoción estable debe estar disponible con latencia acotada | ~1,3 s (26 frames a ~20 fps) |
| RNF-03 | La estabilización debe reducir la oscilación respecto a la señal cruda | De 16 a 7 cambios en 20 s |
| RNF-04 | La ventana de observación debe dejar sitio a varias lecturas estables antes de decidir | 8 s ≈ 4–5 lecturas |
| RNF-05 | La decisión de oferta no debe bloquear el hilo de interfaz | Operaciones asíncronas |

### 4.2 Confiabilidad e integridad

| ID | Requisito |
|---|---|
| RNF-06 | La aritmética monetaria debe ser exacta: enteros en centavos, sin error de redondeo binario |
| RNF-07 | La integridad referencial debe ser garantizada por el motor, no por convención de código |
| RNF-08 | La negociación debe terminar siempre: la escalada es monótona y la escalera finita |
| RNF-09 | Salir de la pantalla no debe dejar temporizadores ni suscripciones vivas |

### 4.3 Privacidad y seguridad

| ID | Requisito |
|---|---|
| RNF-10 | Ningún frame ni imagen de rostro debe persistirse ni transmitirse |
| RNF-11 | El procesamiento del rostro debe ocurrir **en el dispositivo**; la etiqueta de emoción se consume en pantalla y tampoco viaja |
| RNF-12 | La clave que viaja dentro del APK debe conceder **solo lectura**: ninguna escritura puede ejecutarse sin pasar por una función validada |
| RNF-13 | La `service_role key` no debe viajar nunca dentro del APK |
| RNF-14 | La aplicación debe requerir un único permiso sensible (`CAMERA`), pedido al iniciar la primera negociación |

### 4.4 Usabilidad

| ID | Requisito |
|---|---|
| RNF-15 | La adaptación no debe exigir aprendizaje previo del usuario: no hay controles que operar |
| RNF-16 | La interfaz debe seguir Material 3 y mantener consistencia visual |
| RNF-17 | La grilla del catálogo debe ser responsiva, de 2 a 4 columnas según el ancho real (`LayoutBuilder`) |
| RNF-18 | Si falta la configuración del backend, la app debe explicarlo en pantalla en vez de fallar al arrancar |

### 4.5 Mantenibilidad y calidad

| ID | Requisito |
|---|---|
| RNF-19 | Las capas deben permanecer desacopladas: el módulo nativo solo produce emoción; el motor de decisión no conoce widgets ni cámara; la interfaz decide *cuándo* observar, nunca *qué* ofrecer |
| RNF-20 | El esquema debe estar versionado en migraciones SQL revisables y aplicables en orden |
| RNF-21 | La aplicación no debe construir SQL en cadenas: se comunica mediante funciones y vistas nombradas |
| RNF-22 | El proyecto debe mantener cobertura automatizada de las reglas críticas, en la capa donde vive cada una |
| RNF-23 | El código debe pasar `flutter analyze` sin observaciones |
| RNF-24 | El proyecto debe compilar y ejecutarse sin Android Studio, usando VS Code y las command-line tools del SDK |

### 4.6 Portabilidad

| ID | Requisito |
|---|---|
| RNF-25 | La aplicación debe ejecutarse en Android 8.0 (API 26) o superior, con cámara frontal |
| RNF-26 | La aplicación requiere red; sin ella debe explicarlo en pantalla, no quedar en blanco |
| RNF-27 | El backend debe poder ejecutarse en un PostgreSQL estándar, sin extensiones ni servicios propietarios |

---

## 5. Limitaciones

### 5.1 Limitaciones del modelo de emociones

| ID | Limitación | Impacto y mitigación |
|---|---|---|
| LIM-01 | El clasificador opera sobre 48×48 px y **confunde `triste` con `enojo`**: ambas expresiones bajan las cejas | Es el techo del modelo, no del pipeline. Ambas caen en el mismo grupo *desfavorable*, así que la confusión no altera la decisión. El preprocesamiento (grises, ecualización de histograma, recorte cuadrado) redujo el error de "enojo" con rostro neutral del 49% al 5% |
| LIM-02 | El modelo FER-2013 fue entrenado con un dataset genérico, no con usuarios del contexto real | La precisión puede variar según iluminación, tono de piel y ángulo |
| LIM-03 | La señal es intrínsecamente ruidosa frame a frame | Se compensa con dos filtros: ventana de 26 frames con histéresis (RF-07 a RF-09) y voto sobre las lecturas de la ventana de observación (RF-12) |
| LIM-04 | `disgust` y `fear` no tienen regla propia: se pliegan a `enojo` y `neutral` | Ambas caen en el grupo desfavorable, así que no cambian la decisión |

### 5.2 Limitaciones operativas

| ID | Limitación |
|---|---|
| LIM-05 | Sin rostro visible no hay contexto. Desde RF-27 esto deja de ser pasivo: pasados 3 s la negociación se declara PAUSADA, se congela la ventana y se avisa en pantalla. Si el cliente no vuelve nunca, queda pausada indefinidamente con la cámara encendida: no hay tiempo de expiración porque el requisito pide reanudación automática |
| LIM-06 | La orientación está fijada en vertical de forma deliberada; en horizontal el rostro sale del encuadre |
| LIM-07 | Requiere iluminación suficiente para que ML Kit localice el rostro |
| LIM-08 | `neutral` como desfavorable hace que la mayoría de clientes vea avanzar la escalera. Es una decisión de producto, y el primer sitio donde mirar si la tienda regala más margen del que quiere |
| LIM-09 | Un solo cliente activo por dispositivo, aunque varios dispositivos operen a la vez sobre la misma tienda |
| LIM-10 | Sin conexión no hay catálogo ni compra: no existe copia local (FA-04) |
| LIM-11 | El sistema espera que cada escalón rebaje más que el anterior, pero la base no puede garantizarlo: el administrador podría publicar 30% antes que 10% |

### 5.3 Limitaciones de alcance académico

| ID | Limitación |
|---|---|
| LIM-12 | El catálogo se administra a mano desde el panel; no se integra con un ERP |
| LIM-13 | La "venta" se registra en base de datos pero no ejecuta cobro ni logística |
| LIM-14 | No se registra la emoción que disparó cada oferta: no existe tabla de interacciones, y la etiqueta se consume en pantalla. En consecuencia no hay analítica de conversión por emoción — a cambio, ningún dato derivado del rostro queda almacenado |
| LIM-15 | Las mediciones de estabilidad provienen de sesiones de prueba del propio equipo, no de usuarios finales independientes |

---

## 6. Evidencia de cumplimiento

| Qué se verifica | Cómo | Dónde |
|---|---|---|
| Reglas de decisión y negociación | 181 pruebas Dart, sin dispositivo ni backend | `test/` |
| Estabilización de la emoción | 9 pruebas JUnit sobre la JVM | `android/app/src/test/` |
| Esquema, venta atómica, ofertas y permisos | 3 suites SQL contra un PostgreSQL 16 real, en CI | `supabase/tests/` |
| Requisito eliminatorio (la oferta avanza sola) | Prueba de widget que no toca ningún botón | `test/ui/tienda_screen_test.dart` |
| La clave pública no puede cambiar precios | Suite SQL que falla si la tienda queda abierta | `supabase/tests/04_seguridad.sql` |

Comando: `flutter test` · `cd android && ./gradlew testDebugUnitTest` ·
`PGURL=... bash supabase/tests/ejecutar.sh`

### Trazabilidad concepto del curso → verificación

| Concepto del curso | Requisitos que lo cubren | Verificación |
|---|---|---|
| Software adaptativo | RF-16, RF-18, RF-27 | Prueba automatizada del requisito eliminatorio |
| Adaptación al contexto | RF-01 a RF-05 | Expresión facial como variable de entorno |
| Procesamiento en tiempo real | RNF-01 a RNF-04 | ~30 ms/frame; emoción estable en ~1,3 s |
| Uso de capacidades del dispositivo | RF-01 a RF-03, RNF-11 | CameraX, ML Kit y TFLite, todo local |
| Diseño modular | RNF-19 | La decisión es Dart puro: 181 pruebas sin cámara ni red |
| Diseño responsivo | RNF-17 | Grilla de 2 a 4 columnas con `LayoutBuilder` |
| Datos compartidos y consistentes | RF-36, RF-42, RF-43 | Venta y stock en una transacción del servidor; `supabase/tests/01_ciclo_venta.sql` |
| Adaptación también por decisión humana | RF-37 a RF-40 | El administrador publica; la emoción decide el ritmo. `supabase/tests/02_catalogo_y_ofertas.sql` |

---

## 7. Referencias internas

| Documento | Contenido |
|---|---|
| [INFORME_TECNICO.md](INFORME_TECNICO.md) | Informe técnico de entrega: pipeline, arquitectura y verificación |
| [ARQUITECTURA.md](ARQUITECTURA.md) | Detalle de componentes y decisiones de arquitectura |
| [REQUISITOS_POR_INTEGRANTE.md](REQUISITOS_POR_INTEGRANTE.md) | Quién se responsabilizó de cada requisito y con qué evidencia |
| [GUIA_ESTUDIO.md](GUIA_ESTUDIO.md) | Repaso para la sustentación |
| [RETOS_EN_VIVO.md](RETOS_EN_VIVO.md) | Preparación del reto técnico en vivo |
| [../supabase/README.md](../supabase/README.md) | Puesta en marcha del backend, guía del administrador y pruebas SQL |
| [ESQUEMA_CORREGIDO.md](ESQUEMA_CORREGIDO.md) | Histórico: hallazgos G1–G9 y correcciones C1–C11 del modelo de datos |
