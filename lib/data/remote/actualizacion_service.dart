import 'package:supabase_flutter/supabase_flutter.dart';

import 'build_info.dart';

/// Una version mas nueva que la que corre en el dispositivo.
class ActualizacionDisponible {
  const ActualizacionDisponible({required this.apkUrl});

  /// URL estable del APK de esta rama (siempre el mismo archivo, GitHub
  /// Actions lo reemplaza en cada push -- ver .github/workflows/apk.yml).
  final String apkUrl;
}

/// Compara el build instalado contra `app_config`, que GitHub Actions
/// actualiza justo despues de publicar cada APK nueva.
///
/// Sin conexion, o si este build no vino de CI (un `flutter run` local sin
/// BUILD_SHA), no hay nada que comprobar: mejor no avisar que avisar mal.
class ActualizacionService {
  ActualizacionService(this._cliente, {String? shaActual, String? rama})
    : _shaActual = shaActual ?? BuildInfo.sha,
      _rama = rama ?? BuildInfo.rama;

  final SupabaseClient _cliente;
  final String _shaActual;
  final String _rama;

  Future<ActualizacionDisponible?> comprobar() async {
    if (_shaActual.isEmpty || _rama.isEmpty) return null;

    try {
      final fila = await _cliente
          .from('app_config')
          .select()
          .eq('rama', _rama)
          .maybeSingle();
      return evaluar(fila, _shaActual);
    } catch (_) {
      // Un fallo de red aqui no debe interrumpir el arranque de la tienda.
      return null;
    }
  }

  /// Logica de comparacion, separada de la consulta para poder probarla sin
  /// levantar un cliente de Supabase de verdad.
  static ActualizacionDisponible? evaluar(
    Map<String, dynamic>? fila,
    String shaActual,
  ) {
    if (fila == null) return null;

    final shaServidor = fila['build_sha'] as String?;
    final apkUrl = fila['apk_url'] as String?;
    if (shaServidor == null || apkUrl == null) return null;
    if (shaServidor == shaActual) return null;

    return ActualizacionDisponible(apkUrl: apkUrl);
  }
}
