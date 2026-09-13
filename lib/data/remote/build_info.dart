/// Identidad de este build, inyectada al compilar (ver `.github/workflows/apk.yml`).
///
/// `sha` es el commit exacto con el que se compilo este APK. La app lo
/// compara contra `app_config.build_sha` (ver
/// supabase/migrations/0010_actualizaciones.sql) para saber si hay una
/// version mas nueva publicada: si no coinciden, hay que actualizar.
///
/// Vacio en un build local (`flutter run` sin pasar BUILD_SHA): en ese caso
/// [ActualizacionService] no comprueba nada, para no molestar a quien esta
/// desarrollando con un aviso que no aplica.
class BuildInfo {
  const BuildInfo._();

  static const sha = String.fromEnvironment('BUILD_SHA');
  static const rama = String.fromEnvironment('BUILD_RAMA');
}
