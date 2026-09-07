import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';
import '../../theme/app_theme.dart';

class CarritoCompras extends StatelessWidget {
  const CarritoCompras({
    super.key,
    required this.carrito,
    required this.onEliminar,
  });

  final List<Producto> carrito;
  final Function(int) onEliminar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (carrito.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 48, color: AppTheme.mutedText),
              const SizedBox(height: 16),
              Text('Tu carrito está vacío',
                  style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Tocá un producto para agregarlo',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = carrito.fold<double>(
      0,
      (suma, p) => suma + p.precioUnitarioCentavos / 100,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: AppTheme.success),
                const SizedBox(width: 8),
                Text('Mi carrito', style: textTheme.titleLarge),
                const Spacer(),
                Text(
                  '${carrito.length} ${carrito.length == 1 ? 'producto' : 'productos'}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: carrito.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final producto = carrito[index];
                  final precio = (producto.precioUnitarioCentavos / 100)
                      .toStringAsFixed(2);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.success.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: AppTheme.success),
                      ),
                    ),
                    title: Text(
                      producto.nombreProducto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'S/$precio',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.mutedText, size: 20),
                          onPressed: () => onEliminar(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: textTheme.titleMedium),
                  Text(
                    'S/${total.toStringAsFixed(2)}',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
