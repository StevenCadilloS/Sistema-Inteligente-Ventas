/// Direccion del backend, inyectada al compilar.
///
/// No van en el codigo. El repositorio es publico y una clave escrita aqui
/// queda en el historial de git para siempre, aunque despues se borre del
/// archivo. Se pasan asi:
///
///     flutter run   --dart-define-from-file=env.json
///     flutter build apk --release --dart-define-from-file=env.json
///
/// donde `env.json` (ignorado por git, ver env.example.json) es:
///
///     { "SUPABASE_URL": "https://xxxx.supabase.co", "SUPABASE_ANON_KEY": "ey..." }
///
/// La clave anonima no es un secreto en el sentido estricto — viaja dentro del
/// APK y cualquiera puede extraerla. Lo que la vuelve inofensiva es que solo
/// concede lectura: quien la tenga puede ver el catalogo, no cambiar un precio
/// (ver las politicas RLS en supabase/migrations/0001_esquema.sql). Fuera del
/// codigo va igual, porque asocia la clave a un proyecto concreto y porque una
/// clave rotada no deberia obligar a un commit.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');

  /// Los proyectos nuevos de Supabase emiten una "publishable key"
  /// (`sb_publishable_...`); los anteriores, una "anon key" (un JWT). El SDK
  /// dejo obsoleto el parametro `anonKey` en favor de `publishableKey`, pero
  /// ambas clases de clave sirven. Se aceptan las dos variables de entorno
  /// para no obligar a los proyectos ya creados a migrar.
  static const _publishable = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _anon = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get clavePublica =>
      _publishable.isNotEmpty ? _publishable : _anon;

  static bool get configurado => url.isNotEmpty && clavePublica.isNotEmpty;
}
