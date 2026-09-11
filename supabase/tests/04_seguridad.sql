-- ============================================================================
-- Lo que la clave publica NO puede hacer, y lo que un cliente no puede ver de
-- otro.
--
-- La clave viaja dentro del APK y cualquiera la extrae descomprimiendolo. Que
-- la app no pueda escribir tablas no es una precaucion decorativa: si pudiera
-- hacer INSERT, tambien podria hacer UPDATE de precios. Esta prueba falla si
-- la tienda queda abierta.
--
-- `set local role anon` hace que el resto de la transaccion corra con los
-- permisos de la app, no con los del dueno de la base.
-- ============================================================================

begin;

-- Datos que la prueba necesita, creados antes de bajar de rol.
do $$
declare
  v_otro bigint;
begin
  insert into clientes (nombre, paterno) values ('Victima', 'Prueba')
    returning id_cliente into v_otro;
  -- Una compra de otra persona, para comprobar despues que no se ve.
  perform fn_simular_sesion(v_otro);
  perform fn_registrar_venta(
    (select id_producto from productos where nombre = 'Laptop HP Pavilion'),
    1, null);
  perform fn_simular_sesion(null);
end
$$;

set local role anon;

-- --------------- LEER EL CATALOGO: PERMITIDO ---------------

do $$
begin
  perform test_cierto(
    (select count(*) from v_catalogo) > 0,
    'la app puede leer el catalogo sin iniciar sesion'
  );
  perform test_cierto(
    (select count(*) from ofertas) > 0,
    'la app puede leer las ofertas publicadas'
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

-- --------------- DATOS PERSONALES Y VENTAS ---------------

select test_falla(
  $q$ select count(*) from venta $q$,
  null,
  'sin sesion NO se pueden leer las ventas'
);

select test_falla(
  $q$ select count(*) from clientes $q$,
  null,
  'sin sesion NO se puede listar a los clientes'
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

-- --------------- SIN SESION NO SE COMPRA ---------------
--
-- `anon` ni siquiera puede ejecutar las funciones: comprar, ver ofertas o
-- consultar el historial exige estar autenticado.

select test_falla(
  $q$ select fn_registrar_venta(1, 1, null) $q$,
  null,
  'anon NO puede ejecutar fn_registrar_venta'
);

select test_falla(
  $q$ select fn_historial(10) $q$,
  null,
  'anon NO puede ejecutar fn_historial'
);

select test_falla(
  $q$ select fn_ofertas_de(1) $q$,
  null,
  'anon NO puede pedir la escalera de ofertas'
);

-- La sesion simulada es de las pruebas: si la app pudiera llamarla, cualquiera
-- se haria pasar por cualquier cliente.
select test_falla(
  $q$ select fn_simular_sesion(1) $q$,
  null,
  'anon NO puede simular la sesion de otro'
);

reset role;

-- --------------- UN CLIENTE NO VE LO DE OTRO ---------------
--
-- Con sesion, cada quien ve lo suyo. Es lo que hace que el historial sea
-- personal y que el limite diario cuente las compras de una persona concreta.

do $$
declare
  v_ana    bigint;
  v_carlos bigint;
  v_hp     bigint;
begin
  select id_producto into v_hp from productos where nombre = 'Laptop HP Pavilion';

  insert into clientes (nombre, paterno) values ('Ana', 'Uno')
    returning id_cliente into v_ana;
  insert into clientes (nombre, paterno) values ('Carlos', 'Dos')
    returning id_cliente into v_carlos;

  -- Ana compra una vez.
  perform fn_simular_sesion(v_ana);
  perform fn_registrar_venta(v_hp, 1, null);
  perform test_igual(
    (select count(*)::text from fn_historial(50)), '1',
    'Ana ve su compra'
  );

  -- Carlos no ve nada: el historial va por la sesion, no por un parametro.
  perform fn_simular_sesion(v_carlos);
  perform test_igual(
    (select count(*)::text from fn_historial(50)), '0',
    'Carlos NO ve las compras de Ana'
  );

  -- Y el limite de Ana no consume el de Carlos.
  perform test_igual(fn_compras_del_dia()::text, '0',
    'las compras de Ana no cuentan para el cupo de Carlos');
  perform test_cierto(fn_puede_usar_oferta(),
    'Carlos conserva sus dos ofertas del dia');

  perform fn_simular_sesion(null);
end
$$;

-- --------------- EL PRECIO Y EL CLIENTE LOS PONE EL SERVIDOR ---------------
--
-- fn_registrar_venta no recibe ni el total ni el id del cliente: el primero lo
-- recalcula desde el catalogo, el segundo sale del token. Mientras recibiera
-- el id como parametro, cualquiera con la clave publica podia registrar
-- compras a nombre de otra persona. Esta prueba lo deja por escrito: si
-- alguien se lo vuelve a agregar, falla aqui.

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
    'fn_registrar_venta no recibe ningun precio: lo calcula el servidor'
  );
  perform test_cierto(
    v_params not ilike '%cliente%',
    'fn_registrar_venta no recibe el cliente: sale del token'
  );
end
$$;

select test_ok('04_seguridad');

rollback;
