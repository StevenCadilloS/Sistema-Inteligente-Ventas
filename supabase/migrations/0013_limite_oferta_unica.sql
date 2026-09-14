-- ============================================================================
-- 0013 - La oferta es una oportunidad unica al dia
--
-- La regla anterior (0004, regla 7 del README) contaba TODAS las compras del
-- dia para el limite: dos compras, con o sin oferta, y se acababa el cupo.
-- Eso castigaba al que compra a precio normal, que pagaba completo y aun asi
-- perdia su derecho a negociar.
--
-- La regla nueva, decidida con el administrador:
--
--   1. Solo cuentan las compras que USARON oferta. Las de precio normal no
--      consumen nada: quien paga de lista puede conservar su oportunidad.
--   2. El limite baja de 2 a 1. Con la primera compra con oferta se agota el
--      cupo del dia; de ahi en adelante, precio normal hasta manana.
--
-- El cambio de regla vive solo en las dos primeras funciones. Todo lo demas
-- (fn_ofertas_de, fn_registrar_venta, fn_confirmar_carrito) ya delega en
-- ellas, asi que hereda la regla sin tocar su logica: la app ni se entera,
-- porque nunca calcula el limite por su cuenta.
--
-- fn_registrar_venta y fn_confirmar_carrito se re-declaran aqui SOLO para
-- actualizar el texto del rechazo ("tus dos ofertas" ya no es cierto). Los
-- cuerpos son copia literal de 0011: si algun dia se corrige uno, corregir
-- aqui tambien.
-- ============================================================================

-- --------------- 1. CUANTAS OFERTAS USO HOY ---------------
--
-- Antes: count(*) de ventas de hoy. Ahora: ventas de hoy que tengan al menos
-- una linea con oferta. El join con distinct es lo que hace que un carrito
-- con tres productos con oferta (una sola venta desde 0011) cuente como UNA
-- compra con oferta, no tres.

create or replace function fn_compras_del_dia()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select count(distinct v.id_venta)::integer
    from venta v
    join detalle_venta d on d.id_venta = v.id_venta
   where v.id_cliente = fn_cliente_actual()
     and d.id_oferta is not null
     and (v.fecha_hora at time zone fn_zona_negocio())::date
       = (now()       at time zone fn_zona_negocio())::date
$$;

-- --------------- 2. EL LIMITE ES UNO ---------------
--
-- Misma firma, mismo retorno: cambia el 2 por un 1 y nada mas.

create or replace function fn_puede_usar_oferta()
returns boolean
language sql
stable
security definer
set search_path = public
as $$ select fn_cliente_actual() is not null and fn_compras_del_dia() < 1 $$;

-- --------------- 3. EL MENSAJE DEL RECHAZO ---------------
--
-- Copia literal de fn_registrar_venta (0011) con el texto actualizado.

