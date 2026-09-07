# Arquitectura — Sistema Inteligente de Ventas (Cierre de Ventas)

App Flutter/Dart con un módulo nativo Kotlin (cámara + ML) para detectar la emoción del
cliente en tiempo real y adaptar la oferta mostrada. Sin backend: todo corre on-device,
persistencia local en SQLite (`drift`).

Generado leyendo el código fuente (no con herramienta externa). Ver también el grafo de
conocimiento ya construido con `graphify` en `docs/graphify-out/` (`graph.html`,
`GRAPH_REPORT.md`) para explorar relaciones archivo a archivo.

## Diagrama de componentes

Verde = implementado y probado. Gris punteado = diseñado pero **aún no conectado**
(según `docs/GUIA_STEVEN.md` — el puente Kotlin↔Flutter y las 3 pantallas de UI).

```mermaid
flowchart TB
    subgraph NATIVO["Android nativo (Kotlin) · Fase 1 CONTEXTO"]
        direction TB
        CAM["CameraManager<br/>CameraX, camara frontal"]
        DET["EmotionDetector<br/>ML Kit (rostro) + TFLite FER-2013"]
        PROC["EmotionProcessor<br/>filtro de estabilidad, 10 frames"]
        CAM -->|ImageProxy| DET
        DET -->|EmotionResult crudo| PROC
    end

    subgraph BRIDGE["Puente Flutter to Kotlin -- PENDIENTE (Steven)"]
        direction TB
        HANDLER["EmotionChannelHandler.kt<br/>EventChannel.StreamHandler"]
        MAINACT["MainActivity.kt<br/>hoy: FlutterActivity vacia"]
        CHANNEL["emotion_channel.dart<br/>EventChannel listener"]
    end

    subgraph UI["UI Flutter -- PENDIENTE (Steven)"]
        direction TB
        LOGIN["Login / registro"]
        HOME["Principal<br/>oferta + aceptar/rechazar"]
        HIST["Historial (opcional)"]
    end

    subgraph DECISION["Decision (Dart) . Fases 3, 5, 6"]
        direction TB
        AE["AdaptationEngine<br/>decidirOferta()"]
        BANDIT["BanditOptimizer<br/>UCB1: seleccionarEstrategia()<br/>registrarRespuesta()"]
        AE -->|elige estrategia| BANDIT
    end

    subgraph DATOS["Datos (Dart) . Fases 2, 4"]
        direction TB
        REPO["ClienteRepository<br/>registrar / sesion"]
        DB[("AppDatabase (drift)<br/>10 tablas SQLite")]
        PREFS["SharedPreferences<br/>sesion activa"]
        REPO --> DB
        REPO --> PREFS
    end

    subgraph BATCH["Batch (Dart) . Fase 7, background"]
        direction TB
        SCHED["CierreDiarioScheduler<br/>WorkManager, 1x/dia"]
        RUNNER["BatchRunner<br/>ejecutarCierreDiario()<br/>6 recalculos, 1 transaccion"]
        SCHED --> RUNNER
    end

    PROC -->|ProcessedEmotion| HANDLER
    HANDLER --> MAINACT
    MAINACT -.EventChannel.-> CHANNEL
    CHANNEL -->|emotion, confidence| HOME
    LOGIN -->|registrar / iniciarSesion| REPO
    HOME -->|decidirOferta codCliente,emocion,nivelDeInteres| AE
    HOME -->|registrarRespuesta| BANDIT
    AE --> DB
    BANDIT --> DB
    RUNNER --> DB

    classDef implemented fill:#dcfce7,stroke:#16a34a,color:#14532d;
    classDef pending fill:#f1f5f9,stroke:#94a3b8,color:#475569,stroke-dasharray: 4 3;

    class CAM,DET,PROC,AE,BANDIT,REPO,DB,PREFS,SCHED,RUNNER implemented;
    class HANDLER,MAINACT,CHANNEL,LOGIN,HOME,HIST pending;
```

## Flujo de ejecución (caso principal)

