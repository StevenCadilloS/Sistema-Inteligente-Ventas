import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChipEmocion extends StatelessWidget {
  const ChipEmocion({
    super.key,
    required this.estilo,
    required this.detectando,
    required this.confianza,
  });

  final EmotionStyle estilo;
  final bool detectando;
  final double confianza;

  @override
  Widget build(BuildContext context) {
    final color = detectando ? estilo.color : AppTheme.mutedText;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(detectando ? estilo.icon : Icons.videocam_outlined,
                size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              detectando
                  ? '${estilo.label} ${(confianza * 100).toStringAsFixed(0)}%'
                  : 'Leyendo...',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
