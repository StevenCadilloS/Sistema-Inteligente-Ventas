# Taller 01 — Aplicación Adaptativa "Cierre de Ventas"
Plan de implementación

## Contexto

El curso *Desarrollo Adaptativo e Integrado del Software* pide (`docs/Taller 01.pdf`) una **app móvil que adapte su comportamiento automáticamente según el contexto**, con una regla eliminatoria: *"No se considerará adaptativo si el comportamiento requiere intervención manual del usuario."* Se evalúa sobre 20: funcionalidad adaptativa (8), implementación técnica (6), presentación (6).

El dominio es el **Sistema Cierre de Ventas** del curso de Base de Datos, cuyo diseño ya fue auditado y corregido en [ESQUEMA_CORREGIDO.md](ESQUEMA_CORREGIDO.md) (hallazgos G1–G9) y traducido a Room en [MODELO_ANDROID_ROOM.md](MODELO_ANDROID_ROOM.md).

Decisiones tomadas:
- **Alcance BD: completo**, incluyendo batch y KPIs (aunque no suma al rubro del taller, sirve para la presentación y reaprovecha el trabajo del curso de BD).
- **Motor de decisión por reglas** ahora, con la ruta TFLite/Kaggle enchufable después.
- **Generación de texto: plantillas locales por defecto + Claude como enriquecimiento.** La adaptación nunca depende de la red — y la caída a plantillas se demuestra en vivo como evidencia de adaptación.
- Los 15 archivos ya creados en `android/` se conservan y se ajustan.

**Resultado esperado:** una app que corre en un celular físico, cambia sola de estrategia de venta, densidad visual, tema y layout ante cambios de batería, red, luz, orientación e interacción del usuario; registra cada interacción en la BD corregida; y calcula los 4 KPIs.

---

## Estado actual

Ya existen y se conservan (15 archivos):

| Ruta | Estado |
|---|---|
| `android/settings.gradle.kts`, `build.gradle.kts`, `gradle/libs.versions.toml`, `app/build.gradle.kts` | Completos. Compose + Room + Hilt + WorkManager + TFLite + SDK de Anthropic |
| `app/src/main/AndroidManifest.xml` | Completo |
| `context/model/ContextSignals.kt`, `context/ContextProvider.kt` | Completos |
| `context/providers/` — Battery, Connectivity, AmbientLight, Orientation, Interaction | Completos. Todos con `callbackFlow` + `awaitClose` |
| `context/ContextAggregator.kt` | Completo |
| `adaptive/model/AdaptiveModels.kt`, `adaptive/processing/ContextProcessor.kt` | Completos |

Falta: DI, motor de decisión, pipeline, UI, Room, batch, KPIs, generación de texto, entregables.

---

## Fase 1 — Pipeline adaptativo end-to-end (lo que se califica)

Objetivo: demo funcionando en el celular con datos en memoria, antes de tocar la BD.

**Archivos nuevos**
- `di/AppModule.kt` — Hilt: `@ApplicationScope` (`CoroutineScope(SupervisorJob() + Dispatchers.Default)`), binds del motor de decisión y del generador de texto.
- `adaptive/decision/DecisionEngine.kt` — interfaz `fun decide(features: ContextFeatures): AdaptationDecision`.
- `adaptive/decision/RuleBasedDecisionEngine.kt` — política determinista (tabla abajo).
- `adaptive/AdaptivePipeline.kt` — une las 4 etapas: `aggregator.observe().map(processor::process).map(engine::decide).distinctUntilChanged()`.
- `ui/MainActivity.kt`, `ui/SalesViewModel.kt`, `ui/SalesScreen.kt`, `ui/theme/Theme.kt`
- `ui/components/EvidencePanel.kt` — muestra en vivo contexto → features → decisión → *por qué*. Es la evidencia para el informe y el guion de la presentación.

**Política de adaptación (`RuleBasedDecisionEngine`)**

| Condición detectada | Adaptación automática |
|---|---|
| Batería ≤15% o modo ahorro | `AUSTERE`: sin imágenes ni animaciones, sin llamada al LLM, muestreo de sensores más lento |
| Batería ≤30% | `STANDARD`: imágenes en baja resolución |
| Sin red | Motor local + plantilla local; interacciones se encolan para sincronizar |
| Red medida (celular) | `STANDARD`, LLM con `maxTokens` reducido |
| WiFi + batería OK | `RICH`: imágenes, animaciones, pitch generado por Claude |
| Luz < 10 lux | Tema oscuro |
| Landscape | Layout de 2 columnas (comparador) |
| `engagement` > 70 sostenido | Escala a `ESTRATEGIA_CIERRE` (E0000003) + CTA |
| `engagement` < 30 | Cambia a `ESTRATEGIA_ALTERNATIVO` (E0000008) |

Cada rama escribe su `reason`, que el panel de evidencia muestra textualmente.

**Pruebas (JUnit puro, sin emulador)**
- `ContextProcessorTest` — umbrales de batería, red medida, lux, y suavizado EMA del engagement.
- `RuleBasedDecisionEngineTest` — una prueba por fila de la tabla.

---

## Fase 2 — Persistencia (esquema corregido completo)

