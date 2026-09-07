import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';
import '../../theme/app_theme.dart';

class ProductoCard extends StatelessWidget {
  const ProductoCard({
    super.key,
    required this.producto,
    required this.destacado,
    required this.seleccionado,
    required this.estilo,
    required this.onTap,
  });

  final Producto producto;
  final bool destacado;
  final bool seleccionado;
  final EmotionStyle estilo;
  final VoidCallback onTap;

  static const Map<String, String> _imagenes = {
    'P0000001': 'assets/products/P0000001_audifonos.jpg',
    'P0000002': 'assets/products/P0000002_smartwatch.jpg',
    'P0000003': 'assets/products/P0000003_parlante.jpg',
    'P0000004': 'assets/products/P0000004_cargador.jpg',
    'P0000005': 'assets/products/P0000005_laptop.jpg',
    'P0000006': 'assets/products/P0000006_sartenes.jpg',
    'P0000007': 'assets/products/P0000007_lampara.jpg',
    'P0000008': 'assets/products/P0000008_organizador.jpg',
    'P0000009': 'assets/products/P0000009_aspiradora.jpg',
    'P0000010': 'assets/products/P0000010_polo.jpg',
    'P0000011': 'assets/products/P0000011_zapatillas.jpg',
    'P0000012': 'assets/products/P0000012_mochila.jpg',
    'P0000013': 'assets/products/P0000013_casaca.jpg',
    'P0000014': 'assets/products/P0000014_skincare.jpg',
    'P0000015': 'assets/products/P0000015_secadora.jpg',
    'P0000016': 'assets/products/P0000016_perfume.jpg',
  };

  String? get _imagen => _imagenes[producto.codLoteProducto];

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
    final precio =
        (producto.precioUnitarioCentavos / 100).toStringAsFixed(2);

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
                        child: _imagen != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  _imagen!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(icono, size: 40, color: color);
                                  },
                                ),
                              )
                            : Icon(icono, size: 40, color: color),
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
                    Text(
                      'S/$precio',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppTheme.success,
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
