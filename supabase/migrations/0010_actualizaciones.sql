-- ============================================================================
-- 0010 - Aviso de actualizacion disponible
--
-- Una fila por rama con la ultima version compilada. El workflow de GitHub
-- Actions (.github/workflows/apk.yml) escribe aqui con la service_role key
-- justo despues de publicar cada APK; la app compara su propio build_sha
-- (inyectado al compilar, ver env.json) contra el de esta tabla y muestra un
-- banner de "Actualizar" cuando no coinciden.
--
-- Es lectura publica -- que haya una version nueva no es un secreto -- pero
-- solo service_role escribe: la clave publica va dentro del APK y nadie con
-- ella deberia poder mandarle a los clientes una URL de descarga propia.
-- ============================================================================

create table if not exists app_config (
  rama           text primary key,
  build_sha      text not null,
  apk_url        text not null,
  actualizado_en timestamptz not null default now()
);

alter table app_config enable row level security;

drop policy if exists p_lectura_publica on app_config;
create policy p_lectura_publica on app_config for select to anon, authenticated using (true);

grant select on app_config to anon, authenticated;
revoke insert, update, delete on app_config from anon, authenticated;
