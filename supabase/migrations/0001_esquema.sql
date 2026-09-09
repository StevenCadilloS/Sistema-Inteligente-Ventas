-- ============================================================================
-- 0001 - Esquema del Sistema Cierre de Ventas sobre PostgreSQL
--
-- Traduccion del esquema local (lib/data/database/tables.dart, drift/SQLite)
-- a la base compartida. Origen conceptual: docs/MODELO_ANDROID_ROOM.md seccion 3
-- con las correcciones C1-C11 y decisiones D1-D5 de docs/ESQUEMA_CORREGIDO.md.
--
-- Tres diferencias deliberadas frente a la version local, todas obligadas por
-- pasar de "una base por celular" a "una base para todos":
--
--   1. Los codigos de negocio (C0000002, P0000005, PP00000001) los asigna el
--      servidor con secuencias, no el cliente leyendo el maximo actual. En
--      local eso era seguro porque habia un solo escritor; con N celulares,
--      dos lecturas simultaneas del maximo generan el mismo codigo y chocan
--      contra la primary key. Ademas deja que el administrador cree productos
--      desde el panel sin inventarse el codigo.
--
--   2. Las fechas son timestamptz y no epoch millis (INTEGER). El dato ahora
--      lo lee una persona en el panel de administracion, no solo el motor de
--      KPIs; un entero de 13 digitos no es auditable a simple vista. La
--      aritmetica monetaria NO cambia: sigue en centavos enteros (RNF-05).
--
--   3. Toda escritura de bitacora pasa por funciones SECURITY DEFINER
--      (0002_funciones.sql). La app solo tiene permiso de lectura: sin esto,
--      la clave anonima que viaja dentro del APK permitiria a cualquiera
--      reescribir precios o stock.
-- ============================================================================

-- --------------- ROLES ---------------
--
-- Supabase trae estos roles de fabrica, pero un PostgreSQL pelado no: sin
-- ellos, las politicas de mas abajo fallan con `role "anon" does not exist`.
-- Se crean aqui para que la misma migracion corra igual en el proyecto de la
-- nube, en el docker/podman de desarrollo y en el Postgres de CI.
--
-- `nologin`: son roles de permisos, no cuentas. Quien los "usa" es PostgREST,
-- que asume uno u otro segun el token que traiga la peticion.
do $do$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin noinherit bypassrls;
  end if;
end
$do$;

grant usage on schema public to anon, authenticated, service_role;

-- --------------- SECUENCIAS DE CODIGOS DE NEGOCIO ---------------

create sequence if not exists seq_cliente;
create sequence if not exists seq_producto;
create sequence if not exists seq_tipo_producto;
create sequence if not exists seq_estrategia;
create sequence if not exists seq_oferta;
create sequence if not exists seq_proceso_persuasion;

-- --------------- CATALOGOS ---------------

create table if not exists tipos_cliente (
  cod_tipo_cliente    text primary key,
  nombre_tipo_cliente text not null,
  activo              boolean not null default true
);

create table if not exists tipos_producto (
  tipo_producto        text primary key
                       default 'T' || lpad(nextval('seq_tipo_producto')::text, 5, '0'),
  nombre_tipo_producto text not null,
  activo               boolean not null default true
);

-- C2 - cierra la FK huerfana G2. Mapeo emociones FER-2013 -> gestos del
-- negocio. `nombre_gesto` es unique porque el modulo Kotlin identifica la
-- emocion por nombre ("triste"), no por codigo: el codigo es un detalle de
-- persistencia que el clasificador no conoce.
create table if not exists gestos (
  cod_gesto    text primary key,
  nombre_gesto text not null unique,
  descripcion  text,
  activo       boolean not null default true
);

-- C4 - cierra la FK huerfana G4.
create table if not exists tipos_transaccion (
  cod_transaccion text primary key,
  tipo_trx        text not null,
  cod_protocolo   text,
  activo          boolean not null default true
);

-- --------------- MAESTRAS ---------------

