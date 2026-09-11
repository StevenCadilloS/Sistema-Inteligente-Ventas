import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BannerEsperando extends StatelessWidget {
  const BannerEsperando({
    super.key,
    required this.negociando,
    required this.camaraEncendida,
    required this.detectando,
    this.errorCamara,
  });

  final bool negociando;
  final bool camaraEncendida;
  final bool detectando;
  final String? errorCamara;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(_icono, color: _color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _mensaje,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icono {
    if (errorCamara != null) return Icons.no_photography_outlined;
    if (!negociando) return Icons.touch_app_outlined;
    if (!camaraEncendida) return Icons.videocam_off_outlined;
    return detectando ? Icons.auto_awesome : Icons.videocam_outlined;
  }

  Color get _color => errorCamara == null ? AppTheme.mutedText : AppTheme.danger;

  String get _mensaje {
    if (errorCamara != null) return errorCamara!;
    if (!negociando) {
      return 'Selecciona un producto para iniciar la evaluacion facial.';
    }
    if (!camaraEncendida) {
      return 'La camara esta apagada porque este producto no tiene ofertas activas.';
    }
    if (!detectando) {
      return 'Activando la camara frontal. Acepta el permiso si Android lo solicita.';
    }
    return 'Camara activa: la oferta se adapta con tu expresion.';
  }
}
