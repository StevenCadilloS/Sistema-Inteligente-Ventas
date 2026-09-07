import 'package:flutter/material.dart';
import '../../decision/adaptation_engine.dart';
import '../../theme/app_theme.dart';

class PopupOferta extends StatelessWidget {
  const PopupOferta({
    super.key,
    required this.oferta,
    required this.mensaje,
    required this.segundosRestantes,
    required this.onAceptar,
    required this.onRechazar,
    required this.onCerrar,
  });

  final Oferta oferta;
  final String mensaje;
  final int segundosRestantes;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;
  final VoidCallback onCerrar;

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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final precio =
        (oferta.producto.precioUnitarioCentavos / 100).toStringAsFixed(2);
    final imagen = _imagenes[oferta.producto.codLoteProducto];

    return Stack(
      children: [
        GestureDetector(
          onTap: onCerrar,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 16, color: AppTheme.success),
                            const SizedBox(width: 4),
                            Text(
                              '${segundosRestantes}s',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onCerrar,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mensaje,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedText,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imagen != null
                        ? Image.asset(
                            imagen,
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 120,
                                width: 120,
                                color: AppTheme.success.withValues(alpha: 0.1),
                                child: const Icon(Icons.shopping_bag_outlined,
                                    size: 40, color: AppTheme.success),
                              );
                            },
                          )
                        : Container(
                            height: 120,
                            width: 120,
                            color: AppTheme.success.withValues(alpha: 0.1),
                            child: const Icon(Icons.shopping_bag_outlined,
                                size: 40, color: AppTheme.success),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    oferta.producto.nombreProducto,
                    style: textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'S/$precio',
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    oferta.texto,
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (oferta.estrategia != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Estrategia: ${oferta.estrategia!.nombreEstrategia}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onAceptar,
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('Lo quiero'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRechazar,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.mutedText,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: AppTheme.border),
                          ),
                          child: const Text('Ahora no'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
