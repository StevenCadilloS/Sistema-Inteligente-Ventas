import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pantalla unica cuando la app se compilo sin las credenciales del backend.
///
/// Existe porque el modo de fallo es silencioso y confuso: sin URL a la que
/// conectarse, la tienda arranca, queda en blanco y despues lanza un error de
/// red que no dice que hacer. Es el tropiezo mas probable de un companero de
/// equipo que clona el repositorio y compila sin leer el README.
class AppSinBackend extends StatelessWidget {
  const AppSinBackend({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tienda Adaptativa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cloud_off, size: 56, color: AppTheme.mutedText),
                    const SizedBox(height: 16),
                    Text(
                      'Falta configurar el backend',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'El catalogo, el stock y las ofertas viven en la base '
                      'compartida. Esta copia se compilo sin la direccion del '
                      'proyecto, asi que no tiene a donde conectarse.',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.mutedText.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const SelectableText(
                        'flutter run --dart-define-from-file=env.json',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Copia env.example.json a env.json y pon ahi la URL y la '
                      'clave publica del proyecto. Los pasos completos, incluido '
                      'como levantar tu propio servidor, estan en '
                      'supabase/README.md.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
