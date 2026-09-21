-- ============================================================================
-- Ciclo de venta: registro de cliente, compra a precio normal, compra con
-- oferta, stock y errores esperados.
--
-- Todo dentro de una transaccion que termina en ROLLBACK: la prueba no deja
-- datos. Las secuencias si avanzan, pero ninguna prueba afirma sobre un id
-- concreto justamente por eso.
-- ============================================================================

begin;

-- --------------- IDENTIDAD ---------------
--
-- Fuera de Supabase no hay auth.users, asi que las fichas de cliente se crean
-- directamente y la sesion se simula con fn_simular_sesion. Que
-- fn_registrar_cliente exija sesion se comprueba en 04_seguridad.sql.

do $$
declare
  v_cliente bigint;
begin
  insert into clientes (nombre, paterno) values ('Prueba', 'Apellido')
    returning id_cliente into v_cliente;
  perform fn_simular_sesion(v_cliente);

  perform test_igual(
    fn_cliente_actual()::text, v_cliente::text,
    'fn_cliente_actual devuelve el cliente de la sesion'
  );
end
$$;

-- Sin sesion, nadie es nadie.
do $$
begin
  perform fn_simular_sesion(null);
  perform test_cierto(fn_cliente_actual() is null, 'sin sesion no hay cliente');
  perform test_cierto(not fn_puede_usar_oferta(), 'sin sesion no hay ofertas');
end
$$;

-- --------------- COMPRA A PRECIO NORMAL ---------------

do $$
declare
  v_cliente  bigint;
  v_producto bigint;
  v_venta    bigint;
  v_stock_antes integer;
begin
  insert into clientes (nombre, paterno) values ('Sin', 'Oferta')
    returning id_cliente into v_cliente;
  perform fn_simular_sesion(v_cliente);

  select id_producto, stock into v_producto, v_stock_antes
    from productos where nombre = 'Laptop HP Pavilion';

  v_venta := fn_registrar_venta(v_producto, 1, null);

  perform test_igual(
    (select total_centavos::text from venta where id_venta = v_venta),
    '280000',
    'la compra sin oferta cobra el precio de lista'
  );
  perform test_igual(
    (select descuento_centavos::text from venta where id_venta = v_venta),
    '0',
    'sin oferta no hay descuento'
  );
  perform test_igual(
    (select stock::text from productos where id_producto = v_producto),
    (v_stock_antes - 1)::text,
    'la venta descuenta una unidad del stock'
  );
end
$$;

-- --------------- COMPRA CON OFERTA ---------------
--
-- Laptop Lenovo cuesta 250000 y su primer escalon es 10%: 225000.

do $$
declare
  v_cliente  bigint;
  v_producto bigint;
  v_oferta   bigint;
  v_venta    bigint;
begin
  insert into clientes (nombre, paterno) values ('Con', 'Oferta')
    returning id_cliente into v_cliente;
  perform fn_simular_sesion(v_cliente);

  select id_producto into v_producto from productos where nombre = 'Laptop Lenovo IdeaPad';
  select id_oferta into v_oferta from ofertas where nombre = 'Descuento 10%';

  v_venta := fn_registrar_venta(v_producto, 1, v_oferta);

  perform test_igual(
    (select total_centavos::text from venta where id_venta = v_venta),
    '225000',
    '250000 con 10% de descuento son 225000'
  );
  perform test_igual(
    (select descuento_centavos::text from venta where id_venta = v_venta),
    '25000',
    'el descuento registrado es la diferencia real'
  );
  -- El detalle congela lo que se cobro, no el precio de lista de hoy.
  perform test_igual(
    (select precio_total_centavos::text from detalle_venta where id_venta = v_venta),
    '225000',
    'el detalle guarda el precio con descuento ya aplicado'
  );
  -- 0011: la oferta vive en la linea, ya no en la cabecera.
  perform test_igual(
    (select id_oferta::text from detalle_venta where id_venta = v_venta),
    v_oferta::text,
    'la linea guarda con que oferta se vendio'
  );
  perform test_igual(
    (select count(*)::text from information_schema.columns
      where table_name = 'venta' and column_name = 'id_oferta'),
    '0',
    'la cabecera de la venta ya no lleva la oferta'
  );
end
$$;

-- --------------- EL TOTAL SIEMPRE CUADRA ---------------
--
-- La restriccion chk_venta_cuadra existe para que un error de calculo no pase
-- inadvertido. Se comprueba que este activa.

select test_falla(
  $q$ insert into venta (id_cliente, subtotal_centavos, descuento_centavos, total_centavos)
      values ((select min(id_cliente) from clientes), 10000, 1000, 5000) $q$,
  null,
  'no se puede grabar una venta cuyo total no cuadra'
);

-- --------------- ERRORES ESPERADOS ---------------

