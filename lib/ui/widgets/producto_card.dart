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
    final indice =
        (producto.categoria ?? '${producto.idProducto}').hashCode.abs() %
            iconos.length;
    return (iconos[indice], colores[indice]);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icono, color) = _visualCategoria;
    // El catalogo muestra siempre el precio normal. Las rebajas no viven
    // aqui: aparecen durante la negociacion, cuando el cliente selecciona el
    // producto y la camara empieza a leer su respuesta.
    final precio = soles(producto.precioCentavos);

    // Sin stock, pero sigue en el feed: se apaga y se marca en vez de
    // desaparecer, que es mas confuso cuando el catalogo se actualiza solo
    // por Realtime. No se puede seleccionar mientras este asi.
    final agotado = producto.stock <= 0;

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
          onTap: agotado ? null : onTap,
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
                      Opacity(
                        opacity: agotado ? 0.4 : 1,
                        child: Center(
                          child: ImagenProducto(
                            producto: producto,
                            respaldo: Icon(icono, size: 40, color: color),
                          ),
                        ),
                      ),
                      if (agotado)
                        Positioned.fill(
                          child: Center(
                            child: Transform.rotate(
                              angle: -0.35,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                color: Colors.amber,
                                alignment: Alignment.center,
                                child: const Text(
                                  'AGOTADO',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Que el producto tenga ofertas se anuncia, pero no
                      // cual ni de cuanto: el escalon que le toque a este
                      // cliente se decide durante la negociacion, y adelantar
                      // el 30% aqui haria que nadie se quedara en el 10%.
                      if (producto.tieneOfertas && !agotado)
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
                              'Negociable',
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
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          precio,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // El stock se pinta siempre, y lo actualiza el servidor por
                    // Realtime: si otro cliente compra la ultima unidad, este
                    // numero baja aqui sin que nadie refresque nada.
                    Text(
                      agotado
                          ? 'Agotado'
                          : producto.stock <= 3
                              ? 'Quedan ${producto.stock}'
                              : '${producto.stock} disponibles',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: agotado || producto.stock <= 3
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