Implementa las 10 entidades de [MODELO_ANDROID_ROOM.md](MODELO_ANDROID_ROOM.md) §3 **tal como están ahí** (ya incorporan las correcciones C1–C11: `idProcesoPersuasion` en ambas bitácoras, `MAESTRA_GESTOS`, `tipoCliente` en clientes, precio con snapshot, FKs nullables sin el centinela `00000000`).

- `data/local/entity/` — catálogos (4), maestras (3), bitácoras (3).
- `data/local/dao/` — `InteraccionDao`, `VentaDao`, `CatalogoDao`, `KpiDao`, `BatchDao`.
- `data/local/AppDatabase.kt` — `exportSchema = true`; el JSON generado en `app/schemas/` es entregable.
- `data/local/DatabaseSeeder.kt` — `RoomDatabase.Callback` que siembra catálogos **antes** de cualquier bitácora (si no, las FKs fallan), más los datos de muestra del Primer y Segundo Caso de `TABLAS.docx` para validar los KPIs contra el ejercicio en papel.
- `data/repository/InteraccionRepository.kt` — persiste cada adaptación como una fila de `bitacora_interacciones` con el `nivel_de_interes` que calculó el pipeline.

El `SalesViewModel` pasa a leer productos y estrategias de Room en vez de la lista en memoria de la Fase 1.

---

## Fase 3 — Generación de texto adaptativa

- `llm/PitchGenerator.kt` — `suspend fun generate(request: PitchRequest): String`.
- `llm/TemplatePitchGenerator.kt` — plantillas locales por estrategia. **Siempre disponible**, sin red.
- `llm/ClaudePitchGenerator.kt` — SDK `com.anthropic:anthropic-java`, modelo `claude-opus-5`, `OutputConfig.effort(LOW)` y `maxTokens` bajo por latencia; llamada en `Dispatchers.IO`.
- `llm/AdaptivePitchGenerator.kt` — decorador que enruta según `decision.allowRemoteGeneration`, con timeout y caída a plantilla ante cualquier fallo. **Este objeto es la evidencia de adaptación más vistosa de la demo.**

Key en `local.properties` (`anthropic.api.key`), leída por `BuildConfig`. Riesgo documentado en el README: la key queda embebida en el APK, así que se usa una key con límite de gasto y no se distribuye el binario.

---

## Fase 4 — Batch y KPIs

- `work/CierreDiarioWorker.kt` — `CoroutineWorker` con Hilt, periódico diario, `setRequiresBatteryNotLow(true)`.
- `BatchDao.ejecutarCierreDiario()` — `@Transaction` con los 4 UPDATE de [MODELO_ANDROID_ROOM.md](MODELO_ANDROID_ROOM.md) §5, **con la corrección D1 aplicada** (`total_veces_aplicada` agrupa por `cod_estrategia`, no por `cod_cliente`).
- `KpiDao` — los 4 KPIs y la `@DatabaseView v_cierres_por_tipo_producto` de §4 (reemplaza el grupo repetitivo que violaba 1NF).
- `ui/KpiScreen.kt` — pantalla de indicadores.

---

## Fase 5 — Entregables

- `android/README.md` — descripción, cómo ejecutar, tecnologías, configuración de `local.properties`, y la nota de seguridad de la API key.
- `docs/INFORME_TALLER01.md` — 1 página con las 6 secciones exactas que pide el PDF: descripción, contexto y variables, lógica de adaptación, pipeline, evidencia, justificación técnica.
- `.gitignore` — debe excluir `local.properties`.

---

## Verificación

**Automática:** `./gradlew test` — las pruebas de `ContextProcessor` y `RuleBasedDecisionEngine` corren sin emulador.

**En el celular** (guion de demo, cada comando dispara una adaptación visible sin tocar la pantalla):

```bash
adb shell dumpsys battery set level 10    # -> modo AUSTERE, sin imágenes, sin Claude
adb shell dumpsys battery reset           # -> vuelve a RICH
adb shell svc wifi disable                # -> cae a plantilla local, encola interacciones
adb shell settings put global airplane_mode_on 1
```
- Tapar el sensor de luz con el dedo → tema oscuro solo.
- Rotar el equipo → layout de 2 columnas.
- Mirar fija una ficha ~10 s → sube `engagement` → cambia a estrategia de cierre.

El panel de evidencia debe reflejar cada transición con su `reason`, y `bitacora_interacciones` debe tener una fila nueva por cada cambio.

**Contra el ejercicio en papel:** con los datos sembrados del Primer y Segundo Caso, los KPIs de `KpiDao` deben dar el mismo resultado que `TABLAS.docx`.

---

## Riesgos

1. **El alcance BD completo (Fases 2 y 4) no suma al rubro del taller.** Por eso la Fase 1 va primero y deja una demo evaluable; si el tiempo aprieta, se recorta desde el final.
2. **Latencia de Claude** (~1-3 s con Opus): por eso nunca bloquea la adaptación, solo enriquece el texto. Si prefieres menor latencia, `claude-haiku-4-5` es la alternativa — es tu decisión de costo/calidad.
3. **Emulador vs celular**: el sensor de luz no existe en la mayoría de emuladores. El proveedor ya degrada a `Unavailable`, pero la demo del tema oscuro exige equipo físico.