-- Sin sesion no se puede comprar, aunque el producto exista.
do $$
begin
  perform fn_simular_sesion(null);
  perform test_falla(
    format('select fn_registrar_venta(%s, 1, null)',
           (select min(id_producto) from productos)),
    'sin_sesion',
    'sin sesion no se puede comprar'
  );
  -- Se restablece una sesion para el resto del archivo.
  perform fn_simular_sesion((select min(id_cliente) from clientes));
end
$$;

select test_falla(
  $q$ select fn_registrar_venta(999999, 1, null) $q$,
  'producto_inexistente',
  'no se puede vender un producto que no existe'
);

select test_falla(
  $q$ select fn_registrar_venta((select min(id_producto) from productos), 0, null) $q$,
  'cantidad_invalida',
  'la cantidad tiene que ser al menos 1'
);

-- Una oferta que existe pero no esta asociada a ese producto.
do $$
declare
  v_cliente bigint;
  v_hp      bigint;
  v_oferta  bigint;
begin
  insert into clientes (nombre, paterno) values ('Oferta', 'Ajena')
    returning id_cliente into v_cliente;
  perform fn_simular_sesion(v_cliente);

  select id_producto into v_hp from productos where nombre = 'Laptop HP Pavilion';
  select id_oferta into v_oferta from ofertas where nombre = 'Descuento 10%';

  perform test_falla(
    format('select fn_registrar_venta(%s, 1, %s)', v_hp, v_oferta),
    'oferta_no_aplicable',
    'no se puede aplicar una oferta que no es de ese producto'
  );
end
$$;

-- --------------- SIN STOCK ---------------

do $$
declare
  v_cliente  bigint;
  v_producto bigint;
  v_stock_antes integer;
begin
  insert into clientes (nombre, paterno) values ('Sin', 'Stock')
    returning id_cliente into v_cliente;
  perform fn_simular_sesion(v_cliente);

  select id_producto, stock into v_producto, v_stock_antes
    from productos where nombre = 'Samsung Galaxy A55';
  update productos set stock = 0 where id_producto = v_producto;

  perform test_falla(
    format('select fn_registrar_venta(%s, 1, null)', v_producto),
    'sin_stock',
    'no se puede vender un producto agotado'
  );

  -- Se restaura: los bloques de abajo vuelven a comprar este producto, y una
  -- prueba que ensucia el estado de las demas falla de formas que no tienen
  -- que ver con lo que mide (la misma ley de 02_catalogo_y_ofertas).
  update productos set stock = v_stock_antes where id_producto = v_producto;
end
$$;

-- --------------- PRODUCTO INACTIVO ---------------

do $$
declare
  v_cliente  bigint;
  v_producto bigint;
begin
  insert into clientes (nombre, paterno) values ('Producto', 'Inactivo')
    returning id_cliente into v_cliente;
  perform fn_simular_sesion(v_cliente);

  select id_producto into v_producto from productos where nombre = 'Mouse Logitech G203';
  update productos set activo = false where id_producto = v_producto;

  perform test_falla(
    format('select fn_registrar_venta(%s, 1, null)', v_producto),
    'producto_inactivo',
    'no se puede vender un producto dado de baja'
  );

  -- Se reactiva: el Mouse lo usa el bloque del carrito mas abajo.
  update productos set activo = true where id_producto = v_producto;
end
$$;

-- --------------- EL CARRITO: COTIZAR ---------------
--
-- fn_cotizar_carrito solo mira. Con ofertas vigentes cotiza a precio de
-- oferta; con una oferta muerta, a precio de lista y con la bandera baja.

do $$
declare
  v_cliente  bigint;
  v_lenovo   bigint;
  v_hp       bigint;
  v_oferta   bigint;
  v_otra     bigint;
  v_cotizado record;