create or replace function fn_registrar_venta(
  p_id_producto bigint,
  p_cantidad    integer default 1,
  p_id_oferta   bigint default null
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
      raise exception 'Ya usaste tu oferta de hoy'
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

  -- La cabecera ya no conoce la oferta: esa se movio a la linea de abajo.
  insert into venta (
    id_cliente, subtotal_centavos, descuento_centavos, total_centavos
  ) values (
    v_id_cliente, v_subtotal, v_descuento, v_subtotal - v_descuento
  )
  returning id_venta into v_venta_id;

  insert into detalle_venta (
    id_venta, id_producto, cantidad, id_oferta, precio_total_centavos
  ) values (
    v_venta_id, p_id_producto, p_cantidad, p_id_oferta, v_unitario * p_cantidad
  );

  update productos
     set stock = stock - p_cantidad
   where id_producto = p_id_producto;

  return v_venta_id;
end;
$fn$;

-- Copia literal de fn_confirmar_carrito (0011) con el texto actualizado.

create or replace function fn_confirmar_carrito(
  p_lineas jsonb
)
returns bigint
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_id_cliente bigint;
  v_linea      jsonb;
  v_pid        bigint;
  v_cant       integer;
  v_ofer       bigint;
  v_acordado   integer;
  v_nombre     varchar;
  v_stock      integer;
  v_lista      integer;
  v_activo     boolean;
  v_unitario   integer;
  v_rebaja     integer;
  v_hay_oferta boolean := false;
  v_venta_id   bigint;
  v_subtotal   integer := 0;
  v_descuento  integer := 0;
  -- Lo validado pasa a estos arreglos para la segunda vuelta: los INSERT de
  -- lineas van despues de la cabecera, y releer el jsonb re-resolveria
  -- precios en un mundo distinto al que acabo de validar.
  v_pids       bigint[]  := '{}';
  v_cants      integer[] := '{}';
  v_ofertas    bigint[]  := '{}';
  v_unitarios  integer[] := '{}';
  v_i          integer;
begin
  v_id_cliente := fn_cliente_actual();
  if v_id_cliente is null then
    raise exception 'Hay que iniciar sesion para comprar'
      using hint = 'sin_sesion';
  end if;

  if p_lineas is null or jsonb_array_length(p_lineas) = 0 then
    raise exception 'El carrito esta vacio'
      using hint = 'carrito_vacio';
  end if;

  -- Decision con el administrador: TODA la confirmacion es UNA compra. El
  -- limite de la oferta unica del dia se decide aqui, para el carrito
  -- completo, antes de tocar ninguna linea.
  if exists (
    select 1 from jsonb_array_elements(p_lineas) l
     where nullif(l ->> 'id_oferta', '') is not null
  ) then
    v_hay_oferta := true;
    if not fn_puede_usar_oferta() then
      raise exception 'Ya usaste tu oferta de hoy'
        using hint = 'limite_diario';
    end if;
  end if;

  -- Validacion linea por linea, contra el catalogo. Cada producto se queda
  -- bloqueado (FOR UPDATE) hasta el fin de la funcion, y su stock baja ya
  -- aqui: si una linea posterior truena, el rollback devuelve todo. Dos
  -- lineas del mismo producto (decision tomada: se puede) se descuentan una
  -- tras otra y la segunda ve el stock que dejo la primera, asi que un
  -- carrito que pide mas de lo que hay muere en una de las dos.
  for v_linea in select * from jsonb_array_elements(p_lineas) loop
    v_pid      := (v_linea ->> 'id_producto')::bigint;
    v_cant     := coalesce((v_linea ->> 'cantidad')::integer, 1);
    v_ofer     := nullif(v_linea ->> 'id_oferta', '')::bigint;
    v_acordado := (v_linea ->> 'precio_acordado_centavos')::integer;

    if v_cant < 1 then
      raise exception 'La cantidad debe ser al menos 1'
        using hint = 'cantidad_invalida';
    end if;

    select p.nombre, p.stock, p.precio_centavos, p.activo
      into v_nombre, v_stock, v_lista, v_activo
      from productos p
     where p.id_producto = v_pid
       for update;

    if not found then
      raise exception 'No existe el producto %', v_pid
        using hint = 'producto_inexistente';
    end if;

    if not v_activo then
      raise exception 'El producto % ya no esta activo', v_nombre
        using hint = 'producto_inactivo';
    end if;

    if v_stock < v_cant then
      raise exception 'Sin stock suficiente de %', v_nombre
        using hint = 'sin_stock';
    end if;

    v_unitario := v_lista;
    v_rebaja   := 0;
    if v_ofer is not null then
      select s.precio_final_centavos into v_unitario
        from v_secuencia_ofertas s
       where s.id_producto = v_pid
         and s.id_oferta   = v_ofer;

      if not found then
        raise exception 'La oferta % no esta vigente para el producto %',
          v_ofer, v_pid
          using hint = 'oferta_no_aplicable';
      end if;

      v_rebaja := (v_lista - v_unitario) * v_cant;

      -- Igual que en fn_registrar_venta: un combo que encarece seria error
      -- de captura en el panel. Mejor fallar que cobrarlo.
      if v_rebaja < 0 then
        raise exception 'La oferta % deja un precio mayor al normal', v_ofer
          using hint = 'oferta_incoherente';
      end if;
    end if;

    -- El cordon de la promesa de precio: si lo acordado no coincide con lo
    -- vigente, la confirmacion entera muere aqui y la base queda sin tocar.
    if v_acordado is not null and v_acordado <> v_unitario then
      raise exception 'El precio de % cambio: acordaste % centavos y hoy vale % centavos',
        v_nombre, v_acordado, v_unitario
        using hint = 'precio_cambio';
    end if;

    update productos
       set stock = stock - v_cant
     where id_producto = v_pid;

    v_pids      := v_pids || v_pid;
    v_cants     := v_cants || v_cant;
    v_ofertas   := v_ofertas || v_ofer;
    v_unitarios := v_unitarios || v_unitario;

    v_subtotal  := v_subtotal + v_lista * v_cant;
    v_descuento := v_descuento + v_rebaja;
  end loop;

  -- chk_venta_cuadra exige que total = subtotal - descuento; con las sumas
  -- de arriba sale cuadrado de fabrica.
  insert into venta (
    id_cliente, subtotal_centavos, descuento_centavos, total_centavos
  ) values (
    v_id_cliente, v_subtotal, v_descuento, v_subtotal - v_descuento
  )
  returning id_venta into v_venta_id;

  for v_i in 1..array_length(v_pids, 1) loop
    insert into detalle_venta (
      id_venta, id_producto, cantidad, id_oferta, precio_total_centavos
    ) values (
      v_venta_id, v_pids[v_i], v_cants[v_i], v_ofertas[v_i],
      v_unitarios[v_i] * v_cants[v_i]
    );
  end loop;

  return v_venta_id;
end;
$fn$;

-- --------------- 4. PERMISOS ---------------
--
-- La receta de 0011: create or replace no garantiza los permisos al
-- redefinir, se re-aplican.

do $do$
declare f text;
begin
  foreach f in array array[
    'fn_compras_del_dia()',
    'fn_puede_usar_oferta()',
    'fn_registrar_venta(bigint,integer,bigint)',
    'fn_confirmar_carrito(jsonb)'
  ]
  loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end
$do$;
