-- ============================================================================
-- 0002 - Funciones, vistas y Realtime
--
-- Aqui vive todo lo que la app NO puede hacer con un simple INSERT desde el
-- telefono. Dos razones, y ninguna es de estilo:
--
--   a) Atomicidad real entre dispositivos. En la version local, "insertar la
--      venta y descontar el stock" iba en una transaccion de SQLite, y con un
--      unico escritor eso bastaba. Con varios celulares comprando el mismo
--      producto, la transaccion tiene que vivir donde estan los datos, o dos
--      compras simultaneas venden la ultima unidad dos veces.
--
--   b) Permisos. La clave anonima esta dentro del APK. Si la app pudiera
--      hacer INSERT directo, tambien podria hacer UPDATE de precios. Las
--      funciones SECURITY DEFINER son la unica puerta de escritura, y validan
--      antes de abrir.
-- ============================================================================

-- --------------- SECUENCIADORES ---------------

-- Devuelve el siguiente correlativo de una bitacora y canal, bloqueando esa
-- fila. Dos llamadas concurrentes se serializan: la segunda espera y recibe
-- el numero siguiente, nunca el mismo.
create or replace function fn_siguiente_correlativo(p_bitacora text, p_canal text)
returns integer
language sql
security definer
set search_path = public
as $fn$
  insert into correlativos (bitacora, canal, ultimo)
  values (p_bitacora, p_canal, 1)
  on conflict (bitacora, canal)
    do update set ultimo = correlativos.ultimo + 1
  returning ultimo;
$fn$;

-- C1: la clave que une el intento (interaccion) con el cierre (venta).
-- Aqui si se usa una secuencia nativa: un hueco en la numeracion de procesos
-- no rompe ninguna auditoria (no es un correlativo contable), y a cambio no
-- serializa a todos los clientes contra una misma fila.
create or replace function fn_siguiente_proceso()
returns text
language sql
security definer
set search_path = public
as $fn$
  select 'PP' || lpad(nextval('seq_proceso_persuasion')::text, 8, '0');
$fn$;

-- --------------- ESCRITURAS DE LA APP ---------------

-- Registro de cliente. Sustituye a ClienteRepository._siguienteCodCliente,
-- que leia el maximo codigo local: con una base compartida, dos registros
-- simultaneos leian el mismo maximo y el segundo chocaba contra la PK.
create or replace function fn_registrar_cliente(
  p_nombre       text,
  p_apellido     text,
  p_tipo_cliente text default null
)
returns text
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_cod_cliente text;
begin
  if coalesce(trim(p_nombre), '') = '' or coalesce(trim(p_apellido), '') = '' then
    raise exception 'Nombre y apellido son obligatorios' using hint = 'datos_invalidos';
  end if;

  insert into clientes (nombre, apellido, tipo_cliente)
  values (trim(p_nombre), trim(p_apellido), p_tipo_cliente)
  returning cod_cliente into v_cod_cliente;

  return v_cod_cliente;
end;
$fn$;

-- Registro del intento de persuasion. Devuelve el id_proceso_persuasion, que
-- es lo que la app necesita para poder cerrar la venta despues.
--
-- Recibe el NOMBRE de la emocion, no el codigo: el modulo Kotlin
-- (EmotionProcessor.kt) solo produce nombres y no conoce el catalogo. Una
-- emocion no catalogada (por ejemplo "no_face") entra igual, con cod_gesto
-- nulo: se pierde el dato del gesto, no la interaccion.
create or replace function fn_registrar_interaccion(
  p_cod_cliente       text,
  p_emocion           text,
  p_cod_lote_producto text,
  p_cod_estrategia    text default null,
  p_nivel_de_interes  integer default 0,
  p_canal             text default 'A'
)
returns text
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_proceso   text;
  v_cod_gesto text;
