import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TituloFeed extends StatelessWidget {
  const TituloFeed({super.key, required this.estilo, required this.detectando});

  final EmotionStyle estilo;
  final bool detectando;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Para ti ahora', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          detectando
              ? 'Orden ajustado a tu expresion: ${estilo.label.toLowerCase()}'
              : 'Orden estandar de la tienda',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
