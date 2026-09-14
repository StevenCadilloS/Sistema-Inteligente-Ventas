-- ============================================================================
-- 0011 - El carrito: una confirmacion, una venta, muchas lineas
--
-- Hasta aqui "Lo quiero" era la compra misma: cada producto pasaba por
-- fn_registrar_venta, que graba una venta y una linea. El carrito cambia el
-- momento del cobro: el cliente junta productos y se cobra cuando confirma.
--
-- Consecuencias que este archivo resuelve:
--
--   1. La oferta pierde su lugar en la cabecera. venta.id_oferta solo tenia
--      sitio para UNA oferta por compra, y el carrito puede llevar la laptop
--      a -10% y el audifono a -20% en la misma confirmacion. La oferta baja a
--      la linea (detalle_venta.id_oferta): cada producto recuerda con que
--      escalon se vendio.
--
--   2. El limite diario pasa a contar confirmaciones. fn_compras_del_dia
--      cuenta filas de venta; si la confirmacion entera entra en UNA venta,
--      el servidor la ve como una sola compra sin tocar ninguna funcion.
--      Cinco productos con oferta en la primera confirmacion respetan los
--      cinco, porque es su compra #1 del dia.
--
--   3. La promesa de un precio se verifica. La app congela el precio que vio
--      al negociar; el servidor no se lo cree: recalcula y, si lo acordado no
--      coincide con lo vigente al confirmar, rechaza con 'precio_cambio'
--      para que la app avise (decision tomada con el administrador).
-- ============================================================================

-- --------------- 1. LA OFERTA BAJA A LA LINEA ---------------
--
-- Nullable: una linea a precio normal no uso oferta. "add if not exists" para
-- que re-ejecutar la migracion sobre una base que ya la tiene no recree la
-- columna con otra definicion.

alter table detalle_venta
  add column if not exists id_oferta bigint references ofertas(id_oferta);

-- Traslado: la oferta de cada venta existente pasa a su linea. Hoy toda venta
-- tiene exactamente una linea (fn_registrar_venta nunca inserto mas), asi que
-- el traslado no tiene ambiguedad. Las ventas sin oferta no se tocan: sus
-- lineas quedan con id_oferta null, igual que antes.
update detalle_venta dv
   set id_oferta = v.id_oferta
  from venta v
 where v.id_venta = dv.id_venta
   and v.id_oferta is not null
   and dv.id_oferta is distinct from v.id_oferta;

-- La cabecera la suelta solo despues de copiarla. La comprobacion existe para
-- que el paso sea inofensivo si esta migracion se volviera a correr.
do $do$
begin
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public'
       and table_name   = 'venta'
       and column_name  = 'id_oferta'
  ) then
    alter table venta drop column id_oferta;
  end if;
end
$do$;

-- --------------- 2. FN_REGISTRAR_VENTA SE ADAPTA AL NUEVO LUGAR ---------------
--
-- Misma firma (id_producto, cantidad, id_oferta) y mismas reglas: solo cambia
-- que la oferta se escribe en la linea y no en la cabecera, para que lo que
-- ya esta publicado en el APK siga comprando igual mientras el carrito llega
-- a la app.

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

-- --------------- 3. COTIZAR EL CARRITO (SIN ESCRIBIR NADA) ---------------
--
-- La app llama aqui ANTES de confirmar: "en cuanto sale mi carrito hoy?".
-- Responde linea por linea con el precio real de este momento, recalculado
-- desde el catalogo y la oferta, y las banderas que el aviso necesita:
--
--   oferta_aplicada  false -> la oferta que se nego ya no corre: vencio, la
--                             desactivaron o el cliente gasto sus dos compras
--                             del dia. La linea se cotiza a precio normal.
--   stock_suficiente false -> alguien se llevo unidades mientras decidia.
--
-- Solo lee. El cobro es de fn_confirmar_carrito.
--
-- Formato de p_lineas:
--   '[{"id_producto":1, "cantidad":2, "id_oferta":5},
--     {"id_producto":3, "cantidad":1}]'
-- id_oferta es opcional por linea: null significa precio normal.

create or replace function fn_cotizar_carrito(
  p_lineas jsonb
)
returns table (
  id_producto              bigint,
  cantidad                 integer,
  id_oferta                bigint,
  precio_unitario_centavos integer,
  oferta_aplicada          boolean,
  stock_suficiente         boolean
)
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  v_linea  jsonb;
  v_pid    bigint;
  v_cant   integer;
  v_ofer   bigint;
  v_precio_oferta integer;
