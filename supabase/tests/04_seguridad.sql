-- ============================================================================
-- Permisos del rol anonimo.
--
-- Es la prueba que justifica toda la arquitectura de escritura por funciones.
-- La clave anonima viaja dentro del APK: cualquiera que descomprima el
-- paquete la tiene y puede hablar con la base directamente, sin pasar por la
-- app. Lo que aqui se comprueba es que con esa clave en la mano no se pueda
-- cambiar un precio, crear un producto ni falsificar una venta.
--
-- Si alguna de estas pruebas empieza a fallar, la tienda quedo abierta.
-- ============================================================================

begin;

set local role anon;

do $prueba$
declare
  v_cliente text;
begin
  -- --- lo que si puede: leer ---
  perform test_igual((select count(*) from productos)::text, '16',
    'anon puede leer el catalogo');
  perform test_igual((select count(*) from v_catalogo)::text, '16',
    'anon puede leer la vista del catalogo');
  perform test_cierto((select count(*) from v_estrategia_desempeno) = 4,
    'anon puede leer el desempeno de estrategias (lo necesita el UCB1)');
  perform test_cierto(es_admin() is false,
    'anon no es administrador');

  -- --- lo que no puede: escribir el catalogo ---
  perform test_falla(
    $x$ update productos set precio_unitario_centavos = 1
         where cod_lote_producto = 'P0000001' $x$,
    null,
    'anon NO puede cambiar precios');

  perform test_falla(
    $x$ update productos set total_disponible = 9999
         where cod_lote_producto = 'P0000001' $x$,
    null,
    'anon NO puede inflar el stock');

  perform test_falla(
    $x$ insert into productos (nombre_producto, precio_unitario_centavos)
        values ('Producto pirata', 1) $x$,
    null,
    'anon NO puede crear productos');

  perform test_falla(
    $x$ delete from productos where cod_lote_producto = 'P0000001' $x$,
    null,
    'anon NO puede borrar productos');

  perform test_falla(
    $x$ insert into ofertas (cod_lote_producto, nombre_oferta, descuento_porcentaje)
        values ('P0000005', 'Descuento propio', 90) $x$,
    null,
    'anon NO puede publicar ofertas');

  -- --- lo que no puede: escribir bitacoras a mano ---
  -- Escribir ventas directamente permitiria inventar cierres y envenenar el
  -- aprendizaje UCB1, que se alimenta justo de esa tabla.
  perform test_falla(
    $x$ insert into ventas (canal, correlativo, id_proceso_persuasion, cod_cliente,
                            tipo_transaccion)
        values ('A', 999, 'PP99999999', 'C0000001', 'TRX0001') $x$,
    null,
    'anon NO puede inventar ventas');

  perform test_falla(
    $x$ insert into interacciones (canal, correlativo, id_proceso_persuasion,
                                   cod_cliente, tipo_transaccion, nivel_de_interes)
        values ('A', 999, 'PP99999999', 'C0000001', 'TRX0001', 100) $x$,
    null,
    'anon NO puede escribir interacciones directamente');

  perform test_falla(
    $x$ update clientes set monto_total_centavos = 0 $x$,
    null,
    'anon NO puede reescribir los totales de los clientes');

  perform test_falla(
    $x$ insert into administradores (id) values (gen_random_uuid()) $x$,
    null,
    'anon NO puede darse de alta como administrador');

  -- Los secuenciadores no se exponen: llamarlos sueltos solo serviria para
  -- quemar correlativos y abrir huecos en la bitacora.
  perform test_falla(
    $x$ select fn_siguiente_correlativo('ventas', 'A') $x$,
    null,
    'anon NO puede consumir correlativos a mano');

  -- --- lo que si puede, pero solo por la puerta correcta ---
  v_cliente := fn_registrar_cliente('Cliente', 'Anonimo', null);
  perform test_cierto(v_cliente like 'C%',
    'anon SI puede registrarse mediante la funcion');

  perform test_cierto(
    fn_registrar_interaccion(v_cliente, 'neutral', 'P0000001', 'E0000001', 50) like 'PP%',
    'anon SI puede registrar una interaccion mediante la funcion');

  perform test_ok('permisos del rol anonimo');
end;
$prueba$;

reset role;

rollback;