begin
  insert into clientes (nombre, paterno) values ('Cotiza', 'Carrito')
    returning id_cliente into v_cliente;
  perform fn_simular_sesion(v_cliente);

  select id_producto into v_lenovo from productos where nombre = 'Laptop Lenovo IdeaPad';
  select id_producto into v_hp     from productos where nombre = 'Laptop HP Pavilion';
  select id_oferta   into v_oferta from ofertas   where nombre = 'Descuento 10%';
  select id_oferta   into v_otra   from ofertas   where nombre = 'Descuento 30%';

  -- Dos lineas: una con oferta 10% vigente, otra sin oferta.
  select * into v_cotizado
    from fn_cotizar_carrito(
      format('[{"id_producto":%s, "cantidad":1, "id_oferta":%s},
               {"id_producto":%s, "cantidad":2}]', v_lenovo, v_oferta, v_hp)::jsonb);

  perform test_igual(v_cotizado.precio_unitario_centavos::text, '225000',
    'cotiza la Lenovo con su 10% vigente: 225000');
  perform test_cierto(v_cotizado.oferta_aplicada,
    'la cotizacion avisa que aplico la oferta');
  perform test_cierto(v_cotizado.stock_suficiente,
    'la cotizacion avisa que hay stock');

  -- Hasta 0015 estas dos columnas volvian en NULL: la funcion las declaraba
  -- y no las asignaba. La app las usa para saber a que linea corresponde la
  -- fila, y sin ellas avisaba de un cambio de precio en cada compra.
  perform test_igual(v_cotizado.id_producto::text, v_lenovo::text,
    'la cotizacion dice de que producto habla');
  perform test_igual(v_cotizado.cantidad::text, '1',
    'la cotizacion devuelve la cantidad que se le pidio');

  -- La segunda linea de la misma cotizacion: HP sin oferta.
  select * into v_cotizado
    from fn_cotizar_carrito(format('[{"id_producto":%s, "cantidad":2}]', v_hp)::jsonb)
    limit 1;
  perform test_igual(v_cotizado.precio_unitario_centavos::text, '280000',
    'cotiza la HP a precio de lista');
  perform test_cierto(not v_cotizado.oferta_aplicada,
    'sin oferta pedida, no se marca oferta aplicada');

  -- Una oferta que no cuelga de la Lenovo (el Combo Gamer no esta asociado a
  -- ningun producto desde 0006c): se cotiza a precio de lista y con bandera
  -- en falso. Es un aviso, no un error de la cotizacion.
  select id_oferta   into v_otra   from ofertas   where nombre = 'Combo Gamer';
  select * into v_cotizado
    from fn_cotizar_carrito(
      format('[{"id_producto":%s, "cantidad":1, "id_oferta":%s}]', v_lenovo, v_otra)::jsonb)
    limit 1;
  perform test_igual(v_cotizado.precio_unitario_centavos::text, '250000',
    'una oferta fuera de la escalera se cotiza a precio de lista');
  perform test_cierto(not v_cotizado.oferta_aplicada,
    'y la bandera deja claro que no se aplico');

  perform test_falla(
    $q$ select fn_cotizar_carrito('[]') $q$,
    'carrito_vacio',
    'cotizar un carrito vacio no tiene sentido'
  );
  perform test_falla(
    $q$ select fn_cotizar_carrito('[{"id_producto":999999}]') $q$,
    'producto_inexistente',
    'no se cotiza un producto que no existe'
  );
end
$$;

-- --------------- EL CARRITO: UNA CONFIRMACION ES UNA COMPRA ---------------
--
-- Decision con el administrador: confirmar con N productos es UNA compra.
-- El limite diario se mira una sola vez, asi que todas las lineas de la
-- primera confirmacion del dia pueden llevar su oferta.

do $$
declare
  v_cliente  bigint;
  v_lenovo   bigint;
  v_samsung  bigint;
  v_mouse    bigint;
  v_o10      bigint;
  v_o20      bigint;
  v_venta    bigint;
  v_stock_antes integer;
begin
  insert into clientes (nombre, paterno) values ('Confirma', 'Carrito')
    returning id_cliente into v_cliente;
  perform fn_simular_sesion(v_cliente);

  select id_producto into v_lenovo  from productos where nombre = 'Laptop Lenovo IdeaPad';
  select id_producto into v_samsung from productos where nombre = 'Samsung Galaxy A55';
  select id_producto into v_mouse   from productos where nombre = 'Mouse Logitech G203';
  select id_oferta   into v_o10     from ofertas   where nombre = 'Descuento 10%';
  select id_oferta   into v_o20     from ofertas   where nombre = 'Descuento 20%';

  select stock into v_stock_antes from productos where id_producto = v_samsung;

  -- Tres lineas con ofertas distintas en la MISMA confirmacion: Lenovo 10%,
  -- Samsung 20%, Mouse sin oferta. Precios: 250000*0.9=225000,
  -- 150000*0.8=120000, mouse 12000 a lista. Subtotal de lista
  -- 250000+150000+24000=424000; descuento 25000+30000=55000.
  v_venta := fn_confirmar_carrito(
    format('[{"id_producto":%s, "cantidad":1, "id_oferta":%s, "precio_acordado_centavos":225000},
             {"id_producto":%s, "cantidad":1, "id_oferta":%s, "precio_acordado_centavos":120000},
             {"id_producto":%s, "cantidad":2, "precio_acordado_centavos":12000}]',
           v_lenovo, v_o10, v_samsung, v_o20, v_mouse)::jsonb);

  perform test_igual(
    (select total_centavos::text from venta where id_venta = v_venta),
    '369000',
    'cobrar 225000 + 120000 + 24000 por la confirmacion del carrito'
  );
  perform test_igual(
    (select descuento_centavos::text from venta where id_venta = v_venta),
    '55000',
    'el descuento de la venta es la suma de las rebajas de las lineas'
  );
  perform test_igual(
    (select count(*)::text from detalle_venta where id_venta = v_venta),
    '3',
    'la venta del carrito lleva sus tres lineas'
  );
  perform test_igual(
    (select id_oferta::text from detalle_venta
      where id_venta = v_venta and id_producto = v_samsung),
    v_o20::text,
    'cada linea de la venta recuerda su oferta'
  );
  perform test_igual(
    (select stock::text from productos where id_producto = v_samsung),
    (v_stock_antes - 1)::text,
    'el carrito descuenta el stock de cada producto'
  );

  -- El historial (0012) agrupa por venta: tres lineas, una sola fila. Antes
  -- devolvia una fila por linea y la misma compra aparecia tres veces con el
  -- mismo total, que parecia un triple cobro.
  perform test_igual(
    (select count(*)::text from fn_historial(50)),
    '1',
    'el historial devuelve una fila por venta, no por linea'
  );
  perform test_igual(
    (select unidades::text from fn_historial(50) where id_venta = v_venta),
    '4',
    'el historial suma las unidades de todas las lineas'
  );
  perform test_igual(
    (select count(*)::text from fn_venta_detalle(v_venta)),
    '3',
    'el detalle devuelve una fila por linea'
  );
  perform test_igual(
    (select sum(precio_total_centavos)::text from fn_venta_detalle(v_venta)),
    '369000',
    'las lineas del detalle suman el total de la venta'
  );
  perform test_cierto(
    exists (
      select 1 from fn_venta_detalle(v_venta)
       where nombre_oferta = 'Descuento 20%'
         and precio_total_centavos = 120000
    ),
    'el detalle recuerda con que oferta se vendio cada linea'
  );

  -- La regla que el carrito cambia (0013): tres productos con oferta en la
  -- misma confirmacion consumen UNA sola oportunidad, porque es una venta.
  perform test_igual(fn_compras_del_dia()::text, '1',
    'toda la confirmacion del carrito cuenta como una oferta usada');
  perform test_cierto(not fn_puede_usar_oferta(),
    'con la primera compra con oferta se acabo el cupo del dia');

  -- Y el carrito con oferta se rechaza entero: no queda cupo.
  perform test_falla(
    format('select fn_confirmar_carrito(
      ''[{"id_producto":%s, "cantidad":1, "id_oferta":%s},
         {"id_producto":%s, "cantidad":1}]'')', v_lenovo, v_o10, v_mouse),
    'limite_diario',
    'no hay segunda oferta el mismo dia, ni parcial ni completa'
  );

  -- A precio normal si sigue: el limite es de ofertas, no de compras.
  perform fn_confirmar_carrito(
    format('[{"id_producto":%s, "cantidad":1}]', v_mouse)::jsonb);
  perform test_igual(fn_compras_del_dia()::text, '1',
    'sin oferta, el carrito se confirma igual y no consume cupo');
