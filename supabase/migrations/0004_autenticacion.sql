-- ============================================================================
-- 0004 - Identidad del cliente
--
-- Hasta aqui un "cliente" era una fila que la app creaba al escribir un nombre,
-- y su id vivia en SharedPreferences del telefono. Eso tenia dos agujeros:
--
--   1. El historial se perdia al reinstalar la app o cambiar de celular, y no
--      habia forma de recuperarlo: nada ataba esa fila a una persona.
--
--   2. El limite de dos ofertas por dia era trivial de saltar. Se cuenta por
--      id_cliente, asi que bastaba con registrarse otra vez para volver a
--      cero. Borrar los datos de la app daba ofertas ilimitadas.
--
-- Con `uid` apuntando a auth.users, el cliente es quien dice ser, su historial
-- lo sigue a cualquier dispositivo y el limite diario pasa a significar algo.
--
-- La consecuencia mas importante esta al final del archivo: fn_registrar_venta
-- deja de recibir el id del cliente. Lo deduce del token. Mientras lo recibiera
-- como parametro, cualquiera con la clave publica podia registrar compras a
-- nombre de otra persona.
-- ============================================================================

-- --------------- ENLACE CON auth.users ---------------

alter table clientes add column if not exists uid uuid unique;

do $do$
begin
  if exists (select 1 from information_schema.schemata where schema_name = 'auth')
     and not exists (
       select 1 from information_schema.table_constraints
        where constraint_name = 'fk_clientes_uid'
     )
  then
    alter table clientes
      add constraint fk_clientes_uid
      foreign key (uid) references auth.users(id) on delete cascade;
  end if;
end
$do$;

-- Dos cuentas no pueden compartir correo. Sin esto, "mi historial" deja de
-- tener sentido: dos personas distintas responderian al mismo correo.
create unique index if not exists ux_clientes_correo
  on clientes (lower(correo)) where correo is not null;

-- --------------- QUIEN ESTA LLAMANDO ---------------
--
-- Una sola definicion de "el cliente en curso", que es lo que usan todas las
-- funciones de abajo. Devuelve null si quien llama no esta autenticado o no
-- tiene ficha de cliente.
--
-- `auth.uid()` no existe fuera de Supabase; en un Postgres pelado la funcion
-- cae a la sesion simulada que fija fn_simular_sesion, definida mas abajo.

-- `auth.uid()` va por EXECUTE y no como llamada directa a proposito: PL/pgSQL
-- resuelve los nombres al compilar la funcion, asi que una llamada directa
-- falla con `schema "auth" does not exist` en el momento de crearla, fuera de
-- Supabase -- y un bloque EXCEPTION alrededor no ayuda, porque el error no
-- ocurre en ejecucion. Con EXECUTE, el nombre se resuelve al llamarla y el
-- catch si puede atraparlo.
create or replace function fn_cliente_actual()
returns bigint
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  v_uid uuid;
  v_id  bigint;
begin
  begin
    execute 'select auth.uid()' into v_uid;
  exception when others then
    -- Sin esquema auth (Postgres local, CI): no hay sesion real. Se acepta la
    -- sesion simulada de las pruebas, que solo existe donde no hay `auth`:
    -- en Supabase esta rama no se alcanza nunca.
    return nullif(
      current_setting('tienda.cliente_simulado', true), ''
    )::bigint;
  end;

  if v_uid is null then return null; end if;

  select id_cliente into v_id from clientes where uid = v_uid;
  return v_id;
end;
$fn$;

-- Para las pruebas fuera de Supabase: fija a mano quien es "el cliente en
-- curso". En Supabase no se usa nunca -- alli manda el token -- y por eso no se
-- concede a anon ni a authenticated.
create or replace function fn_simular_sesion(p_id_cliente bigint)
returns void
language plpgsql
as $fn$
begin
  perform set_config('tienda.cliente_simulado', coalesce(p_id_cliente::text, ''), true);
end;
$fn$;

comment on function fn_cliente_actual is
  'Id del cliente autenticado, o null. Unica fuente de "quien llama".';

-- --------------- ALTA DEL CLIENTE ---------------
--
-- Se llama una vez, despues de que Supabase Auth creo la cuenta: crea la ficha
-- de negocio y la ata al uid del token. La firma anterior (nombre libre, sin
-- identidad) queda reemplazada -- ya no se puede crear un cliente anonimo.

drop function if exists fn_registrar_cliente(text, text, text, text, text);

create or replace function fn_registrar_cliente(
  p_nombre   text,
  p_paterno  text default null,
  p_materno  text default null,
  p_telefono text default null
)
returns bigint
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_uid    uuid;
  v_correo text;
  v_id     bigint;
