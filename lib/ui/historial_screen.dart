import 'package:flutter/material.dart';

import '../data/modelos/modelos.dart';
import '../data/repositories/cliente_repository.dart';
import '../data/repositories/tienda_repository.dart';
import '../theme/app_theme.dart';

/// Historial de interacciones del cliente activo.
///
/// Antes hacia un join manual contra drift para resolver los nombres de gesto
/// y estrategia; ahora esos joins los resuelve PostgREST en la misma consulta
/// (ver SupabaseTiendaRepository.historial), asi que la pantalla solo pinta.
///
/// Se filtra por el cliente activo a proposito: la base es compartida y sin
/// ese filtro cada usuario veria las interacciones de todos los demas.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({
    super.key,
    required this.tienda,
    required this.clienteRepository,
  });

  final TiendaRepository tienda;
  final ClienteRepository clienteRepository;

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<InteraccionHistorial> _filas = const [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final codCliente = widget.clienteRepository.clienteActivo();
    if (codCliente == null) {
      setState(() {
        _cargando = false;
        _filas = const [];
      });
      return;
    }

    try {
      final filas = await widget.tienda.historial(codCliente);
      if (mounted) {
        setState(() {
          _filas = filas;
          _error = null;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _cargando = false;
        });
      }
    }
  }

  String _formatearFecha(DateTime fecha) =>
      '${fecha.day}/${fecha.month}/${fecha.year} '
      '${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Interacciones')),
      body: SafeArea(child: _cuerpo(context)),
    );
  }

  Widget _cuerpo(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40, color: AppTheme.mutedText),
              const SizedBox(height: 12),
              Text(
                'No se pudo leer el historial: $_error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _cargarHistorial,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filas.isEmpty) {
      return Center(
        child: Text(
          'No hay interacciones registradas',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: RefreshIndicator(
          onRefresh: _cargarHistorial,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _filas.length,
            itemBuilder: (context, index) => _tarjeta(context, _filas[index]),
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(BuildContext context, InteraccionHistorial fila) {
    final estilo = fila.nombreGesto != null
        ? EmotionStyle.of(fila.nombreGesto!)
        : null;

    return Card(
      key: ValueKey(fila.idProcesoPersuasion),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (estilo?.color ?? AppTheme.mutedText).withValues(
            alpha: 0.12,
          ),
          child: Icon(
            estilo?.icon ?? Icons.help_outline,
            color: estilo?.color ?? AppTheme.mutedText,
          ),
        ),
        title: Text(
          'Proceso ${fila.idProcesoPersuasion}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (fila.nombreProducto != null) Text(fila.nombreProducto!),
            Text(
              'Emocion: ${estilo?.label ?? "sin dato"}'
              '${fila.nombreEstrategia != null ? " · Estrategia: ${fila.nombreEstrategia}" : ""}',
            ),
            Text('Interes: ${fila.nivelDeInteres}%'),
          ],
        ),
        isThreeLine: true,
        trailing: Text(
          _formatearFecha(fila.fecha),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
      ),
    );
  }
}
