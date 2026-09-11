-- ============================================================================
-- Lo que la clave publica NO puede hacer.
--
-- Esa clave viaja dentro del APK y cualquiera la extrae descomprimiendolo.
-- Que la app no pueda escribir tablas no es una precaucion decorativa: si
-- pudiera hacer INSERT, tambien podria hacer UPDATE de precios. Esta prueba
-- falla si la tienda queda abierta.
--
-- `set local role anon` hace que el resto de la transaccion corra con los
-- permisos de la app, no con los del dueno de la base.
-- ============================================================================

begin;

-- Datos que la prueba necesita, creados antes de bajar de rol.
do $$
begin
  perform fn_registrar_cliente('Victima', 'Prueba');
end
$$;

set local role anon;

-- --------------- LEER EL CATALOGO: PERMITIDO ---------------

do $$
begin
  perform test_cierto(
    (select count(*) from v_catalogo) > 0,
    'la app puede leer el catalogo'
  );
  perform test_cierto(
    (select count(*) from productos) > 0,
    'la app puede leer los productos'
  );
  perform test_cierto(
    (select count(*) from ofertas) > 0,
    'la app puede leer las ofertas'
  );
end
$$;

-- --------------- TOCAR PRECIOS: PROHIBIDO ---------------

select test_falla(
  $q$ update productos set precio_centavos = 1 $q$,
  null,
  'la app NO puede cambiar precios'
);

select test_falla(
  $q$ update productos set stock = 9999 $q$,
  null,
  'la app NO puede inventar stock'
);

select test_falla(
  $q$ insert into productos (id_categoria, id_marca, nombre, precio_centavos)
      values (1, 1, 'Producto pirata', 1) $q$,
  null,
  'la app NO puede crear productos'
);

select test_falla(
  $q$ delete from productos $q$,
  null,
  'la app NO puede borrar el catalogo'
);

-- --------------- PUBLICAR OFERTAS: PROHIBIDO ---------------
--
-- Si pudiera, se publicaria un 90% a si misma y saltaria el limite diario.

select test_falla(
  $q$ insert into ofertas (id_admin, nombre, id_tipo, porcentaje_descuento, fecha_inicio)
      values (1, 'Oferta pirata', 1, 90, now()) $q$,
  null,
  'la app NO puede publicar ofertas'
);

select test_falla(
  $q$ update ofertas set porcentaje_descuento = 90 $q$,
  null,
  'la app NO puede subir el descuento de una oferta existente'
);

select test_falla(
  $q$ update ofertas_productos set orden = 1 $q$,
  null,
  'la app NO puede reordenar la escalera de ofertas'
);

-- --------------- VENTAS Y DATOS PERSONALES ---------------
--
-- `venta` y `clientes` no son de lectura publica: contienen el historial de
-- compra y los datos de contacto de otras personas.

select test_falla(
  $q$ select count(*) from venta $q$,
  null,
  'la app NO puede leer las ventas de todos'
);

select test_falla(
  $q$ select count(*) from clientes $q$,
  null,
  'la app NO puede listar a los clientes'
);

select test_falla(
  $q$ select count(*) from detalle_venta $q$,
  null,
  'la app NO puede leer el detalle de las ventas'
);

select test_falla(
  $q$ insert into venta (id_cliente, subtotal_centavos, descuento_centavos, total_centavos)
      values (1, 100, 0, 100) $q$,
  null,
  'la app NO puede grabar una venta directamente'
);

select test_falla(
  $q$ update venta set total_centavos = 0 $q$,
  null,
  'la app NO puede alterar el total de una venta'
);

-- --------------- LO QUE SI PUEDE: LAS FUNCIONES ---------------
--
-- Las tres escrituras legitimas pasan por funciones que validan las reglas
-- antes de escribir.

do $$
declare
  v_cliente bigint;
  v_hp      bigint;
  v_venta   bigint;
begin
  v_cliente := fn_registrar_cliente('Cliente', 'Legitimo');
  perform test_cierto(v_cliente is not null,
    'la app SI puede registrar un cliente por la funcion');

  select id_producto into v_hp from productos where nombre = 'Laptop HP Pavilion';
  v_venta := fn_registrar_venta(v_cliente, v_hp, 1, null);
  perform test_cierto(v_venta is not null,
    'la app SI puede registrar una venta por la funcion');

  -- Y puede leer su propio historial, no el de los demas.
  perform test_igual(
    (select count(*)::text from fn_historial(v_cliente, 50)),
    '1',
    'la app SI puede leer el historial del cliente en curso'
  );
end
$$;

-- --------------- EL PRECIO LO PONE EL SERVIDOR ---------------
--
-- fn_registrar_venta no acepta un total de la app: lo recalcula desde el
-- catalogo. Si aceptara, la app podria pagar 1 centavo por una laptop.
-- La firma de la funcion no tiene ningun parametro de precio, y esta prueba
-- lo deja por escrito: si alguien se lo agrega, falla aqui.

do $$
declare
  v_params text;
begin
  select pg_get_function_arguments(p.oid) into v_params
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'fn_registrar_venta';

  perform test_cierto(
    v_params not ilike '%total%' and v_params not ilike '%precio%',
    'fn_registrar_venta no recibe ningun precio de la app: lo calcula el servidor'
  );
end
$$;

reset role;

select test_ok('04_seguridad');

rollback;
