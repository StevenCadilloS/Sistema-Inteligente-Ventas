import 'package:flutter/material.dart';

import '../../data/modelos/modelos.dart';
import '../../theme/app_theme.dart';

/// La hoja del carrito.
///
/// A diferencia de lo que era antes de 0011 -- una lista de compras ya
/// cerradas -- esto es un carrito pendiente: nada esta vendido hasta que el
/// cliente pulse "Confirmar compra". Cada linea se puede borrar, sumar o
/// restar unidades, y el total es la suma de lo acordado por linea.
///
/// El estado del carrito no vive aqui: la pantalla de la tienda lo tiene, y
/// esta hoja solo pinta lo que le llega y avisa que hacer. Asi el badge del
/// AppBar y la hoja son dos vistas del mismo dato, que no pueden
/// desincronizarse.
class CarritoHoja extends StatelessWidget {
  const CarritoHoja({
    super.key,
    required this.lineas,
    required this.confirmando,
    required this.onCantidad,
    required this.onEliminar,
    required this.onVaciar,
    required this.onConfirmar,
    required this.onSeguirComprando,
  });

  final List<LineaCarrito> lineas;

  /// Confirmacion en vuelo: los botones se apagan para no confirmar dos
  /// veces.
  final bool confirmando;

  /// Que hacer al ajustar una linea. [nuevaCantidad] 0 significa quitarla.
  final void Function(LineaCarrito linea, int nuevaCantidad) onCantidad;
  final void Function(LineaCarrito linea) onEliminar;
  final void Function() onVaciar;
  final void Function() onConfirmar;
  final void Function() onSeguirComprando;

  Widget _hoja(BuildContext context, Widget contenido) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 2),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: contenido),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (lineas.isEmpty) {
      return _hoja(
        context,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 48, color: AppTheme.mutedText),
              const SizedBox(height: 16),
              Text('Tu carrito esta vacio', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Negocia un producto y pulsa "Lo quiero" para agregarlo',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final unidades = lineas.fold<int>(0, (n, l) => n + l.cantidad);
    final total = lineas.fold<int>(0, (n, l) => n + l.totalCentavos);

    return _hoja(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: AppTheme.success),
                const SizedBox(width: 8),
                Text('Tu carrito', style: textTheme.titleLarge),
                const Spacer(),
                Text(
                  '$unidades '
                  '${unidades == 1 ? 'unidad' : 'unidades'}',
                  style: textTheme.bodyMedium,
                ),
                // La bitacora de ventas no se borra, pero el carrito si: aun
                // no es una venta, solo una intencion.
                IconButton(
                  tooltip: 'Vaciar carrito',
                  icon: const Icon(Icons.delete_sweep_outlined),
                  color: AppTheme.mutedText,
                  onPressed: confirmando ? null : onVaciar,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lineas.length,
                itemBuilder: (context, index) {
                  final linea = lineas[index];
                  final oferta = linea.idOferta != null;
                  final lista = soles(linea.producto.precioCentavos);

                  return ListTile(
                        key: ValueKey(
                          '${linea.producto.idProducto}_${linea.idOferta}',
                        ),
                        contentPadding: EdgeInsets.zero,
                        leading: LineaCantidad(linea: linea),
                        title: Text(
                          linea.producto.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Los precios van dentro de un FittedBox: la hoja de
                        // la app es mas angosta en un telefono, y una fila de
                        // precios rigida es la receta del desbordamiento.
                        subtitle: FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (oferta) ...[
                                Text(
                                  'antes $lista · ',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppTheme.mutedText,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 2),
                              ],
                              Text(
                                '${soles(linea.acordadoCentavos)} x ${linea.cantidad} = ${soles(linea.totalCentavos)}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: oferta
                                      ? AppTheme.success
                                      : AppTheme.mutedText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              tooltip: 'Quitar una unidad',
                              onPressed: confirmando
                                  ? null
                                  : () => onCantidad(
                                      linea, linea.cantidad - 1),
                            ),
                            Text('${linea.cantidad}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: 'Agregar una unidad',
                              onPressed: confirmando
                                  ? null
                                  : () => onCantidad(linea, linea.cantidad + 1),
                            ),
                          ],
                        ),
                      );
                },
              ),
            ),
            const Divider(),
            Row(
              children: [
                Text('Total', style: textTheme.titleMedium),
                const Spacer(),
                Text(
                  soles(total),
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: confirmando ? null : onSeguirComprando,
                    child: const Text('Seguir comprando'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: confirmando ? null : onConfirmar,
                    child: confirmando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirmar compra'),
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

/// El leading de la linea: cuantas unidades hay de ella.
///
/// La foto del producto quedaria a este tamanio aportando poco; lo que el
/// cliente necesita ver de un vistazo en una linea es la cantidad, y por eso
/// vive junto a los botones de ajustarla.
class LineaCantidad extends StatelessWidget {
  const LineaCantidad({super.key, required this.linea});

  final LineaCarrito linea;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppTheme.success.withValues(alpha: 0.12),
      child: Text(
        'x${linea.cantidad}',
        style: const TextStyle(
          color: AppTheme.success,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