end
$$;

-- --------------- EL CARRITO: TODO O NADA ---------------
--
-- Si una linea no tiene stock, la confirmacion muere completa: no quedan
-- medias ventas ni stocks a medias. La linea ya validada (y su stock ya
-- restado) se deshace igual: la excepcion de test_falla tiene un savepoint
-- disimulado que deshace todo lo que la funcion hubiera tocado.

do $$
declare
  v_cliente  bigint;
  v_lenovo   bigint;
  v_hp       bigint;
  v_ventas_antes   integer;
  v_stock_antes    integer;
begin
  insert into clientes (nombre, paterno) values ('Todo', 'O Nada')
    returning id_cliente into v_cliente;
  perform fn_simular_sesion(v_cliente);

  select id_producto into v_lenovo from productos where nombre = 'Laptop Lenovo IdeaPad';
  select id_producto into v_hp     from productos where nombre = 'Laptop HP Pavilion';

  update productos set stock = 0 where id_producto = v_hp;

  select count(*) into v_ventas_antes from venta;
  select stock   into v_stock_antes  from productos where id_producto = v_lenovo;

  perform test_falla(
    format('select fn_confirmar_carrito(
              ''[{"id_producto":%s, "cantidad":1},
                 {"id_producto":%s, "cantidad":1}]'')', v_lenovo, v_hp),
    'sin_stock',
    'una linea sin stock muere la confirmacion entera'
  );

  perform test_igual(
    (select count(*)::text from venta), v_ventas_antes::text,
    'del carrito rechazado no quedo ninguna venta'
  );
  perform test_igual(
    (select stock::text from productos where id_producto = v_lenovo),
    v_stock_antes::text,
    'y el stock de la linea ya validada tambien quedo como estaba'
  );
end
$$;

select test_falla(
  $q$ select fn_confirmar_carrito('[]') $q$,
  'carrito_vacio',
  'no se confirma un carrito vacio'
);

select test_ok('01_ciclo_venta');

rollback;