```mermaid
sequenceDiagram
    actor Cliente
    participant Cam as CameraManager
    participant Det as EmotionDetector
    participant Proc as EmotionProcessor
    participant Bridge as EventChannel (pendiente)
    participant UI as Pantalla principal
    participant AE as AdaptationEngine
    participant Bandit as BanditOptimizer
    participant DB as AppDatabase (SQLite)

    Cliente->>Cam: rostro frente a la camara
    Cam->>Det: ImageProxy (frame)
    Det->>Proc: EmotionResult crudo (ML Kit + TFLite)
    Proc-->>Bridge: ProcessedEmotion (si isStable)
    Bridge-->>UI: emotion, confidence
    UI->>AE: decidirOferta(codCliente, emocion, nivelDeInteres)
    AE->>Bandit: seleccionarEstrategia() [UCB1]
    Bandit->>DB: SELECT interacciones/ventas agrupadas
    DB-->>Bandit: intentos/exitos por estrategia
    Bandit-->>AE: estrategia elegida
    AE->>DB: INSERT interaccion + UPDATE total_veces_mostrado (1 transaccion)
    AE-->>UI: Oferta(producto, texto, idProcesoPersuasion)
    Cliente->>UI: acepta / rechaza
    UI->>Bandit: registrarRespuesta(idProcesoPersuasion, aceptada)
    Bandit->>DB: INSERT venta + detalle_venta (si aceptada)
```

## Capas y responsables

| Capa | Componentes | Responsable | Estado |
|---|---|---|---|
| Contexto (cámara + ML) | `CameraManager`, `EmotionDetector`, `EmotionProcessor` | Juan | Implementado |
| Puente nativo↔Flutter | `EmotionChannelHandler.kt`, canal en `MainActivity.kt`, `emotion_channel.dart` | Steven | **Pendiente** (diseño listo en `GUIA_STEVEN.md`) |
| UI | Login, Principal, Historial | Steven | **Pendiente** |
| Decisión | `AdaptationEngine` (reglas por emoción), `BanditOptimizer` (UCB1) | Elvis | Implementado, probado |
| Datos / Auth | `ClienteRepository`, `AppDatabase` (drift, 10 tablas), `SharedPreferences` | Elvis | Implementado, probado |
| Batch | `CierreDiarioScheduler` (WorkManager), `BatchRunner` | Elvis | Implementado, probado; disparo diario recién conectado en `main.dart` |

## Notas de arquitectura

- **Sin backend ni red**: todo el pipeline (cámara → clasificación → decisión → persistencia)
  corre en el dispositivo. El modelo FER-2013 (`emotion_model.tflite`) va empaquetado como asset.
- **Reglas de adaptación** (`AdaptationEngine`): triste → sustituto más barato, feliz → premium,
  sorpresa → producto poco mostrado, neutral → producto más mostrado, enojo → cambia de categoría
  + el más barato de ella.
- **Aprendizaje en vivo vs batch**: `BanditOptimizer` recalcula éxitos/intentos por estrategia
  *en cada decisión* directo desde `interacciones`/`ventas` (UCB1). El `BatchRunner` diario
  actualiza columnas derivadas (`totalVecesAplicada`, `ventasGeneradas`, etc.) que son
  exclusivas para KPIs de presentación — deliberadamente no se cruzan con el cálculo en vivo.
  Ver `docs/PLAN_ELVIS.md` sección 6.
- **`main.dart` actual** todavía es la plantilla de `flutter create` + el disparo del cierre
  diario; no está conectado a `ClienteRepository`/`AdaptationEngine`/`BanditOptimizer` — ese
  cableado es justamente el trabajo pendiente de Steven (`docs/GUIA_STEVEN.md`).
- **`id_proceso_persuasion`** es la clave que conecta un intento de persuasión
  (`interacciones`) con su cierre (`ventas`) — corrección C1 documentada en
  `docs/ESQUEMA_CORREGIDO.md`, sin la cual no se podría medir conversión.

## Cómo verlo

- GitHub y VS Code (extensión *Markdown Preview Mermaid Support* o el preview nativo de
  Markdown) renderizan los bloques ` ```mermaid ` de este archivo directamente.
- Para explorar relaciones archivo a archivo con más detalle: `graphify query "<pregunta>"`
  sobre el grafo ya construido en `docs/graphify-out/`.
