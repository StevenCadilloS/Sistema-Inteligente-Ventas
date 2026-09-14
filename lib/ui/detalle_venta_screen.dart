import 'package:flutter/material.dart';

import '../data/modelos/modelos.dart';
import '../data/repositories/tienda_repository.dart';
import '../theme/app_theme.dart';

/// El detalle de una compra: sus lineas, con lo que se pago por cada una.
///
/// Llega el [VentaResumen] de la lista para pintar la cabecera al instante y
/// pide las lineas al servidor (fn_venta_detalle), que comprueba por el token
/// que la venta sea del cliente: la venta ajena se ve como "no encontrada",
/// igual que si el id no existiera.
class DetalleVentaScreen extends StatefulWidget {
  const DetalleVentaScreen({
    super.key,
    required this.tienda,
    required this.venta,
  });

  final TiendaRepository tienda;
  final VentaResumen venta;

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {
  List<LineaVenta> _lineas = const [];
  bool _cargando = true;
  bool _noEncontrada = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    try {
      final detalle = await widget.tienda.detalleVenta(widget.venta.idVenta);
      if (mounted) {
        setState(() {
          _lineas = detalle?.lineas ?? const [];
          _noEncontrada = detalle == null;
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
      appBar: AppBar(title: Text('Compra #${widget.venta.idVenta}')),
      body: SafeArea(child: _cuerpo(context)),
    );
  }

  Widget _cuerpo(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return _mensaje(
        context,
        icono: Icons.cloud_off,
        texto: 'No se pudo leer el detalle: $_error',
        accion: _cargarDetalle,
        etiquetaAccion: 'Reintentar',
      );
    }

    if (_noEncontrada || _lineas.isEmpty) {
      return _mensaje(
        context,
        icono: Icons.receipt_long,
        texto: 'Esta compra ya no esta disponible.',
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                _formatearFecha(widget.venta.fecha),
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.venta.resumenUnidades,
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _lineas.length,
                itemBuilder: (context, index) =>
                    _linea(context, _lineas[index]),
              ),
            ),
            // El total de la venta, siempre visible aunque la lista crezca.
            // Es el mismo numero que mostro la lista, no una suma nueva.
            SafeArea(
              top: false,
              child: Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: textTheme.titleMedium),
                      Text(
                        soles(widget.venta.totalCentavos),
                        style: textTheme.titleLarge?.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linea(BuildContext context, LineaVenta linea) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (linea.tuvoOferta ? AppTheme.danger : AppTheme.success)
              .withValues(alpha: 0.12),
          child: Icon(
            linea.tuvoOferta ? Icons.local_offer_outlined : Icons.check,
            color: linea.tuvoOferta ? AppTheme.danger : AppTheme.success,
          ),
        ),
        title: Text(linea.producto, style: textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Que oferta se aplico, si hubo alguna: es lo que explica por que
            // dos compras del mismo producto pueden costar distinto.
            Text(linea.nombreOferta ?? 'Precio normal'),
            Text('Cantidad: ${linea.cantidad}'),
          ],
        ),
        trailing: Text(
          soles(linea.precioTotalCentavos),
          style: textTheme.titleMedium?.copyWith(color: AppTheme.success),
        ),
      ),
    );
  }

  Widget _mensaje(
    BuildContext context, {
    required IconData icono,
    required String texto,
    VoidCallback? accion,
    String? etiquetaAccion,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 40, color: AppTheme.mutedText),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (accion != null && etiquetaAccion != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: accion,
                child: Text(etiquetaAccion),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
