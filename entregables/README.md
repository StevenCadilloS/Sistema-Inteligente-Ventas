# Entregables — Taller 1

Documentación del proyecto **Tienda Adaptativa**, para el Taller 1 de Desarrollo de una
Aplicación Adaptativa (UNI FIIS, 2026-2).

El PDF del taller (§5) pide dos entregables: el **repositorio con el código fuente** —que
es este mismo— y un **documento técnico de máximo 2 páginas**, que es el primero de la
lista.

## El entregable principal

| Documento | Qué es |
|---|---|
| **[INFORME_TECNICO.md](INFORME_TECNICO.md)** | **El documento técnico que pide el taller.** Las 7 secciones de la rúbrica: descripción, contexto, comportamiento adaptativo, pipeline, arquitectura, tecnologías y ubicación del código |

## Documentación de respaldo

| Documento | Qué es |
|---|---|
| [ARQUITECTURA.md](ARQUITECTURA.md) | Componentes, diagramas de flujo y decisiones de arquitectura |
| [REQUISITOS.md](REQUISITOS.md) | Objetivos, alcances, requisitos funcionales y no funcionales, limitaciones |
| [REQUISITOS_POR_INTEGRANTE.md](REQUISITOS_POR_INTEGRANTE.md) | Quién se responsabilizó de cada requisito, verificado contra el historial de git |

## Preparación de la sustentación

| Documento | Qué es |
|---|---|
| [GUIA_ESTUDIO.md](GUIA_ESTUDIO.md) | Repaso para las partes 1 a 3 de la sustentación: el guion de 3 minutos, el pipeline mapeado a archivos y las preguntas probables |
| [RETOS_EN_VIVO.md](RETOS_EN_VIVO.md) | Parte 4: los cinco tipos de reto técnico del PDF, con dónde tocar cada uno |

## Documentos históricos

Describen etapas anteriores del proyecto y **no reflejan el código actual**. Se conservan
como registro de decisiones; cada uno lleva un aviso arriba explicando qué quedó obsoleto.

| Documento | De qué etapa |
|---|---|
| [ESQUEMA_CORREGIDO.md](ESQUEMA_CORREGIDO.md) | Auditoría del diseño original de la base (G1–G9, C1–C11). Sus conclusiones sí se aplicaron, pero sobre PostgreSQL |
| [MODELO_ANDROID_ROOM.md](MODELO_ANDROID_ROOM.md) | Traducción del esquema a Room/SQLite, que nunca se implementó |
| [PLAN_TALLER01.md](PLAN_TALLER01.md) | Plan original con Jetpack Compose, Room, Hilt y WorkManager |
| [PLAN_ELVIS.md](PLAN_ELVIS.md) | Plan de trabajo de la etapa de SQLite local y aprendizaje UCB1 |
| [GUIA_STEVEN.md](GUIA_STEVEN.md) | Guía de integración de esa misma etapa |
| [graphify-out/](graphify-out/) | Grafo de conocimiento generado el 2026-09-05 |

---

Fuera de esta carpeta: el [README del repositorio](../README.md) tiene las instrucciones
para compilar y ejecutar, y [supabase/README.md](../supabase/README.md) la puesta en marcha
del backend y la guía de administración. El material de origen del curso (los PDF y
documentos del diseño de base de datos) está en [docs/](../docs/).
