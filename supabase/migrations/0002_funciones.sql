-- ============================================================================
-- 0002 - Vistas y funciones del Sistema Inteligente de Ventas
--
-- Todas las escrituras de la app viven aqui, como funciones SECURITY DEFINER.
-- La app tiene permiso de EXECUTE sobre estas funciones y de SELECT sobre el
-- catalogo; nada mas. Una funcion puede exigir que el total cuadre, que haya
-- stock y que el cliente siga dentro de su limite diario. Un INSERT suelto
-- desde el telefono no puede exigir nada.
--
-- `set search_path = public` en cada funcion no es ceremonia: sin eso, quien
-- pueda crear un esquema en el search_path del llamador puede colocar una
-- tabla `productos` propia y hacer que la funcion, que corre como su dueno,
-- lea la suya.
-- ============================================================================

-- --------------- VISTA: OFERTAS VIGENTES ---------------
--
-- Una oferta cuenta si esta activa y hoy cae dentro de su vigencia. Se aisla
-- en una vista porque la condicion aparece en varios sitios y repetirla es
-- como se termina con dos definiciones de "vigente" que no coinciden.

create or replace view v_ofertas_vigentes as
select o.id_oferta,
       o.nombre,
       o.id_tipo,
       t.nombre as tipo,
       o.porcentaje_descuento,
       o.precio_oferta_centavos
  from ofertas o
  join tipos_oferta t on t.id_tipo = o.id_tipo
 where o.activa
   and o.fecha_inicio <= now()
   and (o.fecha_fin is null or o.fecha_fin > now());

-- --------------- VISTA: CATALOGO ---------------
--
-- Lo que ve la tienda. Incluye `tiene_ofertas` para que la app sepa de
-- antemano si vale la pena encender la camara: un producto sin secuencia de
-- ofertas no tiene a donde avanzar, y el README es explicito en que entonces
-- se mantiene el precio normal (regla 8).

create or replace view v_catalogo as
select p.id_producto,
       p.nombre,
       p.descripcion,
       p.precio_centavos,
       p.stock,
       p.imagen,
       p.activo,
       c.id_categoria,
       c.nombre as categoria,
       m.id_marca,
       m.nombre as marca,
       exists (
         select 1
           from ofertas_productos op
           join v_ofertas_vigentes ov on ov.id_oferta = op.id_oferta
          where op.id_producto = p.id_producto
       ) as tiene_ofertas
  from productos p
  join categorias c on c.id_categoria = p.id_categoria
  join marcas     m on m.id_marca     = p.id_marca;

-- --------------- VISTA: SECUENCIA DE OFERTAS ---------------
--
-- La secuencia de un producto, ya ordenada y con el precio de cada escalon
-- calculado. El calculo esta aqui y no en Dart para que el precio que se
-- muestra y el que se cobra salgan de la misma formula.
--
-- Division entera: el redondeo favorece al cliente por un centavo como mucho.

create or replace view v_secuencia_ofertas as
select op.id_producto,
       op.orden,
       op.cantidad,
       ov.id_oferta,
       ov.nombre as nombre_oferta,
       ov.tipo,
       ov.porcentaje_descuento,
       case
         when ov.porcentaje_descuento is not null
           then p.precio_centavos - (p.precio_centavos * ov.porcentaje_descuento) / 100
         else ov.precio_oferta_centavos
       end as precio_final_centavos
  from ofertas_productos op
  join v_ofertas_vigentes ov on ov.id_oferta = op.id_oferta
  join productos p on p.id_producto = op.id_producto
 where p.activo and p.stock > 0;
-- Sin ORDER BY: una vista no garantiza el orden de sus filas cuando otra
-- consulta la envuelve. Quien necesite la secuencia ordenada lo pide
-- explicitamente, como hace fn_ofertas_de.

grant select on v_ofertas_vigentes, v_catalogo, v_secuencia_ofertas
  to anon, authenticated;

-- ============================================================================
-- REGLA DE NEGOCIO: LIMITE DIARIO DE OFERTAS
--
-- "Un cliente puede utilizar ofertas unicamente durante sus dos primeras
-- compras del dia" (README, regla 7). Se cuenta el numero de ventas del
-- cliente hoy, no las que llevaron oferta: la tercera compra del dia no puede
-- usar oferta aunque las dos primeras hayan sido a precio normal.
--
-- "Hoy" es el dia del huso horario del negocio, no UTC. Con UTC, una compra a
-- las 8 de la noche en Lima ya cuenta como del dia siguiente y el cliente
-- estrenaria su limite a mitad de la tarde.
-- ============================================================================

create or replace function fn_zona_negocio()
returns text
language sql
immutable
as $$ select 'America/Lima' $$;

create or replace function fn_compras_del_dia(p_id_cliente bigint)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::integer
    from venta
   where id_cliente = p_id_cliente
     and (fecha_hora at time zone fn_zona_negocio())::date
       = (now()      at time zone fn_zona_negocio())::date
$$;

comment on function fn_compras_del_dia is
  'Compras que el cliente lleva hoy. A la tercera ya no puede usar ofertas.';

create or replace function fn_puede_usar_oferta(p_id_cliente bigint)
returns boolean
language sql
stable
security definer
set search_path = public
as $$ select fn_compras_del_dia(p_id_cliente) < 2 $$;

-- --------------- OFERTAS DISPONIBLES PARA UN CLIENTE ---------------
--
-- Junta las dos condiciones: que el producto tenga secuencia vigente y que el
-- cliente siga dentro de su limite. Devuelve vacio si no puede usar ofertas,
-- que es exactamente lo que la app necesita saber para no encender la camara.

