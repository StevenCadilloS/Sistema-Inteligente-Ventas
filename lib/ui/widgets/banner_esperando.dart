import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// La linea del feed que explica que esta haciendo la camara.
///
/// Depende de [camaraActiva] porque antes no dependia de nada: el banner se
/// pintaba siempre y anunciaba "Leyendo tu expresion con la camara frontal..."
/// durante toda la navegacion, con la camara apagada. Era literalmente falso,
/// y ademas contradecia al cartel de pausa cuando la negociacion se congelaba.
class BannerEsperando extends StatelessWidget {
  const BannerEsperando({
    super.key,
    required this.detectando,
    required this.camaraActiva,
    this.pausada = false,
  });

  /// Hay una emocion estable en pantalla ahora mismo.
  final bool detectando;

  /// Hay una negociacion con la camara encendida.
  final bool camaraActiva;

  /// La negociacion esta congelada por falta de rostro.
  final bool pausada;

  ({IconData icono, String texto, Color color}) get _estado {
    if (!camaraActiva) {
      return (
        icono: Icons.storefront_outlined,
        texto: 'Elige un producto: la oferta se arma con tu reaccion.',
        color: AppTheme.mutedText,
      );
    }
    if (pausada) {
      return (
        icono: Icons.pause_circle_outline,
        texto: 'Negociacion en pausa: no te vemos frente a la camara.',
        color: AppTheme.warning,
      );
    }
    if (detectando) {
      return (
        icono: Icons.auto_awesome,
        texto: 'Sigue navegando: la oferta se arma sola con tu expresion.',
        color: AppTheme.mutedText,
      );
    }
    return (
      icono: Icons.videocam_outlined,
      texto: 'Buscando tu rostro con la camara frontal...',
      color: AppTheme.mutedText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = _estado;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(estado.icono, color: estado.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                estado.texto,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
