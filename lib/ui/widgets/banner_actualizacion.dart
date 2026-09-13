import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Franja fija arriba de la pantalla, sobre cualquier ruta: hay una version
/// nueva publicada y esta no es la que corre en el telefono.
///
/// Vive por encima del Navigator (ver `MyApp.builder` en main.dart) para que
/// se vea sin importar si el cliente esta en el login, la tienda o el
/// historial -- no depende de tener sesion abierta.
class BannerActualizacion extends StatelessWidget {
  const BannerActualizacion({super.key, required this.onActualizar});

  final VoidCallback onActualizar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tenemos una actualizacion para ti',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: onActualizar,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