create or replace function fn_ofertas_de(
  p_id_producto bigint,
  p_id_cliente  bigint
)
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
     and fn_puede_usar_oferta(p_id_cliente)
   order by s.orden
$$;

-- --------------- REGISTRAR CLIENTE ---------------

create or replace function fn_registrar_cliente(
  p_nombre   text,
  p_paterno  text default null,
  p_materno  text default null,
  p_telefono text default null,
  p_correo   text default null
)
returns bigint
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_id bigint;
begin
  if p_nombre is null or btrim(p_nombre) = '' then
    raise exception 'El nombre del cliente es obligatorio'
      using hint = 'nombre_vacio';
  end if;

  insert into clientes (nombre, paterno, materno, telefono, correo)
  values (btrim(p_nombre), p_paterno, p_materno, p_telefono, p_correo)
  returning id_cliente into v_id;

  return v_id;
end;
$fn$;

-- --------------- REGISTRAR VENTA ---------------
--
-- Una sola funcion para toda la compra: cabecera, lineas y descuento de stock
-- en la misma transaccion. Si algo falla no queda media venta escrita.
--
-- El precio NO se lo cree a la app. Se recalcula aqui desde el catalogo y la
-- oferta, porque el cliente que manda `total_centavos = 1` tambien podria
-- mandar lo que quisiera si le hicieramos caso.

create or replace function fn_registrar_venta(
  p_id_cliente bigint,
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
  v_producto  productos%rowtype;
  v_venta_id  bigint;
  v_subtotal  integer;
  v_unitario  integer;
  v_descuento integer := 0;
  v_orden     integer;
begin
  if p_cantidad is null or p_cantidad < 1 then
    raise exception 'La cantidad debe ser al menos 1'
      using hint = 'cantidad_invalida';
  end if;

  if not exists (select 1 from clientes where id_cliente = p_id_cliente) then
    raise exception 'No existe el cliente %', p_id_cliente
      using hint = 'cliente_inexistente';
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
    -- Que la oferta exista y este vigente no basta: tiene que estar asociada
    -- a ESTE producto y el cliente tiene que seguir dentro de su limite.
    select s.orden, s.precio_final_centavos
      into v_orden, v_unitario
      from v_secuencia_ofertas s
     where s.id_producto = p_id_producto
       and s.id_oferta   = p_id_oferta;

    if not found then
      raise exception 'La oferta % no esta vigente para el producto %',
        p_id_oferta, p_id_producto
        using hint = 'oferta_no_aplicable';
    end if;

    if not fn_puede_usar_oferta(p_id_cliente) then
      raise exception 'El cliente % ya uso sus dos ofertas de hoy', p_id_cliente
        using hint = 'limite_diario';
    end if;

    v_descuento := v_subtotal - (v_unitario * p_cantidad);

    -- Una oferta que encarece no es una oferta: seria un error de captura en
    -- el panel (un combo mas caro que la suma). Mejor fallar que cobrarlo.
    if v_descuento < 0 then
      raise exception 'La oferta % deja un precio mayor al normal', p_id_oferta
        using hint = 'oferta_incoherente';
    end if;
  end if;

  insert into venta (
    id_oferta, id_cliente, subtotal_centavos, descuento_centavos, total_centavos
  ) values (
    p_id_oferta, p_id_cliente, v_subtotal, v_descuento, v_subtotal - v_descuento
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

-- --------------- HISTORIAL DEL CLIENTE ---------------
--
-- `venta` no es de lectura publica, asi que el historial sale por aqui: la
-- funcion devuelve solo las compras del cliente que se pide.

create or replace function fn_historial(
  p_id_cliente bigint,
  p_limite integer default 50
)
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
   where v.id_cliente = p_id_cliente
   order by v.fecha_hora desc
   limit greatest(p_limite, 1)
$$;

-- --------------- PERMISOS ---------------
--
-- La app ejecuta estas funciones y nada mas. `revoke ... from public` primero
-- porque PostgreSQL concede EXECUTE a public por defecto, y una funcion
-- SECURITY DEFINER abierta a todo el mundo es justo lo que se quiere evitar.

do $do$
declare f text;
begin
  foreach f in array array[
    'fn_compras_del_dia(bigint)',
    'fn_puede_usar_oferta(bigint)',
    'fn_ofertas_de(bigint,bigint)',
    'fn_registrar_cliente(text,text,text,text,text)',
    'fn_registrar_venta(bigint,bigint,integer,bigint)',
    'fn_historial(bigint,integer)'
  ]
  loop
    execute format('revoke all on function %s from public', f);
    execute format('grant execute on function %s to anon, authenticated', f);
  end loop;
end
$do$;

-- --------------- REALTIME ---------------
--
-- El catalogo cambia cuando el administrador toca productos u ofertas. Se
-- publican las tablas fisicas: Postgres no replica vistas, asi que la app usa
-- el evento como senal para releer v_catalogo, no como dato.

do $do$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (select 1 from pg_publication_tables
                    where pubname = 'supabase_realtime' and tablename = 'productos') then
      alter publication supabase_realtime add table productos;
    end if;
    if not exists (select 1 from pg_publication_tables
                    where pubname = 'supabase_realtime' and tablename = 'ofertas') then
      alter publication supabase_realtime add table ofertas;
    end if;
    if not exists (select 1 from pg_publication_tables
                    where pubname = 'supabase_realtime' and tablename = 'ofertas_productos') then
      alter publication supabase_realtime add table ofertas_productos;
    end if;
  end if;
end
$do$;
