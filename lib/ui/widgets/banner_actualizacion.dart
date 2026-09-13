import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Franja fija arriba de la pantalla, sobre cualquier ruta: hay una version
/// nueva publicada y esta no es la que corre en el telefono.
///
/// Vive por encima del Navigator (ver `MyApp.builder` en main.dart) para que
/// se vea sin importar si el cliente esta en el login, la tienda o el
/// historial -- no depende de tener sesion abierta.
class BannerActualizacion extends StatelessWidget {
  const BannerActualizacion({
    super.key,
    required this.onActualizar,
    this.avance,
    this.error,
  });

  final VoidCallback onActualizar;

  /// Avance de la descarga en 0..1, o -1 cuando el servidor no dice cuanto
  /// pesa. Nulo mientras no se esta descargando.
  final double? avance;

  /// Por que fallo el ultimo intento, si fallo.
  final String? error;

  bool get _descargando => avance != null;

  String _textoAvance() {
    final a = avance!;
    return a < 0 ? 'Espera un momento...' : '${(a * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppTheme.navy,
      child: SafeArea(
        bottom: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.navy],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _descargando
                            ? 'Descargando la actualizacion'
                            : 'Actualizacion disponible',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        error ??
                            (_descargando
                                ? _textoAvance()
                                : 'Hay una version nueva de la tienda'),
                        style: textTheme.bodyMedium?.copyWith(
                          color: error != null
                              ? const Color(0xFFFCA5A5)
                              : Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      if (_descargando) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            // Negativo significa que el servidor no dijo
                            // cuanto pesa: barra indeterminada en vez de una
                            // clavada en cero, que parece colgada.
                            value: avance! < 0 ? null : avance,
                            minHeight: 4,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.25,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_descargando) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onActualizar,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text(error == null ? 'Actualizar' : 'Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.navy,
                      elevation: 0,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: textTheme.labelLarge?.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
