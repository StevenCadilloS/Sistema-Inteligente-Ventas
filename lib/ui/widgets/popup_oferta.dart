import 'package:flutter/material.dart';
import '../../decision/adaptation_engine.dart';
import '../../theme/app_theme.dart';
import 'imagen_producto.dart';

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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final precio =
        (oferta.producto.precioUnitarioCentavos / 100).toStringAsFixed(2);
    final precioFinal = (oferta.precioFinalCentavos / 100).toStringAsFixed(2);

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
                  ImagenProducto(
                    producto: oferta.producto,
                    ancho: 120,
                    alto: 120,
                    radio: 12,
                    respaldo: Container(
                      height: 120,
                      width: 120,
                      color: AppTheme.success.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 40,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    oferta.producto.nombreProducto,
                    style: textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Con descuento se muestra el precio de lista tachado
                      // junto al final: el que se cobra y se registra en
                      // detalleVenta es el final.
                      if (oferta.tieneDescuento) ...[
                        Text(
                          'S/$precio',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppTheme.mutedText,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'S/$precioFinal',
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (oferta.tieneDescuento) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.danger,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${oferta.descuentoPorcentaje}%',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    oferta.texto,
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${oferta.producto.totalDisponible} disponibles',
                    style: textTheme.bodyMedium?.copyWith(fontSize: 12),
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
                        child: OutlinedButton.icon(
                          onPressed: onRechazar,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('No, gracias'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.danger,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: AppTheme.danger,
                              width: 1.5,
                            ),
                          ),
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
