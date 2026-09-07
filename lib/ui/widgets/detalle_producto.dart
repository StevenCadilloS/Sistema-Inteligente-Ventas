import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';
import '../../theme/app_theme.dart';

class DetalleProducto extends StatelessWidget {
  const DetalleProducto({super.key, required this.producto, required this.onComprar});

  final Producto producto;
  final VoidCallback onComprar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final precio =
        (producto.precioUnitarioCentavos / 100).toStringAsFixed(2);
    final hayStock = producto.totalDisponible > 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(producto.nombreProducto, style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'S/$precio',
              style: textTheme.headlineMedium?.copyWith(
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hayStock
                  ? '${producto.totalDisponible} disponibles · ${producto.totalVendidos} vendidos'
                  : 'Sin stock por ahora',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: hayStock ? onComprar : null,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(hayStock ? 'Lo quiero' : 'Sin stock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
