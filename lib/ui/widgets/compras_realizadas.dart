import 'package:flutter/material.dart';

import '../../data/modelos/modelos.dart';
import '../../theme/app_theme.dart';

/// Una compra ya cerrada: el producto y lo que realmente se pago por el
/// (con descuento si la oferta lo tenia). Es exactamente lo que quedo
/// congelado en `detalleVenta`.
typedef CompraRealizada = ({Producto producto, int pagadoCentavos});

/// Compras de la sesion. NO es un carrito pendiente: cada linea ya se
/// registro como `venta` + `detalleVenta` al aceptar la oferta — aceptar es
/// lo que cierra el proceso de persuasion (asi lo mide el KPI 2). Por eso no
/// se puede eliminar lineas desde aqui: la bitacora de ventas no se borra.
class ComprasRealizadas extends StatelessWidget {
  const ComprasRealizadas({super.key, required this.compras});

  final List<CompraRealizada> compras;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (compras.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 48, color: AppTheme.mutedText),
              const SizedBox(height: 16),
              Text('Aun no compraste nada', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Toca un producto para verlo',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = compras.fold<int>(0, (suma, c) => suma + c.pagadoCentavos);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: AppTheme.success),
                const SizedBox(width: 8),
                Text('Tus compras', style: textTheme.titleLarge),
                const Spacer(),
                Text(
                  '${compras.length} '
                  '${compras.length == 1 ? 'producto' : 'productos'}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: compras.length,
                itemBuilder: (context, index) {
                  final compra = compras[index];
                  final pagado =
                      (compra.pagadoCentavos / 100).toStringAsFixed(2);
                  final lista =
                      (compra.producto.precioUnitarioCentavos / 100)
                          .toStringAsFixed(2);
                  final huboDescuento = compra.pagadoCentavos <
                      compra.producto.precioUnitarioCentavos;

                  return ListTile(
                    key: ValueKey('${compra.producto.codLoteProducto}_$index'),
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.success.withValues(alpha: 0.12),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: AppTheme.success),
                      ),
                    ),
                    title: Text(compra.producto.nombreProducto),
                    subtitle: huboDescuento
                        ? Text('Precio de lista S/$lista')
                        : null,
                    trailing: Text(
                      'S/$pagado',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppTheme.success,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total pagado', style: textTheme.titleMedium),
                Text(
                  'S/${(total / 100).toStringAsFixed(2)}',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
