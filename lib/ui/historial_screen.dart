import 'package:flutter/material.dart';

import '../data/modelos/modelos.dart';
import '../data/repositories/tienda_repository.dart';
import '../theme/app_theme.dart';

/// Las compras del cliente de la sesion, una tarjeta por venta.
///
/// La pantalla solo pinta: la venta ya viene agrupada desde el servidor
/// (fn_historial), que ademas filtra por el cliente del token. Tocar una
/// tarjeta abre el detalle de esa compra; no hay forma de pedir el historial
/// de otra persona, ni por error.
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
  List<VentaResumen> _ventas = const [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {

    try {
      final ventas = await widget.tienda.historial();
      if (mounted) {
        setState(() {
          _ventas = ventas;
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

  /// Todo con dos cifras: sin el relleno, las 9:05 se veian como "9:5" y el
  /// 5 de marzo como "5/3".
  String _formatearFecha(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
        '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

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

    if (_ventas.isEmpty) {
      return Center(
        child: Text(
          'Aun no has comprado nada.',
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
            itemCount: _ventas.length,
            itemBuilder: (context, index) => _tarjeta(context, _ventas[index]),
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(BuildContext context, VentaResumen venta) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      key: ValueKey(venta.idVenta),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.success.withValues(alpha: 0.12),
          child: const Icon(Icons.receipt_long, color: AppTheme.success),
        ),
        title: Text('Compra #${venta.idVenta}', style: textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(venta.resumenUnidades),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              soles(venta.totalCentavos),
              style: textTheme.titleMedium?.copyWith(color: AppTheme.success),
            ),
            Text(
              _formatearFecha(venta.fecha),
              style: textTheme.bodyMedium?.copyWith(fontSize: 11),
            ),
          ],
        ),
        onTap: () async {
          await Navigator.pushNamed(context, '/historial/detalle',
              arguments: venta);
          // Al volver puede que la lista este desactualizada si algo cambio
          // en el servidor mientras tanto; recargar cuesta poco y evita
          // mostrar datos viejos.
          if (mounted) _cargarHistorial();
        },
      ),
    );
  }
}
