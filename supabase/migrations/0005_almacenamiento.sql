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
-- dos modos conviven -- util para migrar sin prisa.
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

  execute 'drop policy if exists p_productos_lectura on storage.objects';
  execute 'create policy p_productos_lectura on storage.objects'
       || ' for select to anon, authenticated'
       || ' using (bucket_id = ''productos'')';

  -- --------------- ESCRITURA: SOLO ADMINISTRADORES ---------------
  --
  -- La clave publica va dentro del APK. Sin estas politicas, quien la extraiga
  -- podria subir lo que quisiera a un bucket que la tienda muestra a todos sus
  -- clientes -- y el problema no seria el espacio en disco, sino lo que apareceria
  -- en las tarjetas de productos.
  execute 'drop policy if exists p_productos_escritura on storage.objects';
  execute 'create policy p_productos_escritura on storage.objects'
       || ' for all to authenticated'
       || ' using (bucket_id = ''productos'' and exists'
       || '   (select 1 from administradores a where a.uid = auth.uid()))'
       || ' with check (bucket_id = ''productos'' and exists'
       || '   (select 1 from administradores a where a.uid = auth.uid()))';
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

-- Nota de sintaxis, que costo cuatro intentos: el SQL Editor del panel de
-- Supabase no soporta bien varios delimitadores dollar-quote distintos en el
-- mismo script. Este archivo usaba tres tipos distintos, y al llegar al
-- tercero daba "unterminated dollar-quoted string" aunque el cuerpo
-- estuviera perfectamente cerrado.
--
-- La solucion es no usar dollar-quote aqui: el cuerpo va entre comillas
-- simples normales, con las de dentro dobladas. Es la forma clasica de
-- declarar una funcion en PostgreSQL y la entiende cualquier parser.
create or replace function fn_url_imagen(p_archivo text)
returns text
language plpgsql
stable
as
'
declare
  v_base   text;
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

  begin
    v_base := current_setting(''app.settings.api_external_url'', true);
  exception when others then
    v_base := null;
  end;

  if v_base is null or length(v_base) = 0 then
    return concat(v_ruta, v_limpio);
  end if;

  return concat(v_base, v_ruta, v_limpio);
end;
';

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
