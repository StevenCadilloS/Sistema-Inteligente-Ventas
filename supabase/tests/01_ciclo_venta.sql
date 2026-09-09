-- ============================================================================
-- Ciclo completo: cliente -> interaccion -> venta -> detalle, con las FK
-- activas y el stock descontado.
--
-- Es la version SQL de lo que probaban app_database_test.dart,
-- cliente_repository_test.dart y bandit_optimizer_test.dart contra drift.
-- Se mudo aqui porque la logica se mudo aqui: la atomicidad de la venta y la
-- asignacion de correlativos ya no ocurren en el dispositivo.
--
-- Espera una base recien migrada (secuencias en 1) y se ejecuta antes que las
-- demas pruebas que consumen esas mismas secuencias.
-- ============================================================================

begin;

do $prueba$
declare
  v_cliente   text;
  v_cliente2  text;
  v_proceso   text;
  v_proceso2  text;
  v_fila      record;
begin
  -- --- registro de cliente: el codigo lo asigna el servidor ---
  v_cliente := fn_registrar_cliente('Ada', 'Lovelace', 'T00001');
  perform test_igual(v_cliente, 'C0000001', 'el primer cliente recibe C0000001');

  v_cliente2 := fn_registrar_cliente('Alan', 'Turing', null);
  perform test_igual(v_cliente2, 'C0000002', 'el segundo registro continua el secuencial');

  -- C3: tipo_cliente es nullable, el KPI 3 agrupa por el pero no todos lo tienen
  perform test_igual(
    (select tipo_cliente from clientes where cod_cliente = v_cliente2)::text,
    null,
    'se puede registrar sin tipo de cliente (C3)');

  perform test_falla(
    $x$ select fn_registrar_cliente('  ', 'Sinnombre', null) $x$,
    'datos_invalidos',
    'no deja registrar con el nombre en blanco');

  -- --- interaccion ---
  v_proceso := fn_registrar_interaccion(v_cliente, 'triste', 'P0000001', 'E0000001', 88);
  perform test_igual(v_proceso, 'PP00000001', 'el primer proceso de persuasion es PP00000001');

  select * into v_fila from interacciones where id_proceso_persuasion = v_proceso;
  perform test_igual(v_fila.correlativo::text, '1', 'el primer correlativo del canal A es 1');
  perform test_igual(v_fila.canal, 'A', 'el canal por defecto es A (app movil)');
  perform test_igual(v_fila.cod_gesto, 'G0000001',
    'la emocion "triste" se traduce a su codigo de gesto en el servidor');
  perform test_igual(v_fila.nivel_de_interes::text, '88', 'guarda el nivel de interes');

  -- El contador de exhibiciones es lo unico que hace que las reglas "neutral"
  -- (lo mas mostrado) y "sorpresa" (lo menos mostrado) cambien de resultado.
  perform test_igual(
    (select total_veces_mostrado from productos where cod_lote_producto = 'P0000001')::text,
    '43',
    'registrar la interaccion incrementa total_veces_mostrado (42 -> 43)');

  -- Una emocion fuera del catalogo no debe tumbar el pipeline: entra sin gesto.
  v_proceso2 := fn_registrar_interaccion(v_cliente, 'no_face', 'P0000002', null, 0);
  perform test_igual(
    (select cod_gesto from interacciones where id_proceso_persuasion = v_proceso2)::text,
    null,
    'una emocion no catalogada se registra igual, sin gesto');
  perform test_igual(
    (select correlativo from interacciones where id_proceso_persuasion = v_proceso2)::text,
    '2',
    'el correlativo avanza de a uno');

  -- --- FK activas ---
  perform test_falla(
    $x$ select fn_registrar_interaccion('C9999999', 'feliz', 'P0000001', null, 50) $x$,
    null,
    'las FK rechazan un cod_cliente que no existe');

  perform test_falla(
    $x$ select fn_registrar_interaccion('C0000001', 'feliz', 'P9999999', null, 50) $x$,
    null,
    'las FK rechazan un producto que no existe');

  -- --- venta ---
  -- El precio que se congela es el ofrecido (4990 con 10% = 4491), no el de
  -- lista: la venta debe registrar lo que se pacto.
  perform fn_registrar_venta(v_proceso, 4491);

  select * into v_fila from ventas where id_proceso_persuasion = v_proceso;
  perform test_igual(v_fila.cod_cliente, v_cliente, 'la venta hereda el cliente de la interaccion');
  perform test_igual(v_fila.cod_estrategia, 'E0000001', 'la venta hereda la estrategia');
  perform test_igual(v_fila.correlativo::text, '1', 'la venta arranca su propio correlativo en 1');

  perform test_igual(
    (select precio_unitario_centavos from detalle_venta where venta_id = v_fila.id)::text,
    '4491',
    'el detalle congela el precio realmente ofrecido, no el de lista');

  perform test_igual(
    (select total_disponible from productos where cod_lote_producto = 'P0000001')::text,
    '29',
    'la venta descuenta una unidad del stock (30 -> 29)');

  -- --- rechazo ---
  -- Rechazar no escribe nada: la ausencia de venta con ese proceso ES el
  -- rechazo, y asi lo mide el KPI 2.
  perform test_igual(
    (select count(*) from ventas where id_proceso_persuasion = v_proceso2)::text,
    '0',
    'el rechazo no deja fila en ventas');

  -- --- errores esperados ---
  perform test_falla(
    $x$ select fn_registrar_venta('PP99999999', null) $x$,
    'proceso_inexistente',
    'cerrar un proceso que no existe falla con su pista');

  update productos set total_disponible = 0 where cod_lote_producto = 'P0000003';
  perform test_falla(
    format($x$ select fn_registrar_venta(%L, null) $x$,
           fn_registrar_interaccion(v_cliente, 'feliz', 'P0000003', null, 40)),
    'sin_stock',
    'vender un producto agotado falla con la pista sin_stock');

  -- El CHECK de la tabla es la ultima linea de defensa, por si alguien edita
  -- el inventario a mano desde el panel.
  perform test_falla(
    $x$ update productos set total_disponible = -1 where cod_lote_producto = 'P0000004' $x$,
    null,
    'la base no acepta stock negativo');

  perform test_ok('ciclo de venta');
end;
$prueba$;

rollback;