begin
  select cod_gesto into v_cod_gesto from gestos where nombre_gesto = p_emocion;

  v_proceso := fn_siguiente_proceso();

  insert into interacciones (
    canal, correlativo, id_proceso_persuasion, cod_cliente,
    cod_estrategia, cod_gesto, cod_lote_producto, tipo_transaccion,
    nivel_de_interes
  ) values (
    p_canal,
    fn_siguiente_correlativo('interacciones', p_canal),
    v_proceso,
    p_cod_cliente,
    p_cod_estrategia,
    v_cod_gesto,
    p_cod_lote_producto,
    'TRX0001',
    greatest(0, least(100, coalesce(p_nivel_de_interes, 0)))
  );

  -- Sin esto, las reglas "neutral" (lo mas mostrado) y "sorpresa" (lo menos
  -- mostrado) nunca cambiarian de resultado: nada mas escribe esta columna.
  -- Incremento relativo en SQL, no leer-sumar-escribir desde la app.
  if p_cod_lote_producto is not null then
    update productos
       set total_veces_mostrado = total_veces_mostrado + 1
     where cod_lote_producto = p_cod_lote_producto;
  end if;

  return v_proceso;
end;
$fn$;

-- Cierre de la venta: cabecera, detalle y descuento de stock en una sola
-- transaccion del servidor.
--
-- Rechazar no llama a nada: la AUSENCIA de venta con ese
-- id_proceso_persuasion es el rechazo, y asi lo mide el KPI 2.
create or replace function fn_registrar_venta(
  p_id_proceso_persuasion text,
  p_precio_final_centavos integer default null
)
returns bigint
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_interaccion interacciones%rowtype;
  v_producto    productos%rowtype;
  v_venta_id    bigint;
  v_precio      integer;
begin
  -- Un proceso puede tener mas de una interaccion (varios productos mostrados
  -- en la misma sesion). La ultima es la que cierra.
  select * into v_interaccion
    from interacciones
   where id_proceso_persuasion = p_id_proceso_persuasion
   order by timestamp desc, id desc
   limit 1;

  if not found then
    raise exception 'No existe el proceso de persuasion %', p_id_proceso_persuasion
      using hint = 'proceso_inexistente';
  end if;

  if v_interaccion.cod_lote_producto is null then
    raise exception 'La interaccion % no tiene producto asociado', p_id_proceso_persuasion
      using hint = 'sin_producto';
  end if;

  -- FOR UPDATE: bloquea la fila del producto hasta el final de la funcion. Es
  -- lo que impide que dos compras simultaneas lean el mismo stock disponible
  -- y ambas se lo lleven.
  select * into v_producto
    from productos
   where cod_lote_producto = v_interaccion.cod_lote_producto
     for update;

  if v_producto.total_disponible <= 0 then
    raise exception 'Sin stock de %', v_producto.nombre_producto
      using hint = 'sin_stock';
  end if;

  -- El precio que se congela es el que se le mostro al cliente, con descuento
  -- ya aplicado. Si la app no lo manda, se usa el de lista.
  v_precio := coalesce(p_precio_final_centavos, v_producto.precio_unitario_centavos);

  insert into ventas (
    canal, correlativo, id_proceso_persuasion, cod_cliente,
    cod_estrategia, tipo_transaccion
  ) values (
    v_interaccion.canal,
    fn_siguiente_correlativo('ventas', v_interaccion.canal),
    p_id_proceso_persuasion,
    v_interaccion.cod_cliente,
    v_interaccion.cod_estrategia,
    v_interaccion.tipo_transaccion
  )
  returning id into v_venta_id;

  insert into detalle_venta (venta_id, cod_lote_producto, cantidad, precio_unitario_centavos)
  values (v_venta_id, v_producto.cod_lote_producto, 1, v_precio);

  update productos
     set total_disponible = total_disponible - 1
   where cod_lote_producto = v_producto.cod_lote_producto;

  return v_venta_id;
end;
$fn$;

-- --------------- MODULO BATCH ---------------