begin
  -- Por EXECUTE, igual que en fn_cliente_actual: sin esquema auth la llamada
  -- directa ni siquiera dejaria crear esta funcion.
  begin
    execute 'select auth.uid()' into v_uid;
  exception when others then
    v_uid := null;
  end;

  if v_uid is null then
    raise exception 'Hay que iniciar sesion antes de registrarse'
      using hint = 'sin_sesion';
  end if;

  if p_nombre is null or btrim(p_nombre) = '' then
    raise exception 'El nombre del cliente es obligatorio'
      using hint = 'nombre_vacio';
  end if;

  -- Si ya tiene ficha, se devuelve la suya: volver a entrar no crea un
  -- cliente nuevo, que es justo el agujero que este archivo cierra.
  select id_cliente into v_id from clientes where uid = v_uid;
  if v_id is not null then
    return v_id;
  end if;

  -- El correo sale del token, no del formulario: es el que Supabase ya
  -- verifico. Dejar que la app lo mandara permitiria registrarse con el
  -- correo de otra persona.
  execute 'select email from auth.users where id = $1'
    into v_correo using v_uid;

  insert into clientes (nombre, paterno, materno, telefono, correo, uid)
  values (btrim(p_nombre), p_paterno, p_materno, p_telefono, v_correo, v_uid)
  returning id_cliente into v_id;

  return v_id;
end;
$fn$;

-- --------------- LAS FUNCIONES DEJAN DE RECIBIR EL ID ---------------
--
-- Este es el cambio que de verdad importa. Mientras `p_id_cliente` fuera un
-- parametro, cualquiera con la clave publica (que va dentro del APK) podia
-- pasar el id de otra persona: leer su historial, gastarle sus ofertas del
-- dia o registrarle compras. Ahora el cliente sale del token y no hay nada
-- que falsificar.

drop function if exists fn_compras_del_dia(bigint);
drop function if exists fn_puede_usar_oferta(bigint);
drop function if exists fn_ofertas_de(bigint, bigint);
drop function if exists fn_historial(bigint, integer);
drop function if exists fn_registrar_venta(bigint, bigint, integer, bigint);

create or replace function fn_compras_del_dia()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::integer
    from venta
   where id_cliente = fn_cliente_actual()
     and (fecha_hora at time zone fn_zona_negocio())::date
       = (now()      at time zone fn_zona_negocio())::date
$$;

create or replace function fn_puede_usar_oferta()
returns boolean
language sql
stable
security definer
set search_path = public
as $$ select fn_cliente_actual() is not null and fn_compras_del_dia() < 2 $$;

create or replace function fn_ofertas_de(p_id_producto bigint)
returns table (
  orden                 integer,
  id_oferta             bigint,
  nombre_oferta         varchar,
  tipo                  varchar,
  porcentaje_descuento  integer,
  precio_final_centavos integer
)
language sql
stable
security definer
set search_path = public
as $$
  select s.orden, s.id_oferta, s.nombre_oferta, s.tipo,
         s.porcentaje_descuento, s.precio_final_centavos
    from v_secuencia_ofertas s
   where s.id_producto = p_id_producto
     and fn_puede_usar_oferta()
   order by s.orden
$$;

create or replace function fn_historial(p_limite integer default 50)
returns table (
  id_venta       bigint,
  fecha_hora     timestamptz,
  producto       varchar,
  cantidad       integer,
  nombre_oferta  varchar,
  total_centavos integer
)
language sql
stable
security definer
set search_path = public
as $$
  select v.id_venta, v.fecha_hora, p.nombre, d.cantidad, o.nombre,
         v.total_centavos
    from venta v
    join detalle_venta d on d.id_venta = v.id_venta
    join productos p     on p.id_producto = d.id_producto
    left join ofertas o  on o.id_oferta = v.id_oferta
   where v.id_cliente = fn_cliente_actual()
   order by v.fecha_hora desc
   limit greatest(p_limite, 1)
$$;

create or replace function fn_registrar_venta(
  p_id_producto bigint,
  p_cantidad integer default 1,
  p_id_oferta bigint default null
)
returns bigint
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_id_cliente bigint;
  v_producto   productos%rowtype;
  v_venta_id   bigint;
  v_subtotal   integer;
  v_unitario   integer;
  v_descuento  integer := 0;
