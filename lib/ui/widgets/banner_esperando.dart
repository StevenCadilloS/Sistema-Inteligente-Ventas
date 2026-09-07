import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BannerEsperando extends StatelessWidget {
  const BannerEsperando({super.key, required this.detectando});

  final bool detectando;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              detectando ? Icons.auto_awesome : Icons.videocam_outlined,
              color: AppTheme.mutedText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                detectando
                    ? 'Sigue navegando: la oferta se arma sola con tu expresion.'
                    : 'Leyendo tu expresion con la camara frontal...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
