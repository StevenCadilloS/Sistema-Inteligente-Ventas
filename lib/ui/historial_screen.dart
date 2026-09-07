import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;

import '../data/database/app_database.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Interaccion> _interacciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    try {
      final interacciones = await (widget.db.select(widget.db.interacciones)
            ..orderBy([(i) => OrderingTerm.desc(i.timestamp)])
            ..limit(50))
          .get();

      if (mounted) {
        setState(() {
          _interacciones = interacciones;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _interacciones.isEmpty
              ? const Center(
                  child: Text(
                    'No hay interacciones registradas',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarHistorial,
                  child: ListView.builder(
                    itemCount: _interacciones.length,
                    itemBuilder: (context, index) {
                      final interaccion = _interacciones[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.deepPurple),
                            ),
                          ),
                          title: Text(
                            'Proceso: ${interaccion.idProcesoPersuasion}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Cliente: ${interaccion.codCliente}'),
                              if (interaccion.codGesto != null)
                                Text('Emocion: ${interaccion.codGesto}'),
                              if (interaccion.codEstrategia != null)
                                Text(
                                  'Estrategia: ${interaccion.codEstrategia}',
                                ),
                              Text(
                                'Interes: ${interaccion.nivelDeInteres}%',
                              ),
                            ],
                          ),
                          trailing: Text(
                            _formatearFecha(interaccion.timestamp),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