create table if not exists clientes (
  cod_cliente          text primary key
                       default 'C' || lpad(nextval('seq_cliente')::text, 7, '0'),
  nombre               text not null,
  apellido             text not null,
  tipo_cliente         text references tipos_cliente(cod_tipo_cliente),  -- C3: nullable
  fecha_ingreso        timestamptz not null default now(),
  -- derivados, mantenidos por el cierre diario (0002_funciones.sql)
  cant_lecturas        integer not null default 0,   -- D1
  total_compras        integer not null default 0,
  monto_total_centavos bigint  not null default 0,
  ultima_visita        timestamptz,
  activo               boolean not null default true
);

create index if not exists idx_clientes_tipo on clientes (tipo_cliente);

create table if not exists productos (
  cod_lote_producto        text primary key
                           default 'P' || lpad(nextval('seq_producto')::text, 7, '0'),
  nombre_producto          text not null,
  tipo_producto            text references tipos_producto(tipo_producto),  -- C6
  precio_unitario_centavos integer not null check (precio_unitario_centavos >= 0),  -- C5
  imagen                   text,
  fecha_creacion_stock     timestamptz not null default now(),
  -- El CHECK es la ultima linea de defensa del stock: aunque alguien escriba
  -- un UPDATE a mano en el panel, la base no acepta inventario negativo.
  total_disponible         integer not null default 0 check (total_disponible >= 0),
  -- derivados
  total_vendidos           integer not null default 0,
  cierres_venta            integer not null default 0,  -- D3
  total_veces_mostrado     integer not null default 0,
  activo                   boolean not null default true
);

create index if not exists idx_productos_tipo on productos (tipo_producto);

create table if not exists estrategias (
  cod_estrategia       text primary key
                       default 'E' || lpad(nextval('seq_estrategia')::text, 7, '0'),
  nombre_estrategia    text not null,
  -- NO lleva tipo_cliente (G3)
  total_veces_aplicada integer not null default 0,  -- derivado, solo el batch
  ventas_generadas     integer not null default 0,  -- derivado, solo el batch
  activo               boolean not null default true
);

-- --------------- OFERTAS (nuevo) ---------------
--
-- Tabla que no existia en la version local. Hasta ahora el unico descuento
-- posible era el que calcula AdaptationEngine en memoria a partir de la
-- emocion: nacia y moria dentro de una decision, y nadie podia crearlo desde
-- fuera. Para que el administrador pueda "publicar una oferta" hace falta que
-- el descuento sea un dato persistido, con vigencia y visible para todos.
--
-- Convive con el descuento adaptativo sin pisarlo: la regla de composicion
-- (el mayor de los dos) esta en v_catalogo y documentada alli.
create table if not exists ofertas (
  cod_oferta           text primary key
                       default 'OF' || lpad(nextval('seq_oferta')::text, 6, '0'),
  cod_lote_producto    text not null references productos(cod_lote_producto) on delete cascade,
  nombre_oferta        text not null,
  -- Tope de 90: un descuento del 100% regalaria el producto y ademas dejaria
  -- detalle_venta con importe 0, ensuciando todos los KPIs de monto.
  descuento_porcentaje integer not null check (descuento_porcentaje between 1 and 90),
  vigente_desde        timestamptz not null default now(),
  vigente_hasta        timestamptz,
  activo               boolean not null default true,
  check (vigente_hasta is null or vigente_hasta > vigente_desde)
);

create index if not exists idx_ofertas_producto on ofertas (cod_lote_producto);
create index if not exists idx_ofertas_vigencia on ofertas (activo, vigente_desde, vigente_hasta);

-- --------------- CORRELATIVOS ---------------
--
-- `correlativo` es una secuencia por canal y por bitacora. En la version
-- local se calculaba leyendo el maximo actual dentro de una transaccion, que
-- alcanzaba con un solo dispositivo. Con varios, dos transacciones simultaneas
-- leen el mismo maximo y la segunda revienta contra UNIQUE(canal, correlativo)
-- - exactamente el problema que anticipaba docs/MODELO_ANDROID_ROOM.md.
--
-- Se resuelve con una fila por (bitacora, canal) y un UPDATE ... RETURNING,
-- que bloquea esa fila: el segundo escritor espera y recibe el numero
-- siguiente. No se usa una secuencia nativa de Postgres porque las secuencias
-- dejan huecos al hacer rollback, y un correlativo de bitacora con huecos no
-- es defendible en una auditoria.
create table if not exists correlativos (
  bitacora text not null,
  canal    text not null,
  ultimo   integer not null default 0,
  primary key (bitacora, canal)
);

