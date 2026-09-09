-- ============================================================================
-- Modulo batch y KPIs.
--
-- Version SQL de batch_runner_test.dart y casos_reales_test.dart. Los numeros
-- esperados son los mismos que verificaban aquellas pruebas contra drift; lo
-- que cambio es donde corre el calculo.
-- ============================================================================

begin;

do $prueba$
declare
  v_cliente text;
  v_p1 text; v_p2 text; v_p3 text;
  v_antes record;
begin
  -- --- KPI 2 sobre una base sin ventas ---
  -- En SQL, COUNT(*) = 0 hace que la division devuelva NULL. Sin el COALESCE
  -- de la vista, la pantalla de KPIs recibiria un nulo donde espera un numero.
  perform test_igual((select porcentaje from v_kpi2_ventas_sin_alternativa)::text, '0.0',
    'KPI2 devuelve 0.0 con la base vacia, no NULL');

  perform test_igual((select count(*) from v_kpi1_cierre_por_mes)::text, '0',
    'KPI1 sin interacciones no devuelve filas');

  -- --- datos ---
  v_cliente := fn_registrar_cliente('Grace', 'Hopper', 'T00002');

  -- Dos procesos que cierran y uno que no: 2 de 3 = 66.67% de cierre.
  v_p1 := fn_registrar_interaccion(v_cliente, 'feliz', 'P0000001', 'E0000001', 90);
  perform fn_registrar_venta(v_p1, 4990);

  v_p2 := fn_registrar_interaccion(v_cliente, 'triste', 'P0000002', 'E0000001', 70);
  perform fn_registrar_venta(v_p2, 11610);

  v_p3 := fn_registrar_interaccion(v_cliente, 'enojo', 'P0000003', 'E0000002', 40);
  -- sin venta: rechazado

  -- --- cierre diario ---
  select cant_lecturas, total_compras, monto_total_centavos
    into v_antes from clientes where cod_cliente = v_cliente;
  perform test_igual(v_antes.total_compras::text, '0',
    'los contadores derivados no se tocan al vender: son del batch');

  perform fn_cierre_diario();

  perform test_igual(
    (select cant_lecturas from clientes where cod_cliente = v_cliente)::text, '3',
    'cant_lecturas cuenta procesos de persuasion distintos (D1)');
  perform test_igual(
    (select total_compras from clientes where cod_cliente = v_cliente)::text, '2',
    'total_compras cuenta las ventas del cliente');
  perform test_igual(
    (select monto_total_centavos from clientes where cod_cliente = v_cliente)::text, '16600',
    'monto_total suma los precios pactados (4990 + 11610), no los de lista');
  perform test_cierto(
    (select ultima_visita is not null from clientes where cod_cliente = v_cliente),
    'ultima_visita queda con la fecha de la ultima venta');

  perform test_igual(
    (select total_veces_aplicada from estrategias where cod_estrategia = 'E0000001')::text, '2',
    'total_veces_aplicada agrupa por estrategia (D1), no por cliente');
  perform test_igual(
    (select ventas_generadas from estrategias where cod_estrategia = 'E0000001')::text, '2',
    'ventas_generadas cuenta los cierres de esa estrategia');
  perform test_igual(
    (select total_veces_aplicada from estrategias where cod_estrategia = 'E0000002')::text, '1',
    'la estrategia rechazada si cuenta como aplicada');
  perform test_igual(
    (select ventas_generadas from estrategias where cod_estrategia = 'E0000002')::text, '0',
    'la estrategia rechazada no genero ventas');

  -- D3: cierres_venta y total_vendidos miden lo mismo y deben coincidir.
  perform test_igual(
    (select cierres_venta from productos where cod_lote_producto = 'P0000001')::text, '1',
    'cierres_venta se mantiene en productos (D3)');
  perform test_igual(
    (select total_vendidos from productos where cod_lote_producto = 'P0000001')::text, '1',
    'total_vendidos coincide con cierres_venta');

  -- --- idempotencia ---
  -- El cierre recalcula desde las bitacoras en vez de acumular. Si acumulara,
  -- correrlo dos veces (un reintento del programador, dos dispositivos a la
  -- vez) duplicaria todos los contadores.
  perform fn_cierre_diario();
  perform fn_cierre_diario();
  perform test_igual(
    (select cant_lecturas from clientes where cod_cliente = v_cliente)::text, '3',
    'correr el cierre tres veces da el mismo resultado que una');
  perform test_igual(
    (select total_veces_aplicada from estrategias where cod_estrategia = 'E0000001')::text, '2',
    'el cierre es idempotente tambien en estrategias');

  -- --- KPIs ---
  perform test_igual(
    (select cierres::text from v_kpi1_cierre_por_mes where mes = to_char(now(), 'YYYY-MM')),
    '2', 'KPI1 cuenta los 2 procesos cerrados del mes');
  perform test_igual(
    (select intentos::text from v_kpi1_cierre_por_mes where mes = to_char(now(), 'YYYY-MM')),
    '3', 'KPI1 cuenta los 3 intentos del mes');
  perform test_igual(
    (select porcentaje::text from v_kpi1_cierre_por_mes where mes = to_char(now(), 'YYYY-MM')),
    '66.67', 'KPI1 calcula el porcentaje de cierre del mes');

  -- Los dos procesos cerrados mostraron un unico producto cada uno.
  perform test_igual((select porcentaje from v_kpi2_ventas_sin_alternativa)::text, '100.00',
    'KPI2: las 2 ventas se cerraron sin mostrar alternativa');

  perform test_igual(
    (select ventas_generadas::text from v_kpi3_efectividad_por_tipo_cliente
      where tipo_cliente = 'T00002' and cod_estrategia = 'E0000001'),
    '2', 'KPI3 agrupa cierres por tipo de cliente y estrategia');
  perform test_igual(
    (select efectividad::text from v_kpi3_efectividad_por_tipo_cliente
      where tipo_cliente = 'T00002' and cod_estrategia = 'E0000001'),
    '100.00', 'KPI3 calcula la efectividad de la estrategia');

  perform test_igual((select sum(ventas) from v_kpi4_ventas_por_dia_semana)::text, '2',
    'KPI4 suma las 2 ventas registradas');
  perform test_igual((select sum(porcentaje) from v_kpi4_ventas_por_dia_semana)::text, '100.00',
    'KPI4 reparte el 100% entre los dias');

  -- --- la vista de consulta critica (C10/G8) ---
  perform test_igual((select count(*) from v_cierres_por_tipo_producto)::text, '2',
    'la vista de cierres tiene una fila por venta-producto');
  perform test_igual(
    (select importe_centavos::text from v_cierres_por_tipo_producto
      where cod_lote_producto = 'P0000001'),
    '4990', 'la vista de cierres calcula el importe con el precio pactado');

  -- --- desempeno para el UCB1 ---
  -- Se calcula en vivo desde las bitacoras, no desde las columnas del batch:
  -- mezclar ambas fuentes haria que se pisen entre si.
  perform test_igual(
    (select intentos::text from v_estrategia_desempeno where cod_estrategia = 'E0000001'),
    '2', 'el desempeno cuenta intentos en vivo');
  perform test_igual(
    (select exitos::text from v_estrategia_desempeno where cod_estrategia = 'E0000001'),
    '2', 'el desempeno cuenta exitos en vivo');
  perform test_igual(
    (select intentos::text from v_estrategia_desempeno where cod_estrategia = 'E0000003'),
    '0', 'una estrategia nunca aplicada queda en 0, no ausente');
  perform test_igual((select count(*) from v_estrategia_desempeno)::text, '4',
    'el desempeno lista las 4 estrategias, tambien las no probadas');

  perform test_ok('batch y KPIs');
end;
$prueba$;

rollback;