-- Cierre diario: los 6 procesos derivados. Una funcion plpgsql corre dentro
-- de una sola transaccion, asi que la atomicidad que exigia
-- docs/Consideraciones.docx ("se actualizan todos o ninguno") la da el motor,
-- no una convencion de codigo.
--
-- Es idempotente: recalcula cada contador desde las bitacoras, no acumula.
-- Por eso puede ejecutarse a demanda desde la app durante la presentacion sin
-- riesgo de descuadrar nada.
--
-- Independiente del aprendizaje UCB1, que recalcula exitos/intentos en vivo
-- desde interacciones/ventas y nunca lee ni escribe estas columnas.
create or replace function fn_cierre_diario()
returns void
language plpgsql
security definer
set search_path = public
as $fn$
begin
  -- D1: agrupa por cod_estrategia, no por cod_cliente como decia el diagrama
  -- original. COUNT(DISTINCT id_proceso_persuasion), no COUNT(*): un mismo
  -- proceso puede mostrar la misma estrategia en mas de una interaccion.
  update estrategias e set total_veces_aplicada = (
    select count(distinct i.id_proceso_persuasion)
      from interacciones i where i.cod_estrategia = e.cod_estrategia);

  update estrategias e set ventas_generadas = (
    select count(distinct v.id_proceso_persuasion)
      from ventas v where v.cod_estrategia = e.cod_estrategia);

  -- D1: cant_lecturas = procesos de persuasion distintos por cliente.
  update clientes c set cant_lecturas = (
    select count(distinct i.id_proceso_persuasion)
      from interacciones i where i.cod_cliente = c.cod_cliente);

  update clientes c set
    total_compras = (
      select count(*) from ventas v where v.cod_cliente = c.cod_cliente),
    monto_total_centavos = (
      select coalesce(sum(d.cantidad * d.precio_unitario_centavos), 0)
        from ventas v join detalle_venta d on d.venta_id = v.id
       where v.cod_cliente = c.cod_cliente),
    ultima_visita = (
      select max(v.timestamp) from ventas v where v.cod_cliente = c.cod_cliente);

  -- D3: cierres_venta se mantiene en productos (mismo COUNT que total_vendidos).
  update productos p set cierres_venta = (
    select count(*) from detalle_venta d
     where d.cod_lote_producto = p.cod_lote_producto);

  update productos p set total_vendidos = (
    select count(*) from detalle_venta d
     where d.cod_lote_producto = p.cod_lote_producto);
end;
$fn$;

-- --------------- VISTAS DE CATALOGO ---------------

-- La oferta vigente de cada producto. DISTINCT ON deja una sola fila por
-- producto: si el administrador publica dos ofertas solapadas sobre el mismo
-- articulo, gana la de mayor descuento (al cliente se le respeta la mejor).
create or replace view v_ofertas_vigentes as
select distinct on (cod_lote_producto)
       cod_lote_producto, cod_oferta, nombre_oferta, descuento_porcentaje, vigente_hasta
  from ofertas
 where activo
   and vigente_desde <= now()
   and (vigente_hasta is null or vigente_hasta > now())
 order by cod_lote_producto, descuento_porcentaje desc;

-- Lo que la tienda lee. Un solo viaje trae producto, categoria, stock y la
-- oferta publicada por el administrador.
--
-- `descuento_oferta` es el descuento del administrador; el descuento
-- adaptativo (el que decide la emocion) NO vive aqui, se calcula en el
-- dispositivo. La composicion de ambos esta en AdaptationEngine y es "el
-- mayor de los dos, nunca la suma": sumarlos permitiria que una promocion del
-- 40% mas un enojo del 25% terminara regalando el producto.
create or replace view v_catalogo as
select p.cod_lote_producto,
       p.nombre_producto,
       p.tipo_producto,
       tp.nombre_tipo_producto,
       p.precio_unitario_centavos,
       p.imagen,
       p.total_disponible,
       p.total_veces_mostrado,
       p.total_vendidos,
       p.cierres_venta,
       p.fecha_creacion_stock,
       p.activo,
       coalesce(o.descuento_porcentaje, 0) as descuento_oferta,
       o.nombre_oferta,
       o.cod_oferta,
       -- Division entera, igual que el operador ~/ de Dart: el precio nunca
       -- pasa por punto flotante (RNF-05).
       p.precio_unitario_centavos
         - (p.precio_unitario_centavos * coalesce(o.descuento_porcentaje, 0)) / 100
         as precio_vigente_centavos
  from productos p
  left join tipos_producto tp on tp.tipo_producto = p.tipo_producto
  left join v_ofertas_vigentes o on o.cod_lote_producto = p.cod_lote_producto;

