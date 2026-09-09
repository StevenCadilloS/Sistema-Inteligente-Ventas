-- ============================================================================
-- El catalogo que ve la tienda y las ofertas que publica el administrador.
--
-- Es la parte nueva del sistema: comprueba que publicar una oferta desde el
-- panel cambie el precio que reciben los usuarios, y que la vigencia se
-- respete sin que nadie tenga que ir a apagarla a mano.
-- ============================================================================

begin;

do $prueba$
declare
  v_fila record;
begin
  -- --- catalogo base ---
  perform test_igual((select count(*) from v_catalogo)::text, '16',
    'v_catalogo publica los 16 productos sembrados');

  select * into v_fila from v_catalogo where cod_lote_producto = 'P0000001';
  perform test_igual(v_fila.descuento_oferta::text, '0',
    'sin ofertas, el descuento del administrador es 0');
  perform test_igual(v_fila.precio_vigente_centavos::text, '4990',
    'sin ofertas, el precio vigente es el de lista');
  perform test_igual(v_fila.nombre_tipo_producto, 'Tecnologia',
    'el catalogo trae el nombre de la categoria resuelto');

  -- --- el administrador publica una oferta ---
  insert into ofertas (cod_lote_producto, nombre_oferta, descuento_porcentaje)
  values ('P0000001', 'Semana tecnologica', 20);

  select * into v_fila from v_catalogo where cod_lote_producto = 'P0000001';
  perform test_igual(v_fila.descuento_oferta::text, '20',
    'la oferta publicada aparece en el catalogo de inmediato');
  perform test_igual(v_fila.nombre_oferta, 'Semana tecnologica',
    'el catalogo trae el nombre de la oferta, para poder anunciarla');
  -- 4990 - (4990 * 20 / 100) = 4990 - 998 = 3992, con division entera
  perform test_igual(v_fila.precio_vigente_centavos::text, '3992',
    'el precio vigente baja segun la oferta, en centavos enteros');

  -- --- dos ofertas solapadas: gana la mejor para el cliente ---
  insert into ofertas (cod_lote_producto, nombre_oferta, descuento_porcentaje)
  values ('P0000001', 'Liquidacion', 35);

  select * into v_fila from v_catalogo where cod_lote_producto = 'P0000001';
  perform test_igual(v_fila.descuento_oferta::text, '35',
    'con dos ofertas vigentes gana la de mayor descuento');
  perform test_igual(v_fila.cod_oferta,
    (select cod_oferta from ofertas where nombre_oferta = 'Liquidacion'),
    'el catalogo identifica cual de las dos ofertas se aplico');

  -- --- vigencia ---
  update ofertas set activo = false where nombre_oferta = 'Liquidacion';
  perform test_igual(
    (select descuento_oferta from v_catalogo where cod_lote_producto = 'P0000001')::text,
    '20',
    'desactivar una oferta devuelve la vigencia a la otra');

  update ofertas
     set vigente_desde = now() - interval '2 days',
         vigente_hasta = now() - interval '1 day'
   where nombre_oferta = 'Semana tecnologica';
  perform test_igual(
    (select descuento_oferta from v_catalogo where cod_lote_producto = 'P0000001')::text,
    '0',
    'una oferta vencida deja de aplicarse sola, sin que nadie la apague');

  insert into ofertas (cod_lote_producto, nombre_oferta, descuento_porcentaje, vigente_desde)
  values ('P0000002', 'Preventa', 15, now() + interval '1 day');
  perform test_igual(
    (select descuento_oferta from v_catalogo where cod_lote_producto = 'P0000002')::text,
    '0',
    'una oferta programada a futuro todavia no se aplica');

  -- --- limites ---
  perform test_falla(
    $x$ insert into ofertas (cod_lote_producto, nombre_oferta, descuento_porcentaje)
        values ('P0000005', 'Regalo', 100) $x$,
    null,
    'no se puede publicar un descuento del 100%');

  perform test_falla(
    $x$ insert into ofertas (cod_lote_producto, nombre_oferta, descuento_porcentaje)
        values ('P0000005', 'Nada', 0) $x$,
    null,
    'no se puede publicar un descuento de 0%');

  perform test_falla(
    $x$ insert into ofertas (cod_lote_producto, nombre_oferta, descuento_porcentaje,
                             vigente_desde, vigente_hasta)
        values ('P0000005', 'Al reves', 10, now(), now() - interval '1 day') $x$,
    null,
    'no se puede publicar una oferta que termina antes de empezar');

  perform test_falla(
    $x$ insert into ofertas (cod_lote_producto, nombre_oferta, descuento_porcentaje)
        values ('P9999999', 'Fantasma', 10) $x$,
    null,
    'no se puede publicar una oferta sobre un producto que no existe');

  -- --- productos nuevos del administrador ---
  -- El codigo se asigna solo: quien crea el producto desde el panel escribe
  -- nombre, precio y stock, no un correlativo.
  insert into productos (nombre_producto, tipo_producto, precio_unitario_centavos, total_disponible)
  values ('Teclado Mecanico', 'T00001', 21900, 7);

  perform test_igual(
    (select cod_lote_producto from productos where nombre_producto = 'Teclado Mecanico'),
    'P0000017',
    'un producto nuevo recibe el codigo siguiente sin intervencion');

  perform test_igual((select count(*) from v_catalogo)::text, '17',
    'el producto nuevo entra al catalogo que leen los usuarios');

  -- Un producto dado de baja desaparece del catalogo, pero sus ventas
  -- historicas siguen en la base (por eso `activo` y no un DELETE).
  update productos set activo = false where cod_lote_producto = 'P0000017';
  perform test_igual(
    (select count(*) from v_catalogo where activo)::text, '16',
    'desactivar un producto lo saca del catalogo activo');

  perform test_ok('catalogo y ofertas');
end;
$prueba$;

rollback;
