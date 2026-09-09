import 'package:flutter/material.dart';
import '../../data/modelos/modelos.dart';
import '../../theme/app_theme.dart';
import 'imagen_producto.dart';

class ProductoCard extends StatelessWidget {
  const ProductoCard({
    super.key,
    required this.producto,
    required this.destacado,
    required this.seleccionado,
    required this.comprado,
    required this.estilo,
    required this.onTap,
  });

  final Producto producto;
  final bool destacado;
  final bool seleccionado;

  /// Ya comprado en esta sesion: no se vuelve a ofertar.
  final bool comprado;

  final EmotionStyle estilo;
  final VoidCallback onTap;


  (IconData, Color) get _visualCategoria {
    const iconos = [
      Icons.devices_other,
      Icons.chair_outlined,
      Icons.checkroom,
      Icons.spa_outlined,
      Icons.local_mall_outlined,
    ];
    const colores = [
      Color(0xFF0891B2),
      Color(0xFF7C3AED),
      Color(0xFFDB2777),
      Color(0xFF059669),
      Color(0xFFEA580C),
    ];
    final indice = (producto.tipoProducto ?? producto.codLoteProducto)
            .hashCode
            .abs() %
        iconos.length;
    return (iconos[indice], colores[indice]);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icono, color) = _visualCategoria;
    // El precio que se anuncia es el vigente: si el administrador publico una
    // oferta, el catalogo debe mostrarla ya aplicada. `precioLista` solo se
    // pinta tachado al lado, como referencia.
    final precio = (producto.precioVigenteCentavos / 100).toStringAsFixed(2);
    final precioLista = (producto.precioUnitarioCentavos / 100)
        .toStringAsFixed(2);

    final bordeColor = seleccionado
        ? Colors.amber
        : destacado
            ? estilo.color
            : AppTheme.border;
    final bordeAncho = seleccionado ? 3.0 : destacado ? 2.0 : 1.0;

    final sombra = seleccionado
        ? [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.6),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ]
        : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: sombra,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: bordeColor,
            width: bordeAncho,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? Colors.amber.withValues(alpha: 0.15)
                        : color.withValues(alpha: 0.10),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: ImagenProducto(
                          producto: producto,
                          respaldo: Icon(icono, size: 40, color: color),
                        ),
                      ),
                      // La promocion del administrador se anuncia en la
                      // esquina opuesta a las etiquetas de estado, para que no
                      // compitan por el mismo hueco.
                      if (producto.enOferta)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '-${producto.descuentoOferta}%',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (seleccionado)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Seleccionado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else if (comprado)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Comprado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else if (destacado)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: estilo.color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Para ti',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombreProducto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'S/$precio',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppTheme.success,
                          ),
                        ),
                        // Con una oferta vigente se muestran los dos precios:
                        // el tachado es lo que justifica el descuento.
                        if (producto.enOferta) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'S/$precioLista',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // El stock se pinta siempre, y lo actualiza el servidor por
                    // Realtime: si otro cliente compra la ultima unidad, este
                    // numero baja aqui sin que nadie refresque nada.
                    Text(
                      producto.totalDisponible <= 3
                          ? 'Quedan ${producto.totalDisponible}'
                          : '${producto.totalDisponible} disponibles',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: producto.totalDisponible <= 3
                            ? AppTheme.danger
                            : AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