-- Desempeno por estrategia para el UCB1. Antes eran dos consultas con GROUP
-- BY desde el dispositivo; ahora es una sola vista, un solo viaje de red.
-- COUNT(DISTINCT id_proceso_persuasion) por la misma razon de siempre: contar
-- filas crudas inflaria "intentos" frente a como lo miden el KPI 3 y el batch.
create or replace view v_estrategia_desempeno as
select e.cod_estrategia,
       e.nombre_estrategia,
       e.activo,
       coalesce(i.intentos, 0) as intentos,
       coalesce(v.exitos, 0)   as exitos
  from estrategias e
  left join (
    select cod_estrategia, count(distinct id_proceso_persuasion) as intentos
      from interacciones where cod_estrategia is not null group by cod_estrategia
  ) i on i.cod_estrategia = e.cod_estrategia
  left join (
    select cod_estrategia, count(distinct id_proceso_persuasion) as exitos
      from ventas where cod_estrategia is not null group by cod_estrategia
  ) v on v.cod_estrategia = e.cod_estrategia;

-- --------------- VISTAS DE KPI ---------------
--
-- Traduccion de queries.drift. Las funciones de fecha cambian (strftime de
-- SQLite -> to_char/extract de Postgres) porque el timestamp dejo de ser un
-- entero de epoch millis; los numeros que producen son los mismos.

-- C10/G8 - reemplaza el grupo repetitivo ventas(1-99) del diseno original.
create or replace view v_cierres_por_tipo_producto as
select p.tipo_producto,
       tp.nombre_tipo_producto,
       c.cod_cliente,
       c.nombre || ' ' || c.apellido as cliente,
       p.cod_lote_producto,
       p.nombre_producto,
       d.cantidad,
       d.precio_unitario_centavos * d.cantidad as importe_centavos,
       e.cod_estrategia,
       e.nombre_estrategia,
       v.timestamp
  from detalle_venta d
  join ventas v      on v.id = d.venta_id
  join productos p   on p.cod_lote_producto = d.cod_lote_producto
  left join tipos_producto tp on tp.tipo_producto = p.tipo_producto
  join clientes c    on c.cod_cliente = v.cod_cliente
  left join estrategias e on e.cod_estrategia = v.cod_estrategia;

-- KPI 1 - % de cierre de ventas por mes.
create or replace view v_kpi1_cierre_por_mes as
with intentos as (
  select to_char(timestamp, 'YYYY-MM') as mes,
         count(distinct id_proceso_persuasion) as n
    from interacciones group by 1
), cierres as (
  select to_char(timestamp, 'YYYY-MM') as mes,
         count(distinct id_proceso_persuasion) as n
    from ventas group by 1
)
select i.mes,
       coalesce(c.n, 0) as cierres,
       i.n as intentos,
       round(100.0 * coalesce(c.n, 0) / i.n, 2) as porcentaje
  from intentos i left join cierres c on c.mes = i.mes
 order by i.mes;

-- KPI 2 - % de ventas cerradas sin haber mostrado producto alternativo.
-- Esta consulta es la prueba de por que G1 era bloqueante: sin
-- id_proceso_persuasion en ambas tablas no habria por donde enlazar.
create or replace view v_kpi2_ventas_sin_alternativa as
with productos_por_proceso as (
  select id_proceso_persuasion as pid,
         count(distinct cod_lote_producto) as n_prod
    from interacciones
   where cod_lote_producto is not null
   group by id_proceso_persuasion
)
select coalesce(
         round(100.0 * sum(case when p.n_prod = 1 then 1 else 0 end) / nullif(count(*), 0), 2),
         0.0) as porcentaje
  from productos_por_proceso p
 where p.pid in (select distinct id_proceso_persuasion from ventas);

