-- ============================================================================
-- 0009 - Configura la URL externa que fn_url_imagen necesita
--
-- fn_url_imagen (0005) arma la URL publica de una foto leyendo el ajuste de
-- Postgres `app.settings.api_external_url`. Ese ajuste nunca se dejo
-- configurado en el proyecto: sin el, la funcion devolvia solo la mitad de
-- la URL (`/storage/v1/object/public/productos/archivo.jpg`, sin dominio), y
-- la app no podia descargar ninguna foto aunque la columna `imagen` no
-- estuviera vacia.
--
-- El valor es la URL del proyecto tal como aparece en env.json
-- (SUPABASE_URL) y en Project Settings -> API -> Project URL. Si el proyecto
-- de Supabase cambiara alguna vez, este es el unico lugar que hay que tocar.
--
-- ALTER DATABASE aplica a las conexiones NUEVAS, no a la sesion que lo
-- ejecuta: tras correr esto, hay que abrir una consulta nueva en el SQL
-- Editor (o esperar a que la actual se reconecte) para que fn_url_imagen ya
-- devuelva la URL completa.
-- ============================================================================

alter database postgres
  set app.settings.api_external_url = 'https://gczncetavisljftogbzu.supabase.co';