begin
  if fn_cliente_actual() is null then
    raise exception 'Hay que iniciar sesion para cotizar'
      using hint = 'sin_sesion';
  end if;

  if p_lineas is null or jsonb_array_length(p_lineas) = 0 then
    raise exception 'El carrito esta vacio'
      using hint = 'carrito_vacio';
  end if;

  for v_linea in select * from jsonb_array_elements(p_lineas) loop
    v_pid  := (v_linea ->> 'id_producto')::bigint;
    v_cant := coalesce((v_linea ->> 'cantidad')::integer, 1);
    v_ofer := nullif(v_linea ->> 'id_oferta', '')::bigint;

    -- Un carrito con cantidad 0 o negativa es un error de la app, no un caso
    -- de negocio: se corta antes de que la cotizacion diga disparates.
    if v_cant < 1 then
      raise exception 'La cantidad debe ser al menos 1'
        using hint = 'cantidad_invalida';
    end if;

    -- El precio parte del de lista...
    select p.precio_centavos, (p.stock >= v_cant)
      into precio_unitario_centavos, stock_suficiente
      from productos p
     where p.id_producto = v_pid;

    if not found then
      raise exception 'No existe el producto %', v_pid
        using hint = 'producto_inexistente';
    end if;

    -- ...y baja si la oferta que se nego sigue jugando para quien llama.
    -- El precio se lee a una variable aparte: el SELECT INTO con "no rows"
    -- pone NULL en su destino, y si fuera directo machacaria el precio de
    -- lista que acabamos de asignar.
    oferta_aplicada := false;
    id_oferta       := v_ofer;
    if v_ofer is not null and fn_puede_usar_oferta() then
      select s.precio_final_centavos into v_precio_oferta
        from v_secuencia_ofertas s
       where s.id_producto = v_pid
         and s.id_oferta   = v_ofer;
      if found then
        precio_unitario_centavos := v_precio_oferta;
        oferta_aplicada          := true;
      end if;
      -- Si no la encontro en la secuencia vigente, el precio de lista y la
      -- bandera en false SON la respuesta: es un aviso, no un error.
    end if;

    return next;
  end loop;
end;
$fn$;

-- --------------- 4. CONFIRMAR EL CARRITO ---------------
--
-- La caja registradora del carrito. Recibe TODAS las lineas y entra en una
-- sola venta: cabecera, lineas y descuento de stock en la misma transaccion.
-- Si una linea falla, no queda nada escrito (el rollback de la excepcion
-- deshace tambien los stocks ya restados).
--
-- El limite diario se mira UNA vez, antes de la primera linea: da igual que
-- el carrito traiga tres productos con oferta, es una sola compra; y si el
-- cliente ya gasto sus dos ofertas del dia, el rechazo es del carrito entero.
--
-- El precio acordado no se le cree a nadie: cada linea puede traer
-- "precio_acordado_centavos" con lo que el cliente vio en pantalla. Si difiere
-- de lo que determina el servidor HOY, se rechaza con 'precio_cambio' y la
-- app vuelve a cotizar para mostrar el aviso. Nunca se cobra lo que la app
-- sugiera: el valor que viaja por el jsonb solo sirve para RECHAZAR cuando
-- pantalla y base no coinciden, nunca para fijar el cobro.
--
-- Formato de p_lineas:
--   '[{"id_producto":1, "cantidad":2, "id_oferta":5,
--      "precio_acordado_centavos":450000},
--     {"id_producto":3, "cantidad":1}]'
-- precio_acordado_centavos es opcional: su ausencia significa "sin
-- verificacion" (para las pruebas y herramientas, que no necesitan el eco de
-- la pantalla).

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
  -- limite de las dos ofertas del dia se decide aqui, para el carrito
  -- completo, antes de tocar ninguna linea.
  if exists (
    select 1 from jsonb_array_elements(p_lineas) l
     where nullif(l ->> 'id_oferta', '') is not null
  ) then
    v_hay_oferta := true;
    if not fn_puede_usar_oferta() then
      raise exception 'Ya usaste tus dos ofertas de hoy'
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

-- --------------- 5. EL HISTORIAL LEE LA OFERTA EN LA LINEA ---------------
--
-- Misma consulta de siempre; el cambio es solo el join: la oferta vive en
-- detalle_venta desde ahora.

create or replace function fn_historial(
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
    left join ofertas o  on o.id_oferta = d.id_oferta
   where v.id_cliente = fn_cliente_actual()
   order by v.fecha_hora desc
   limit greatest(p_limite, 1)
$$;

-- --------------- 6. PERMISOS ---------------
--
-- La receta de 0004: las funciones de compra son para clientes con sesion;
-- anon no ejecuta nada. Se reincorpora fn_registrar_venta por si la base
-- viniera de antes de 0004, con la misma gramatica de permisos.

do $do$
declare f text;
begin
  foreach f in array array[
    'fn_registrar_venta(bigint,integer,bigint)',
    'fn_cotizar_carrito(jsonb)',
    'fn_confirmar_carrito(jsonb)',
    'fn_historial(integer)'
  ]
  loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end
$do$;
