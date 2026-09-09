-- ============================================================================
-- 0003 - Semilla
--
-- Los 4 catalogos base (equivalente de AppDatabase.seedCatalogos) y el
-- catalogo de demostracion (equivalente de catalogo_demo.dart). Mismos
-- codigos, mismos precios y mismos contadores que la version local, para que
-- las reglas de adaptacion se comporten igual desde el primer arranque.
--
-- Idempotente: `on conflict do nothing` en todo. Volver a correrla no duplica
-- ni pisa lo que el administrador haya cambiado despues.
-- ============================================================================

-- --------------- CATALOGOS BASE ---------------

insert into tipos_cliente (cod_tipo_cliente, nombre_tipo_cliente) values
  ('T00001', 'Nuevo'),
  ('T00002', 'Frecuente'),
  ('T00003', 'VIP')
on conflict (cod_tipo_cliente) do nothing;

-- Las 5 clases que produce el clasificador FER-2013 (EmotionDetector.kt).
-- Cierra la FK huerfana G2 (correccion C2).
insert into gestos (cod_gesto, nombre_gesto) values
  ('G0000001', 'triste'),
  ('G0000002', 'feliz'),
  ('G0000003', 'sorpresa'),
  ('G0000004', 'neutral'),
  ('G0000005', 'enojo')
on conflict (cod_gesto) do nothing;

-- El aceptar/rechazar NO va aqui: se infiere de si existe una fila en
-- `ventas` con el mismo id_proceso_persuasion (asi lo mide el KPI 2).
insert into tipos_transaccion (cod_transaccion, tipo_trx) values
  ('TRX0001', 'oferta_adaptativa')
on conflict (cod_transaccion) do nothing;

-- --------------- CATEGORIAS ---------------

insert into tipos_producto (tipo_producto, nombre_tipo_producto) values
  ('T00001', 'Tecnologia'),
  ('T00002', 'Hogar'),
  ('T00003', 'Moda'),
  ('T00004', 'Belleza')
on conflict (tipo_producto) do nothing;

-- --------------- PRODUCTOS ---------------
--
-- `total_veces_mostrado` va sembrado y variado a proposito: las reglas de
-- `neutral` (lo mas mostrado) y `sorpresa` (lo menos mostrado) necesitan
-- historial para ordenar distinto desde el primer arranque.
--
-- `imagen` guarda el nombre del asset que ya vive en assets/products/. Un
-- producto que cree el administrador desde el panel puede dejarlo nulo (la
-- tarjeta cae a un marcador) o apuntar a una URL.

insert into productos (cod_lote_producto, nombre_producto, tipo_producto,
                       precio_unitario_centavos, imagen, total_disponible,
                       total_veces_mostrado) values
  ('P0000001', 'Audifonos Bluetooth',       'T00001',   4990, 'P0000001_audifonos.jpg',   30, 42),
  ('P0000002', 'Smartwatch Deportivo',      'T00001',  12900, 'P0000002_smartwatch.jpg',  15, 18),
  ('P0000003', 'Parlante Portatil',         'T00001',   8500, 'P0000003_parlante.jpg',    22, 27),
  ('P0000004', 'Cargador Inalambrico',      'T00001',   3590, 'P0000004_cargador.jpg',    40,  9),
  ('P0000005', 'Laptop Ultradelgada',       'T00001', 289900, 'P0000005_laptop.jpg',       4,  5),
  ('P0000006', 'Set de Sartenes',           'T00002',  15900, 'P0000006_sartenes.jpg',    12, 31),
  ('P0000007', 'Lampara LED de Escritorio', 'T00002',   4290, 'P0000007_lampara.jpg',     25, 14),
  ('P0000008', 'Organizador Modular',       'T00002',   2590, 'P0000008_organizador.jpg', 50,  3),
  ('P0000009', 'Aspiradora Robot',          'T00002',  79900, 'P0000009_aspiradora.jpg',   6, 21),
  ('P0000010', 'Polo Basico de Algodon',    'T00003',   2990, 'P0000010_polo.jpg',        60, 38),
  ('P0000011', 'Zapatillas Urbanas',        'T00003',  13900, 'P0000011_zapatillas.jpg',  18, 45),
  ('P0000012', 'Mochila Antirrobo',         'T00003',   8900, 'P0000012_mochila.jpg',     20, 12),
  ('P0000013', 'Casaca Impermeable',        'T00003',  19900, 'P0000013_casaca.jpg',      10,  7),
  ('P0000014', 'Kit de Skincare',           'T00004',   6990, 'P0000014_skincare.jpg',    28, 25),
  ('P0000015', 'Secadora de Cabello',       'T00004',   9900, 'P0000015_secadora.jpg',    14, 16),
  ('P0000016', 'Perfume Citrico 100ml',     'T00004',   1890, 'P0000016_perfume.jpg',     35,  1)
on conflict (cod_lote_producto) do nothing;

-- --------------- ESTRATEGIAS ---------------
--
-- Las 4 palancas sobre las que aprende el UCB1. Cada una es un mecanismo de
-- persuasion distinto y modifica la oferta de verdad (ver AdaptationEngine):
-- si fueran solo etiquetas, el bandit estaria optimizando sobre nombres sin
-- efecto y no habria nada que aprender.
insert into estrategias (cod_estrategia, nombre_estrategia) values
  ('E0000001', 'Descuento directo'),
  ('E0000002', 'Envio gratis'),
  ('E0000003', 'Recomendacion premium'),
  ('E0000004', 'Oferta relampago')
on conflict (cod_estrategia) do nothing;

-- --------------- SECUENCIAS ---------------
--
-- Los codigos de arriba se insertaron a mano, asi que las secuencias siguen
-- en 1 y el primer producto que cree el administrador intentaria llamarse
-- P0000001 y chocaria contra la PK. Se adelantan al maximo ya usado: el
-- siguiente producto nace como P0000017.
--
-- `false` como tercer argumento significa "este es el proximo valor a
-- entregar", no "este ya se entrego": por eso se pasa max + 1.

-- Van dentro de un bloque para que `setval` no ensucie la salida de psql con
-- seis tablas de resultados en cada despliegue.
do $do$
begin
  perform setval('seq_producto',
    (select coalesce(max(substring(cod_lote_producto from 2)::int), 0) + 1 from productos), false);

  perform setval('seq_tipo_producto',
    (select coalesce(max(substring(tipo_producto from 2)::int), 0) + 1 from tipos_producto), false);

  perform setval('seq_estrategia',
    (select coalesce(max(substring(cod_estrategia from 2)::int), 0) + 1 from estrategias), false);

  perform setval('seq_cliente',
    (select coalesce(max(substring(cod_cliente from 2)::int), 0) + 1 from clientes), false);

  perform setval('seq_oferta',
    (select coalesce(max(substring(cod_oferta from 3)::int), 0) + 1 from ofertas), false);

  perform setval('seq_proceso_persuasion',
    (select coalesce(max(substring(id_proceso_persuasion from 3)::int), 0) + 1 from interacciones), false);
end
$do$;

-- Los correlativos arrancan donde termine lo ya registrado, por si la base se
-- siembra sobre datos migrados desde los celulares.
insert into correlativos (bitacora, canal, ultimo)
select 'interacciones', canal, max(correlativo) from interacciones group by canal
on conflict (bitacora, canal) do nothing;

insert into correlativos (bitacora, canal, ultimo)
select 'ventas', canal, max(correlativo) from ventas group by canal
on conflict (bitacora, canal) do nothing;