-- KPI 3 - % de efectividad de estrategias por tipo de cliente.
create or replace view v_kpi3_efectividad_por_tipo_cliente as
select cl.tipo_cliente,
       e.cod_estrategia,
       e.nombre_estrategia,
       count(distinct v.id_proceso_persuasion) as ventas_generadas,
       count(distinct i.id_proceso_persuasion) as veces_aplicada,
       round(100.0 * count(distinct v.id_proceso_persuasion)
             / nullif(count(distinct i.id_proceso_persuasion), 0), 2) as efectividad
  from interacciones i
  join clientes cl   on cl.cod_cliente = i.cod_cliente
  join estrategias e on e.cod_estrategia = i.cod_estrategia
  left join ventas v on v.id_proceso_persuasion = i.id_proceso_persuasion
                    and v.cod_estrategia = i.cod_estrategia
 group by cl.tipo_cliente, e.cod_estrategia, e.nombre_estrategia
 order by cl.tipo_cliente, efectividad desc;

-- KPI 4 - distribucion de ventas por dia de la semana (decision D2).
-- 0 = domingo ... 6 = sabado, igual que el strftime('%w') original.
create or replace view v_kpi4_ventas_por_dia_semana as
select extract(dow from timestamp)::integer as dia_semana,
       count(*) as ventas,
       round(100.0 * count(*) / (select count(*) from ventas), 2) as porcentaje
  from ventas
 group by 1 order by 1;

-- --------------- PERMISOS ---------------

-- Las vistas heredan el RLS de sus tablas base solo si son security_invoker;
-- se declaran asi para que ninguna vista se convierta en una puerta trasera
-- de lectura por encima de las politicas. Requiere PostgreSQL 15+ (Supabase
-- corre 15 o superior); en versiones anteriores el bloque no hace nada y las
-- vistas quedan como estaban.
do $do$
declare v text;
begin
  if current_setting('server_version_num')::int >= 150000 then
    foreach v in array array[
      'v_ofertas_vigentes','v_catalogo','v_estrategia_desempeno',
      'v_cierres_por_tipo_producto','v_kpi1_cierre_por_mes',
      'v_kpi2_ventas_sin_alternativa','v_kpi3_efectividad_por_tipo_cliente',
      'v_kpi4_ventas_por_dia_semana'
    ] loop
      execute format('alter view %I set (security_invoker = true)', v);
    end loop;
  end if;
end
$do$;

do $do$
declare rol text;
begin
  foreach rol in array array['anon', 'authenticated'] loop
    if exists (select 1 from pg_roles where rolname = rol) then
      execute format('grant select on
        v_ofertas_vigentes, v_catalogo, v_estrategia_desempeno,
        v_cierres_por_tipo_producto, v_kpi1_cierre_por_mes,
        v_kpi2_ventas_sin_alternativa, v_kpi3_efectividad_por_tipo_cliente,
        v_kpi4_ventas_por_dia_semana to %I', rol);

      execute format('grant execute on function
        fn_registrar_cliente(text, text, text),
        fn_registrar_interaccion(text, text, text, text, integer, text),
        fn_registrar_venta(text, integer),
        fn_cierre_diario() to %I', rol);
    end if;
  end loop;
end
$do$;

-- Los secuenciadores no se exponen: solo los usan las funciones de arriba,
-- que corren como SECURITY DEFINER. Llamarlos sueltos solo serviria para
-- quemar correlativos.
revoke execute on function fn_siguiente_correlativo(text, text) from public;
revoke execute on function fn_siguiente_proceso() from public;

-- --------------- REALTIME ---------------
--
-- Lo que se publica es exactamente lo que el administrador toca y el usuario
-- tiene que ver sin refrescar: catalogo, stock y ofertas. Las bitacoras NO se
-- publican: cada dispositivo escribe cientos de interacciones y ninguna le
-- interesa a los demas.
--
-- La app se suscribe a estas tablas y, ante cualquier cambio, vuelve a leer
-- v_catalogo. No se suscribe a la vista porque Postgres solo replica cambios
-- de tablas fisicas.
do $do$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (select 1 from pg_publication_tables
                   where pubname = 'supabase_realtime' and tablename = 'productos') then
      alter publication supabase_realtime add table productos;
    end if;
    if not exists (select 1 from pg_publication_tables
                   where pubname = 'supabase_realtime' and tablename = 'ofertas') then
      alter publication supabase_realtime add table ofertas;
    end if;
    if not exists (select 1 from pg_publication_tables
                   where pubname = 'supabase_realtime' and tablename = 'tipos_producto') then
      alter publication supabase_realtime add table tipos_producto;
    end if;
  end if;
end
$do$;
