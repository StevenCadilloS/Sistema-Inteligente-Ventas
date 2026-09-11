import 'package:flutter/material.dart';
import '../../data/modelos/modelos.dart';
import '../../decision/negociacion.dart';
import '../../theme/app_theme.dart';
import 'imagen_producto.dart';

class PopupOferta extends StatelessWidget {
  const PopupOferta({
    super.key,
    required this.negociacion,
    required this.mensaje,
    required this.lecturas,
    required this.onAceptar,
    required this.onRechazar,
    required this.onCerrar,
  });

  final Negociacion negociacion;
  final String mensaje;
  /// Lecturas estables acumuladas en la ventana de observacion en curso, o
  /// -1 si no hay camara.
  ///
  /// Se muestran para que se note que el sistema esta mirando: el detector
  /// tarda ~1,3 s por lectura y sin este contador el popup parece congelado.
  final int lecturas;

  bool get _sinCamara => lecturas < 0;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final producto = negociacion.producto;
    final escalon = negociacion.escalonActual;
    final hayRebaja = escalon != null;
    final precio = soles(producto.precioCentavos);
    final precioFinal = soles(negociacion.precioActualCentavos);

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
                            Icon(
                              _sinCamara
                                  ? Icons.videocam_off_outlined
                                  : lecturas > 0
                                      ? Icons.visibility_outlined
                                      : Icons.hourglass_empty,
                              size: 16,
                              color: _sinCamara
                                  ? AppTheme.mutedText
                                  : AppTheme.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _sinCamara ? 'sin camara' : '$lecturas',
                              style: textTheme.bodyMedium?.copyWith(
                                color: _sinCamara
                                    ? AppTheme.mutedText
                                    : AppTheme.success,
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
                    hayRebaja
                        ? 'Oferta ${escalon.orden} de ${negociacion.totalEscalones}'
                        : 'Precio normal',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedText,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ImagenProducto(
                    producto: producto,
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
                    producto.nombre,
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
                      if (hayRebaja) ...[
                        Text(
                          precio,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppTheme.mutedText,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        precioFinal,
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hayRebaja) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.danger,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            escalon.esCombo
                                ? escalon.nombreOferta
                                : '-${escalon.porcentajeDescuento}%',
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
                    mensaje,
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${producto.stock} disponibles',
                    style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
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