-- --------------- BITACORAS ---------------

create table if not exists interacciones (
  id                     bigint generated always as identity primary key,
  canal                  text not null,               -- 'W' web, 'A' app
  correlativo            integer not null,
  id_proceso_persuasion  text not null,               -- C1: une intento <-> cierre
  cod_cliente            text not null references clientes(cod_cliente),
  cod_estrategia         text references estrategias(cod_estrategia),      -- C11: nullable
  cod_gesto              text references gestos(cod_gesto),
  cod_lote_producto      text references productos(cod_lote_producto),     -- C7
  tipo_transaccion       text not null references tipos_transaccion(cod_transaccion),
  timestamp              timestamptz not null default now(),
  nivel_de_interes       integer not null check (nivel_de_interes between 0 and 100),
  unique (canal, correlativo)
);

create index if not exists idx_interacciones_proceso    on interacciones (id_proceso_persuasion);
create index if not exists idx_interacciones_cliente    on interacciones (cod_cliente);
create index if not exists idx_interacciones_estrategia on interacciones (cod_estrategia);
create index if not exists idx_interacciones_timestamp  on interacciones (timestamp);

create table if not exists ventas (
  id                    bigint generated always as identity primary key,
  canal                 text not null,   -- C7
  correlativo           integer not null,
  id_proceso_persuasion text not null,   -- C1 (cierra G1)
  cod_cliente           text not null references clientes(cod_cliente),
  cod_estrategia        text references estrategias(cod_estrategia),
  tipo_transaccion      text not null references tipos_transaccion(cod_transaccion),
  timestamp             timestamptz not null default now(),
  unique (canal, correlativo)
);

create index if not exists idx_ventas_proceso    on ventas (id_proceso_persuasion);
create index if not exists idx_ventas_cliente    on ventas (cod_cliente);
create index if not exists idx_ventas_estrategia on ventas (cod_estrategia);
create index if not exists idx_ventas_timestamp  on ventas (timestamp);

create table if not exists detalle_venta (
  id                       bigint generated always as identity primary key,
  venta_id                 bigint not null references ventas(id) on delete cascade,
  cod_lote_producto        text not null references productos(cod_lote_producto),
  cantidad                 integer not null check (cantidad > 0),
  -- snapshot: el precio realmente pactado, con el descuento ya aplicado
  precio_unitario_centavos integer not null check (precio_unitario_centavos >= 0),
  unique (venta_id, cod_lote_producto)
);

create index if not exists idx_detalle_producto on detalle_venta (cod_lote_producto);

-- --------------- ADMINISTRADORES ---------------
--
-- Quien puede tocar catalogo, stock y ofertas. Se identifica por el usuario
-- autenticado de Supabase (auth.users), no por el cliente de la tienda: son
-- dos poblaciones distintas - el cliente se registra con nombre y apellido y
-- no tiene credenciales.
--
-- La FK contra auth.users se agrega solo si ese esquema existe, para que la
-- migracion tambien corra en un Postgres pelado (el docker-compose de
-- desarrollo y el de CI), donde no hay GoTrue.
create table if not exists administradores (
  id      uuid primary key,
  correo  text,
  activo  boolean not null default true,
  creado  timestamptz not null default now()
);

do $do$
begin
  if exists (select 1 from information_schema.tables
             where table_schema = 'auth' and table_name = 'users')
     and not exists (select 1 from information_schema.table_constraints
                     where constraint_name = 'administradores_id_fkey') then
    alter table administradores
      add constraint administradores_id_fkey
      foreign key (id) references auth.users(id) on delete cascade;
  end if;
end
$do$;

-- `stable` y no `volatile`: se evalua una vez por consulta en vez de una vez
-- por fila, que dentro de una politica RLS es la diferencia entre usar el
-- indice y escanear la tabla entera.
create or replace function es_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  select exists (
    select 1 from administradores
    where id = nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
      and activo
  );