begin
  v_id_cliente := fn_cliente_actual();
  if v_id_cliente is null then
    raise exception 'Hay que iniciar sesion para comprar'
      using hint = 'sin_sesion';
  end if;

  if p_cantidad is null or p_cantidad < 1 then
    raise exception 'La cantidad debe ser al menos 1'
      using hint = 'cantidad_invalida';
  end if;

  -- FOR UPDATE bloquea la fila hasta el final de la funcion: es lo que impide
  -- que dos compras simultaneas lean el mismo stock y ambas se lo lleven.
  select * into v_producto
    from productos
   where id_producto = p_id_producto
     for update;

  if not found then
    raise exception 'No existe el producto %', p_id_producto
      using hint = 'producto_inexistente';
  end if;

  if not v_producto.activo then
    raise exception 'El producto % no esta activo', v_producto.nombre
      using hint = 'producto_inactivo';
  end if;

  if v_producto.stock < p_cantidad then
    raise exception 'Sin stock suficiente de %', v_producto.nombre
      using hint = 'sin_stock';
  end if;

  v_subtotal := v_producto.precio_centavos * p_cantidad;
  v_unitario := v_producto.precio_centavos;

  if p_id_oferta is not null then
    select s.precio_final_centavos into v_unitario
      from v_secuencia_ofertas s
     where s.id_producto = p_id_producto
       and s.id_oferta   = p_id_oferta;

    if not found then
      raise exception 'La oferta % no esta vigente para el producto %',
        p_id_oferta, p_id_producto
        using hint = 'oferta_no_aplicable';
    end if;

    if not fn_puede_usar_oferta() then
      raise exception 'Ya usaste tus dos ofertas de hoy'
        using hint = 'limite_diario';
    end if;

    v_descuento := v_subtotal - (v_unitario * p_cantidad);

    -- Una oferta que encarece no es una oferta: seria un error de captura en
    -- el panel. Mejor fallar que cobrarlo.
    if v_descuento < 0 then
      raise exception 'La oferta % deja un precio mayor al normal', p_id_oferta
        using hint = 'oferta_incoherente';
    end if;
  end if;

  insert into venta (
    id_oferta, id_cliente, subtotal_centavos, descuento_centavos, total_centavos
  ) values (
    p_id_oferta, v_id_cliente, v_subtotal, v_descuento, v_subtotal - v_descuento
  )
  returning id_venta into v_venta_id;

  insert into detalle_venta (id_venta, id_producto, cantidad, precio_total_centavos)
  values (v_venta_id, p_id_producto, p_cantidad, v_unitario * p_cantidad);

  update productos
     set stock = stock - p_cantidad
   where id_producto = p_id_producto;

  return v_venta_id;
end;
$fn$;

-- --------------- RLS SOBRE LOS DATOS DEL CLIENTE ---------------
--
-- Cada quien ve su ficha y sus compras, y nada mas. Las funciones de arriba ya
-- filtran por fn_cliente_actual(), pero las politicas son la red de seguridad:
-- si manana alguien expone una vista sin filtrar, esto sigue en pie.

drop policy if exists p_cliente_ve_lo_suyo on clientes;
create policy p_cliente_ve_lo_suyo on clientes
  for select to authenticated
  using (id_cliente = fn_cliente_actual());

drop policy if exists p_cliente_edita_lo_suyo on clientes;
create policy p_cliente_edita_lo_suyo on clientes
  for update to authenticated
  using (id_cliente = fn_cliente_actual())
  with check (id_cliente = fn_cliente_actual());

drop policy if exists p_venta_propia on venta;
create policy p_venta_propia on venta
  for select to authenticated
  using (id_cliente = fn_cliente_actual());

drop policy if exists p_detalle_propio on detalle_venta;
create policy p_detalle_propio on detalle_venta
  for select to authenticated
  using (
    exists (
      select 1 from venta v
       where v.id_venta = detalle_venta.id_venta
         and v.id_cliente = fn_cliente_actual()
    )
  );

grant select on clientes, venta, detalle_venta to authenticated;
grant update (nombre, paterno, materno, telefono) on clientes to authenticated;

-- --------------- PERMISOS DE EJECUCION ---------------
--
-- `anon` conserva solo lo que se puede hacer sin sesion: leer el catalogo (por
-- las politicas de 0001) y nada mas. Comprar, ver ofertas o consultar el
-- historial exige estar autenticado.

do $do$
declare f text;
begin
  foreach f in array array[
    'fn_cliente_actual()',
    'fn_compras_del_dia()',
    'fn_puede_usar_oferta()',
    'fn_ofertas_de(bigint)',
    'fn_registrar_cliente(text,text,text,text)',
    'fn_registrar_venta(bigint,integer,bigint)',
    'fn_historial(integer)'
  ]
  loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end
$do$;

-- La sesion simulada no se concede a nadie: es para las pruebas, que corren
-- como dueno de la base. Si algun dia se pudiera llamar desde la app, cualquiera
-- se haria pasar por cualquier cliente.
revoke all on function fn_simular_sesion(bigint) from public, anon, authenticated;
