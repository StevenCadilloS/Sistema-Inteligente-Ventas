-- ============================================================================
-- Ciclo de venta: registro de cliente, compra a precio normal, compra con
-- oferta, stock y errores esperados.
--
-- Todo dentro de una transaccion que termina en ROLLBACK: la prueba no deja
-- datos. Las secuencias si avanzan, pero ninguna prueba afirma sobre un id
-- concreto justamente por eso.
-- ============================================================================

begin;

-- --------------- REGISTRO DE CLIENTE ---------------

do $$
declare
  v_cliente bigint;
begin
  v_cliente := fn_registrar_cliente('Prueba', 'Apellido', null, '900000000', 'prueba@test.com');
  perform test_cierto(v_cliente is not null, 'fn_registrar_cliente devuelve un id');
  perform test_igual(
    (select nombre from clientes where id_cliente = v_cliente),
    'Prueba',
    'el cliente queda guardado con su nombre'
  );
end
$$;

-- Un nombre vacio no es un cliente.
select test_falla(
  $q$ select fn_registrar_cliente('   ') $q$,
  'nombre_vacio',
  'no se puede registrar un cliente sin nombre'
);

-- --------------- COMPRA A PRECIO NORMAL ---------------

do $$
declare
  v_cliente  bigint;
  v_producto bigint;
  v_venta    bigint;
  v_stock_antes integer;
begin
  v_cliente := fn_registrar_cliente('Sin', 'Oferta');
  select id_producto, stock into v_producto, v_stock_antes
    from productos where nombre = 'Laptop HP Pavilion';

  v_venta := fn_registrar_venta(v_cliente, v_producto, 1, null);

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
  v_cliente := fn_registrar_cliente('Con', 'Oferta');
  select id_producto into v_producto from productos where nombre = 'Laptop Lenovo IdeaPad';
  select id_oferta into v_oferta from ofertas where nombre = 'Descuento 10%';

  v_venta := fn_registrar_venta(v_cliente, v_producto, 1, v_oferta);

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

select test_falla(
  $q$ select fn_registrar_venta(999999, (select min(id_producto) from productos), 1, null) $q$,
  'cliente_inexistente',
  'no se puede vender a un cliente que no existe'
);

select test_falla(
  $q$ select fn_registrar_venta((select min(id_cliente) from clientes), 999999, 1, null) $q$,
  'producto_inexistente',
  'no se puede vender un producto que no existe'
);

select test_falla(
  $q$ select fn_registrar_venta(
        (select min(id_cliente) from clientes),
        (select min(id_producto) from productos), 0, null) $q$,
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
  v_cliente := fn_registrar_cliente('Oferta', 'Ajena');
  select id_producto into v_hp from productos where nombre = 'Laptop HP Pavilion';
  select id_oferta into v_oferta from ofertas where nombre = 'Descuento 10%';

  perform test_falla(
    format('select fn_registrar_venta(%s, %s, 1, %s)', v_cliente, v_hp, v_oferta),
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
begin
  v_cliente := fn_registrar_cliente('Sin', 'Stock');
  select id_producto into v_producto from productos where nombre = 'Samsung Galaxy A55';

  update productos set stock = 0 where id_producto = v_producto;

  perform test_falla(
    format('select fn_registrar_venta(%s, %s, 1, null)', v_cliente, v_producto),
    'sin_stock',
    'no se puede vender un producto agotado'
  );
end
$$;

-- --------------- PRODUCTO INACTIVO ---------------

do $$
declare
  v_cliente  bigint;
  v_producto bigint;
begin
  v_cliente := fn_registrar_cliente('Producto', 'Inactivo');
  select id_producto into v_producto from productos where nombre = 'Mouse Logitech G203';

  update productos set activo = false where id_producto = v_producto;

  perform test_falla(
    format('select fn_registrar_venta(%s, %s, 1, null)', v_cliente, v_producto),
    'producto_inactivo',
    'no se puede vender un producto dado de baja'
  );
end
$$;

select test_ok('01_ciclo_venta');

rollback;