$fn$;

-- --------------- RLS ---------------
--
-- La clave anonima viaja dentro del APK: cualquiera que descomprima el
-- paquete la tiene. Por eso el rol anonimo solo puede LEER, y unicamente lo
-- que la tienda necesita mostrar. Todo lo que escribe (registrarse, registrar
-- una interaccion, cerrar una venta) pasa por las funciones SECURITY DEFINER
-- de 0002, que validan antes de tocar la tabla.
--
-- El administrador escribe de dos formas, ambas por encima de estas
-- politicas: desde el panel de Supabase (rol service_role, exento de RLS) o
-- autenticado, via las politicas es_admin() de abajo.

alter table tipos_cliente     enable row level security;
alter table tipos_producto    enable row level security;
alter table gestos            enable row level security;
alter table tipos_transaccion enable row level security;
alter table clientes          enable row level security;
alter table productos         enable row level security;
alter table estrategias       enable row level security;
alter table ofertas           enable row level security;
alter table interacciones     enable row level security;
alter table ventas            enable row level security;
alter table detalle_venta     enable row level security;
alter table correlativos      enable row level security;
alter table administradores   enable row level security;

-- Lectura publica: el catalogo y sus catalogos de apoyo, mas las bitacoras
-- que alimentan la pantalla de historial. Es lo que la tienda pinta, y lo
-- que debe llegar sola cuando el administrador lo cambia.
do $do$
declare t text;
begin
  foreach t in array array[
    'tipos_cliente','tipos_producto','gestos','tipos_transaccion',
    'clientes','productos','estrategias','ofertas',
    'interacciones','ventas','detalle_venta'
  ] loop
    execute format('drop policy if exists lectura_publica on %I', t);
    execute format(
      'create policy lectura_publica on %I for select to anon, authenticated using (true)', t);
  end loop;
end
$do$;

-- Escritura del administrador sobre lo que administra. `correlativos` queda
-- fuera a proposito: nadie lo edita a mano, solo lo mueve
-- fn_siguiente_correlativo, que corre como SECURITY DEFINER.
do $do$
declare t text;
begin
  foreach t in array array[
    'tipos_cliente','tipos_producto','gestos','tipos_transaccion',
    'productos','estrategias','ofertas','clientes'
  ] loop
    execute format('drop policy if exists escritura_admin on %I', t);
    execute format(
      'create policy escritura_admin on %I for all to authenticated using (es_admin()) with check (es_admin())', t);
  end loop;
end
$do$;

-- Un administrador puede verse a si mismo; darse de alta es cosa del panel.
drop policy if exists lectura_propia on administradores;
create policy lectura_propia on administradores
  for select to authenticated
  using (id = nullif(current_setting('request.jwt.claim.sub', true), '')::uuid);

-- --------------- PRIVILEGIOS ---------------
--
-- RLS y GRANT son dos capas distintas y hacen falta las dos: la politica dice
-- QUE FILAS puede ver un rol, el grant dice si puede ejecutar SELECT sobre la
-- tabla siquiera. Supabase concede estos grants por defecto a lo que crea el
-- rol `postgres`; se escriben explicitos para que la migracion no dependa de
-- esa cortesia y corra igual en un Postgres pelado.
--
-- Se conceden uno por uno y no con "all tables in schema public": ese comodin
-- alcanzaria tambien a cualquier tabla ajena que viva en el mismo esquema.
grant select on
  tipos_cliente, tipos_producto, gestos, tipos_transaccion,
  clientes, productos, estrategias, ofertas,
  interacciones, ventas, detalle_venta
  to anon, authenticated;

-- Ni INSERT ni UPDATE ni DELETE para la app: sus tres escrituras pasan por las
-- funciones SECURITY DEFINER de 0002, que corren con los permisos del dueno.
grant all on
  tipos_cliente, tipos_producto, gestos, tipos_transaccion,
  clientes, productos, estrategias, ofertas,
  interacciones, ventas, detalle_venta, correlativos, administradores
  to service_role;
