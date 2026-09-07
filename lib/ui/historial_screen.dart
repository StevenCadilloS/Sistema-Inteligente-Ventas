import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;

import '../data/database/app_database.dart';
import '../theme/app_theme.dart';

class _FilaHistorial {
  const _FilaHistorial({
    required this.interaccion,
    required this.nombreGesto,
    required this.nombreEstrategia,
  });

  final Interaccion interaccion;
  final String? nombreGesto;
  final String? nombreEstrategia;
}

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<_FilaHistorial> _filas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  /// Join manual (sin query nombrada en queries.drift, ver
  /// docs/GUIA_STEVEN.md seccion 3 "Historial") solo para mostrar nombres
  /// legibles en vez de codGesto/codEstrategia crudos - no toca el esquema
  /// ni las tablas auditadas.
  Future<void> _cargarHistorial() async {
    try {
      final db = widget.db;
      final query = db.select(db.interacciones).join([
        leftOuterJoin(db.gestos, db.gestos.codGesto.equalsExp(db.interacciones.codGesto)),
        leftOuterJoin(
          db.estrategias,
          db.estrategias.codEstrategia.equalsExp(db.interacciones.codEstrategia),
        ),
      ])
        ..orderBy([OrderingTerm.desc(db.interacciones.timestamp)])
        ..limit(50);

      final filas = await query.get();
      final resultado = filas
          .map((fila) => _FilaHistorial(
                interaccion: fila.readTable(db.interacciones),
                nombreGesto: fila.readTableOrNull(db.gestos)?.nombreGesto,
                nombreEstrategia:
                    fila.readTableOrNull(db.estrategias)?.nombreEstrategia,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _filas = resultado;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    }
  }

  String _formatearFecha(int epochMillis) {
    final fecha = DateTime.fromMillisecondsSinceEpoch(epochMillis);
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Interacciones'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filas.isEmpty
                ? Center(
                    child: Text(
                      'No hay interacciones registradas',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: RefreshIndicator(
                        onRefresh: _cargarHistorial,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filas.length,
                          itemBuilder: (context, index) {
                            final fila = _filas[index];
                            final interaccion = fila.interaccion;
                            final estilo = fila.nombreGesto != null
                                ? EmotionStyle.of(fila.nombreGesto!)
                                : null;

                            return Card(
                              key: ValueKey(interaccion.id),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: (estilo?.color ??
                                          AppTheme.mutedText)
                                      .withValues(alpha: 0.12),
                                  child: Icon(
                                    estilo?.icon ?? Icons.help_outline,
                                    color: estilo?.color ?? AppTheme.mutedText,
                                  ),
                                ),
                                title: Text(
                                  'Proceso ${interaccion.idProcesoPersuasion}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Cliente: ${interaccion.codCliente}'),
                                    Text(
                                      'Emocion: ${estilo?.label ?? "sin dato"}'
                                      '${fila.nombreEstrategia != null ? " · Estrategia: ${fila.nombreEstrategia}" : ""}',
                                    ),
                                    Text('Interes: ${interaccion.nivelDeInteres}%'),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  _formatearFecha(interaccion.timestamp),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
