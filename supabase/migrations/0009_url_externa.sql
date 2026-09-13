-- ============================================================================
-- 0009 - Fija la URL externa que fn_url_imagen necesita
--
-- fn_url_imagen (0005) armaba la URL publica de una foto leyendo el ajuste de
-- Postgres `app.settings.api_external_url`, que nunca quedo configurado: sin
-- el, la funcion devolvia solo la mitad de la URL
-- (`/storage/v1/object/public/productos/archivo.jpg`, sin dominio), y la app
-- no podia descargar ninguna foto aunque la columna `imagen` no estuviera
-- vacia.
--
-- La primera version de este archivo intentaba `alter database postgres set
-- app.settings.api_external_url = ...`, pero el rol que usa el SQL Editor de
-- Supabase gestionado no tiene permiso para tocar configuraciones a nivel de
-- base de datos (42501: permission denied to set parameter). Redefinir la
-- funcion si esta permitido -- es una funcion propia, no un ajuste del
-- servidor -- asi que la URL queda fija dentro de ella en vez de leerse en
-- caliente.
--
-- Si el proyecto de Supabase cambiara alguna vez, este es el unico lugar que
-- hay que tocar (el valor sale de env.json / Project Settings -> API ->
-- Project URL).
--
-- Importante: esto NO corrige las imagenes que ya se asignaron con la URL
-- rota -- la funcion se ejecuto una vez al hacer el `update` y el resultado
-- quedo guardado tal cual. Hay que volver a correr
-- supabase/migrations/0008_imagenes_semilla.sql despues de este archivo.
-- ============================================================================

create or replace function fn_url_imagen(p_archivo text)
returns text
language plpgsql
stable
as
'
declare
  v_base   text := ''https://gczncetavisljftogbzu.supabase.co'';
  v_ruta   text := concat(chr(47), ''storage'', chr(47), ''v1'', chr(47),
                          ''object'', chr(47), ''public'', chr(47),
                          ''productos'', chr(47));
  v_limpio text;
begin
  if p_archivo is null then
    return null;
  end if;

  v_limpio := btrim(p_archivo);
  if length(v_limpio) = 0 then
    return null;
  end if;

  if lower(v_limpio) like concat(''http'', chr(37))
     and strpos(v_limpio, concat(chr(58), chr(47), chr(47))) > 0 then
    return v_limpio;
  end if;

  return concat(v_base, v_ruta, v_limpio);
end;
';

revoke all on function fn_url_imagen(text) from public;
grant execute on function fn_url_imagen(text) to authenticated, service_role;
