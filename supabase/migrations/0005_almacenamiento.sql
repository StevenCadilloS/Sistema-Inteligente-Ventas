-- ============================================================================
-- 0005 - Imagenes de los productos en Supabase Storage
--
-- Hasta aqui `productos.imagen` solo podia nombrar un archivo empaquetado en
-- el APK. Eso ata el catalogo a la version instalada: para cambiar una foto
-- habia que recompilar y redistribuir la app, y un producto que el
-- administrador creara desde el panel no tenia forma de tener imagen.
--
-- Con un bucket publico, `imagen` guarda una URL y la foto se cambia desde el
-- panel. La columna no cambia de tipo: ya aceptaba URL completa, asi que los
-- dos modos conviven — util para migrar sin prisa.
--
-- Por que publico y no privado: el catalogo se ve sin iniciar sesion, asi que
-- sus fotos no son un secreto. Un bucket privado obligaria a firmar cada URL
-- y a renovarla al caducar, para proteger algo que cualquiera puede ver
-- abriendo la tienda. Lo que si esta cerrado es la ESCRITURA.
-- ============================================================================

-- El esquema `storage` solo existe en Supabase. Fuera (Postgres local, CI)
-- esta migracion no tiene nada que hacer y se salta entera, igual que las
-- politicas de administrador de 0001.
do $do$
begin
  if not exists (select 1 from information_schema.schemata where schema_name = 'storage') then
    raise notice 'Sin esquema storage: se omite (normal fuera de Supabase)';
    return;
  end if;

  -- --------------- EL BUCKET ---------------
  --
  -- `public = true` solo afecta a la lectura: cualquiera con la URL ve la
  -- foto. Subir, reemplazar o borrar sigue exigiendo ser administrador.
  insert into storage.buckets (id, name, public)
  values ('productos', 'productos', true)
  on conflict (id) do update set public = true;

  -- --------------- LECTURA: PUBLICA ---------------

  execute $sql$
    drop policy if exists p_productos_lectura on storage.objects
  $sql$;
  execute $sql$
    create policy p_productos_lectura on storage.objects
      for select to anon, authenticated
      using (bucket_id = 'productos')
  $sql$;

  -- --------------- ESCRITURA: SOLO ADMINISTRADORES ---------------
  --
  -- La clave publica va dentro del APK. Sin estas politicas, quien la extraiga
  -- podria subir lo que quisiera a un bucket que la tienda muestra a todos sus
  -- clientes — y el problema no seria el espacio en disco, sino lo que apareceria
  -- en las tarjetas de productos.
  execute $sql$
    drop policy if exists p_productos_escritura on storage.objects
  $sql$;
  execute $sql$
    create policy p_productos_escritura on storage.objects
      for all to authenticated
      using (
        bucket_id = 'productos'
        and exists (select 1 from administradores a where a.uid = auth.uid())
      )
      with check (
        bucket_id = 'productos'
        and exists (select 1 from administradores a where a.uid = auth.uid())
      )
  $sql$;
end
$do$;

-- --------------- AYUDA PARA EL ADMINISTRADOR ---------------
--
-- Arma la URL publica de un archivo del bucket, para no tener que recordar la
-- forma exacta ni el id del proyecto al insertar un producto:
--
--   update productos set imagen = fn_url_imagen('laptop_lenovo.jpg')
--    where id_producto = 1;
--
-- Devuelve null si se le pasa null, para que asignarla a un producto sin foto
-- no invente una URL rota.

create or replace function fn_url_imagen(p_archivo text)
returns text
language plpgsql
stable
as $fn$
declare
  v_base text;
begin
  if p_archivo is null or btrim(p_archivo) = '' then
    return null;
  end if;

  -- Una URL completa se devuelve tal cual: permite mezclar fotos del bucket
  -- con otras alojadas fuera.
  if p_archivo like 'http://%' or p_archivo like 'https://%' then
    return p_archivo;
  end if;

  -- El endpoint sale de la configuracion del propio proyecto, no de una
  -- constante: asi la funcion sigue siendo correcta si la base se restaura en
  -- otro proyecto de Supabase.
  begin
    execute 'select current_setting(''app.settings.api_external_url'', true)'
      into v_base;
  exception when others then
    v_base := null;
  end;

  if v_base is null or v_base = '' then
    -- Fuera de Supabase (o sin ese ajuste) se devuelve una ruta relativa, que
    -- es inutil para la app pero honesta: mejor que una URL inventada.
    return '/storage/v1/object/public/productos/' || p_archivo;
  end if;

  return v_base || '/storage/v1/object/public/productos/' || p_archivo;
end;
$fn$;

revoke all on function fn_url_imagen(text) from public;
grant execute on function fn_url_imagen(text) to authenticated, service_role;

-- --------------- LA SEMILLA APUNTABA A ARCHIVOS QUE NO EXISTEN ---------------
--
-- 0003 sembro nombres inventados (laptop_lenovo.jpg, mouse_g203.jpg...) que no
-- estan en assets/products/ ni en ningun sitio: la app pedia cada uno, recibia
-- un 404 y caia al icono de la categoria. Se limpian, y cada producto queda
-- sin foto hasta que el administrador suba la suya al bucket.
--
-- Solo se tocan los nombres que sembro 0003: si alguien ya subio una imagen de
-- verdad, o puso una URL, se respeta.

update productos
   set imagen = null
 where imagen in (
   'laptop_lenovo.jpg', 'laptop_hp.jpg', 'galaxy_a55.jpg',
   'mouse_g203.jpg', 'teclado_k380.jpg', 'sony_ch520.jpg'
 );
