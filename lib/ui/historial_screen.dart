import 'package:flutter/material.dart';

import '../data/modelos/modelos.dart';
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
  });

  final TiendaRepository tienda;

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<CompraHistorial> _filas = const [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {

    try {
      final filas = await widget.tienda.historial();
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
      appBar: AppBar(title: const Text('Mis compras')),
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

  Widget _tarjeta(BuildContext context, CompraHistorial fila) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      key: ValueKey(fila.idVenta),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (fila.tuvoOferta ? AppTheme.danger : AppTheme.success)
              .withValues(alpha: 0.12),
          child: Icon(
            fila.tuvoOferta ? Icons.local_offer_outlined : Icons.check,
            color: fila.tuvoOferta ? AppTheme.danger : AppTheme.success,
          ),
        ),
        title: Text(fila.producto, style: textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Que oferta se aplico, si hubo alguna: es lo que explica por que
            // dos compras del mismo producto pueden costar distinto.
            Text(fila.nombreOferta ?? 'Precio normal'),
            if (fila.cantidad > 1) Text('Cantidad: ${fila.cantidad}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              soles(fila.totalCentavos),
              style: textTheme.titleMedium?.copyWith(color: AppTheme.success),
            ),
            Text(
              _formatearFecha(fila.fecha),
              style: textTheme.bodyMedium?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
