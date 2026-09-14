-- ============================================================================
-- 0014 - Catalogo de expansion: 30 productos con marcas reales, de tecnologia,
--        hogar, ropa y belleza, con escaleras de ofertas mixtas.
--
-- Categorias y marcas nuevas se agregan con on conflict do nothing; los
-- productos se resuelven por nombre, nunca por id (las secuencias no se
-- fuerzan, ver 0003). Cada producto idempotente: correr dos veces no duplica.
--
-- Reparto de ofertas decidido con el administrador:
--   - Escalera A: 10% -> 20% -> 30%
--   - Escalera B: 5%  -> 15% -> 20%
--   - Escalera C: 5%  -> 10%
--   - Sin oferta: precio fijo, regla 8 (como la HP Pavilion)
--
-- Las ofertas 5% y 15% no existen en la base (la semilla solo trajo 10, 20
-- y 30), asi que se crean aqui, a nombre de steven@tienda.com.
--
-- imagen queda en NULL a proposito: la app cae al icono de la categoria
-- hasta que se suban las fotos al bucket productos (ver 0008).
--
-- REVERSION: al final del archivo, comentada. Si algo sale mal tras aplicar
-- el catalogo, copia ese bloque en el SQL Editor y ejecutalo: borra solo lo
-- que este archivo creo, sin tocar ventas ni clientes.
-- ============================================================================

-- --------------- 1. CATEGORIAS ---------------

insert into categorias (nombre) values
  ('Tecnologia'), ('Hogar'), ('Ropa'), ('Belleza')
on conflict (nombre) do nothing;

-- --------------- 2. MARCAS ---------------

insert into marcas (nombre) values
  ('HP'), ('Samsung'), ('LG'), ('Redragon'), ('SanDisk'), ('Xiaomi'),
  ('JBL'), ('Oster'), ('Dolce Gusto'), ('Philips'), ('Peter Pan'),
  ('Coton'), ('Home Style'), ('Brita'), ('The North Face'), ('Levis'),
  ('Adidas'), ('Tommy Hilfiger'), ('Nike'), ('Caterpillar'),
  ('Maybelline'), ('Nivea'), ('Real Techniques'), ('Head & Shoulders'),
  ('Neutrogena')
on conflict (nombre) do nothing;

-- --------------- 3. OFERTAS NUEVAS ---------------
--
-- La semilla trajo Descuento 10/20/30. Faltan 5 y 15 para las escaleras B y
-- C. Idempotente por nombre.

insert into ofertas (id_admin, nombre, id_tipo, porcentaje_descuento,
                     fecha_inicio, fecha_fin)
select a.id_admin, v.nombre, t.id_tipo, v.pct,
       timestamptz '2026-09-01 00:00:00-05', timestamptz '2026-12-31 23:59:59-05'
  from (values
    ('steven@tienda.com', 'Descuento 5%',  5),
    ('steven@tienda.com', 'Descuento 15%', 15)
  ) as v(correo, nombre, pct)
  join administradores a on a.correo = v.correo
  join tipos_oferta    t on t.nombre = 'Descuento'
 where not exists (select 1 from ofertas o where o.nombre = v.nombre);

-- --------------- 4. PRODUCTOS ---------------
--
-- 30 productos. La escalera de cada uno va anotada en el comentario; los sin
-- oferta no reciben filas en ofertas_productos.

-- ---- TECNOLOGIA (8) ----
-- Escalera A (10/20/30): Laptop HP 15-fd000, Tablet Samsung Galaxy A9+,
--   Monitor LG 24MK430H, Teclado Redragon Kumara K552
-- Escalera C (5/10): MicroSD SanDisk 128GB, Power Bank Xiaomi 20000mAh
-- Sin oferta: Audifonos JBL Tune 510BT, Webcam Xiaomi Mi Web Camera

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select c.id_categoria, m.id_marca, v.nombre, v.descripcion, v.precio, v.stock
  from (values
    ('Tecnologia', 'HP',       'Laptop HP 15-fd000',
     'Laptop de 15.6 pulgadas, Intel Core i5, 8GB RAM, 512GB SSD', 189900, 12),
    ('Tecnologia', 'Samsung',  'Tablet Samsung Galaxy A9+',
     'Tablet de 10.5 pulgadas, 64GB, con altavoces cuadrados', 89900, 15),
    ('Tecnologia', 'LG',       'Monitor LG 24MK430H',
     'Monitor Full HD de 24 pulgadas con HDMI y VGA', 49900, 10),
    ('Tecnologia', 'Redragon', 'Teclado Redragon Kumara K552',
     'Teclado mecanico gamer con iluminacion RGB', 24900, 18),
    ('Tecnologia', 'SanDisk',  'MicroSD SanDisk 128GB',
     'Tarjeta de memoria clase 10 con adaptador SD', 6900, 45),
    ('Tecnologia', 'Xiaomi',   'Power Bank Xiaomi 20000mAh',
     'Bateria externa con carga rapida, dos puertos USB', 12900, 25),
    ('Tecnologia', 'JBL',      'Audifonos JBL Tune 510BT',
     'Audifonos inalambricos con Pure Bass, 40 horas de bateria', 15900, 20),
    ('Tecnologia', 'Xiaomi',   'Webcam Xiaomi Mi Web Camera',
     'Camara 1080p con microfono doble para videollamadas', 11900, 22)
  ) as v(categoria, marca, nombre, descripcion, precio, stock)
  join categorias c on c.nombre = v.categoria
  join marcas     m on m.nombre = v.marca
 where not exists (select 1 from productos p where p.nombre = v.nombre);

-- ---- HOGAR (8) ----
-- Escalera A (10/20/30): Olla Presion Oster 6L, Cafetera Dolce Gusto,
--   Plancha Philips GC1740
-- Escalera B (5/15/20): Ventilador Peter Pan TF-1691, Licuadora Oster 600W
-- Sin oferta: Set de Toallas Coton, Cortina Blackout Home Style,
--   Filtro Brita para Grifo

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select c.id_categoria, m.id_marca, v.nombre, v.descripcion, v.precio, v.stock
  from (values
    ('Hogar', 'Oster',       'Olla Presion Oster 6L',
     'Olla a presion de 6 litros, acero inoxidable', 25900, 9),
    ('Hogar', 'Dolce Gusto', 'Cafetera Dolce Gusto Piccolo',
     'Cafetera de capsulas para espresso y bebidas', 32900, 8),
    ('Hogar', 'Philips',     'Plancha Philips GC1740',
     'Plancha a vapor con suela antiadherente', 12900, 17),
    ('Hogar', 'Peter Pan',   'Ventilador Peter Pan TF-1691',
     'Ventilador de pie, tres velocidades, altura regulable', 15900, 13),
    ('Hogar', 'Oster',       'Licuadora Oster 600W',
     'Vaso de vidrio de 1.5 litros, cinco velocidades', 16900, 12),
    ('Hogar', 'Coton',       'Set de Toallas Coton',
     'Cuatro toallas de algodon 500 gramos', 8900, 30),
    ('Hogar', 'Home Style',  'Cortina Blackout Home Style',
     'Oscurece la habitacion, incluye argollas', 9900, 21),
    ('Hogar', 'Brita',       'Filtro Brita para Grifo',
     'Reduce cloro y sedimentos del agua del grifo', 5900, 28)
  ) as v(categoria, marca, nombre, descripcion, precio, stock)
  join categorias c on c.nombre = v.categoria
  join marcas     m on m.nombre = v.marca
 where not exists (select 1 from productos p where p.nombre = v.nombre);

-- ---- ROPA (7) ----
-- Escalera B (5/15/20): Casaca The North Face Polar, Jean Levis 511,
--   Buzo Adidas con Capucha
-- Escalera C (5/10): Camisa Tommy Cuadros, Gorro Adidas de Lana
-- Sin oferta: Medias Nike (3 pares), Cinturon Caterpillar de Cuero

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select c.id_categoria, m.id_marca, v.nombre, v.descripcion, v.precio, v.stock
  from (values
    ('Ropa', 'The North Face', 'Casaca The North Face Polar',
     'Casaca polar termica para invierno', 25900, 14),
    ('Ropa', 'Levis',          'Jean Levis 511 Slim',
     'Denim elastizado, corte slim fit', 22900, 16),
    ('Ropa', 'Adidas',         'Buzo Adidas con Capucha',
     'Buzo de algodon frizado, bolsillo canguro', 19900, 18),
    ('Ropa', 'Tommy Hilfiger', 'Camisa Tommy Cuadros',
     'Camisa de vestir de manga larga', 18900, 12),
    ('Ropa', 'Adidas',         'Gorro Adidas de Lana',
     'Gorro tejido con forro polar', 4900, 30),
    ('Ropa', 'Nike',           'Medias Nike (3 pares)',
     'Medias deportivas de algodon con refuerzo', 5900, 35),
    ('Ropa', 'Caterpillar',    'Cinturon Caterpillar de Cuero',
     'Cuero genuino, hebilla clasica', 7900, 15)
  ) as v(categoria, marca, nombre, descripcion, precio, stock)
  join categorias c on c.nombre = v.categoria
  join marcas     m on m.nombre = v.marca
 where not exists (select 1 from productos p where p.nombre = v.nombre);

-- ---- BELLEZA (7) ----
-- Escalera A (10/20/30): Paleta Maybelline The Blushed,
--   Crema Nivea Facial Hidratante
-- Escalera B (5/15/20): Kit Brochas Real Techniques, Aceite Corporal Nivea
-- Escalera C (5/10): Shampoo Head & Shoulders 400ml,
--   Protector Solar Neutrogena FPS 50
-- Sin oferta: Espejo con Luz Xiaomi

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select c.id_categoria, m.id_marca, v.nombre, v.descripcion, v.precio, v.stock
  from (values
    ('Belleza', 'Maybelline',       'Paleta Maybelline The Blushed',
     'Paleta de sombras y rubor de larga duracion', 9900, 16),
    ('Belleza', 'Nivea',            'Crema Nivea Facial Hidratante',
     'Hidratacion para piel seca y mixta, 100ml', 3900, 40),
    ('Belleza', 'Real Techniques',  'Kit Brochas Real Techniques',
     'Doce brochas sinteticas con estuche', 12900, 19),
    ('Belleza', 'Nivea',            'Aceite Corporal Nivea',
     'Con vitamina E, absorcion rapida, 200ml', 4900, 32),
    ('Belleza', 'Head & Shoulders', 'Shampoo Head & Shoulders 400ml',
     'Anticaspa con ketoconazol', 2900, 50),
    ('Belleza', 'Neutrogena',       'Protector Solar Neutrogena FPS 50',
     'Textura ligera, libre de grasas', 7900, 25),
    ('Belleza', 'Xiaomi',           'Espejo con Luz Xiaomi',
     'LED regulable con aumento 3x, recargable', 14900, 10)
  ) as v(categoria, marca, nombre, descripcion, precio, stock)
  join categorias c on c.nombre = v.categoria
  join marcas     m on m.nombre = v.marca
 where not exists (select 1 from productos p where p.nombre = v.nombre);

-- --------------- 5. ESCALERAS DE OFERTAS ---------------
--
-- Un insert por escalon, con where not exists: re-ejecutar no duplica ni
-- reordena. La columna cantidad es 1 en todo el catalogo actual (0003).

-- ---- Escalera A: 10 -> 20 -> 30 ----

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select o.id_oferta, p.id_producto, 1, 1
  from ofertas o, productos p
 where o.nombre = 'Descuento 10%' and p.nombre in (
   'Laptop HP 15-fd000', 'Tablet Samsung Galaxy A9+', 'Monitor LG 24MK430H',
   'Teclado Redragon Kumara K552', 'Olla Presion Oster 6L',
   'Cafetera Dolce Gusto Piccolo', 'Plancha Philips GC1740',
   'Paleta Maybelline The Blushed', 'Crema Nivea Facial Hidratante')
   and not exists (select 1 from ofertas_productos op
                    where op.id_producto = p.id_producto and op.orden = 1);

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select o.id_oferta, p.id_producto, 2, 1
  from ofertas o, productos p
 where o.nombre = 'Descuento 20%' and p.nombre in (
   'Laptop HP 15-fd000', 'Tablet Samsung Galaxy A9+', 'Monitor LG 24MK430H',
   'Teclado Redragon Kumara K552', 'Olla Presion Oster 6L',
   'Cafetera Dolce Gusto Piccolo', 'Plancha Philips GC1740',
   'Paleta Maybelline The Blushed', 'Crema Nivea Facial Hidratante')
   and not exists (select 1 from ofertas_productos op
                    where op.id_producto = p.id_producto and op.orden = 2);

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select o.id_oferta, p.id_producto, 3, 1
  from ofertas o, productos p
 where o.nombre = 'Descuento 30%' and p.nombre in (
   'Laptop HP 15-fd000', 'Tablet Samsung Galaxy A9+', 'Monitor LG 24MK430H',
   'Teclado Redragon Kumara K552', 'Olla Presion Oster 6L',
   'Cafetera Dolce Gusto Piccolo', 'Plancha Philips GC1740',
   'Paleta Maybelline The Blushed', 'Crema Nivea Facial Hidratante')
   and not exists (select 1 from ofertas_productos op
                    where op.id_producto = p.id_producto and op.orden = 3);

-- ---- Escalera B: 5 -> 15 -> 20 ----

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select o.id_oferta, p.id_producto, 1, 1
  from ofertas o, productos p
 where o.nombre = 'Descuento 5%' and p.nombre in (
   'Ventilador Peter Pan TF-1691', 'Licuadora Oster 600W',
   'Casaca The North Face Polar', 'Jean Levis 511 Slim',
   'Buzo Adidas con Capucha', 'Kit Brochas Real Techniques',
   'Aceite Corporal Nivea')
   and not exists (select 1 from ofertas_productos op
                    where op.id_producto = p.id_producto and op.orden = 1);

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select o.id_oferta, p.id_producto, 2, 1
  from ofertas o, productos p
 where o.nombre = 'Descuento 15%' and p.nombre in (
   'Ventilador Peter Pan TF-1691', 'Licuadora Oster 600W',
   'Casaca The North Face Polar', 'Jean Levis 511 Slim',
   'Buzo Adidas con Capucha', 'Kit Brochas Real Techniques',
   'Aceite Corporal Nivea')
   and not exists (select 1 from ofertas_productos op
                    where op.id_producto = p.id_producto and op.orden = 2);

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select o.id_oferta, p.id_producto, 3, 1
  from ofertas o, productos p
 where o.nombre = 'Descuento 20%' and p.nombre in (
   'Ventilador Peter Pan TF-1691', 'Licuadora Oster 600W',
   'Casaca The North Face Polar', 'Jean Levis 511 Slim',
   'Buzo Adidas con Capucha', 'Kit Brochas Real Techniques',
   'Aceite Corporal Nivea')
   and not exists (select 1 from ofertas_productos op
                    where op.id_producto = p.id_producto and op.orden = 3);

-- ---- Escalera C: 5 -> 10 ----

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select o.id_oferta, p.id_producto, 1, 1
  from ofertas o, productos p
 where o.nombre = 'Descuento 5%' and p.nombre in (
   'MicroSD SanDisk 128GB', 'Power Bank Xiaomi 20000mAh',
   'Camisa Tommy Cuadros', 'Gorro Adidas de Lana',
   'Shampoo Head & Shoulders 400ml', 'Protector Solar Neutrogena FPS 50')
   and not exists (select 1 from ofertas_productos op
                    where op.id_producto = p.id_producto and op.orden = 1);

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select o.id_oferta, p.id_producto, 2, 1
  from ofertas o, productos p
 where o.nombre = 'Descuento 10%' and p.nombre in (
   'MicroSD SanDisk 128GB', 'Power Bank Xiaomi 20000mAh',
   'Camisa Tommy Cuadros', 'Gorro Adidas de Lana',
   'Shampoo Head & Shoulders 400ml', 'Protector Solar Neutrogena FPS 50')
   and not exists (select 1 from ofertas_productos op
                    where op.id_producto = p.id_producto and op.orden = 2);

-- --------------- 6. VERIFICACION ---------------

do $$
declare
  v_total      integer;
  v_con_oferta integer;
begin
  select count(*) into v_total from productos
   where nombre in (
     'Laptop HP 15-fd000', 'Tablet Samsung Galaxy A9+', 'Monitor LG 24MK430H',
     'Teclado Redragon Kumara K552', 'MicroSD SanDisk 128GB',
     'Power Bank Xiaomi 20000mAh', 'Audifonos JBL Tune 510BT',
     'Webcam Xiaomi Mi Web Camera',
     'Olla Presion Oster 6L', 'Cafetera Dolce Gusto Piccolo',
     'Plancha Philips GC1740', 'Ventilador Peter Pan TF-1691',
     'Licuadora Oster 600W', 'Set de Toallas Coton',
     'Cortina Blackout Home Style', 'Filtro Brita para Grifo',
     'Casaca The North Face Polar', 'Jean Levis 511 Slim',
     'Buzo Adidas con Capucha', 'Camisa Tommy Cuadros',
     'Gorro Adidas de Lana', 'Medias Nike (3 pares)',
     'Cinturon Caterpillar de Cuero',
     'Paleta Maybelline The Blushed', 'Crema Nivea Facial Hidratante',
     'Kit Brochas Real Techniques', 'Aceite Corporal Nivea',
     'Shampoo Head & Shoulders 400ml', 'Protector Solar Neutrogena FPS 50',
     'Espejo con Luz Xiaomi');

  if v_total <> 30 then
    raise exception 'Faltan productos: se esperaban 30 y hay %', v_total;
  end if;

  select count(distinct op.id_producto) into v_con_oferta
    from ofertas_productos op
    join productos p on p.id_producto = op.id_producto
   where p.nombre in (
     'Laptop HP 15-fd000', 'Tablet Samsung Galaxy A9+', 'Monitor LG 24MK430H',
     'Teclado Redragon Kumara K552', 'MicroSD SanDisk 128GB',
     'Power Bank Xiaomi 20000mAh',
     'Olla Presion Oster 6L', 'Cafetera Dolce Gusto Piccolo',
     'Plancha Philips GC1740', 'Ventilador Peter Pan TF-1691',
     'Licuadora Oster 600W',
     'Casaca The North Face Polar', 'Jean Levis 511 Slim',
     'Buzo Adidas con Capucha', 'Camisa Tommy Cuadros',
     'Gorro Adidas de Lana',
     'Paleta Maybelline The Blushed', 'Crema Nivea Facial Hidratante',
     'Kit Brochas Real Techniques', 'Aceite Corporal Nivea',
     'Shampoo Head & Shoulders 400ml', 'Protector Solar Neutrogena FPS 50');

  if v_con_oferta <> 22 then
    raise exception 'Faltan escaleras: se esperaban 22 productos con oferta y hay %',
      v_con_oferta;
  end if;
end
$$;

-- ============================================================================
-- REVERSION
--
-- Ejecutar SOLO si hay que deshacer el catalogo. Borra en orden inverso al
-- que se creo, y solo lo que este archivo inserto: las ventas existentes
-- (que referencian productos por id) se quedan con sus datos, y las ofertas
-- 10/20/30 se conservan porque las usan los productos de la semilla.
--
-- begin;
--
-- -- Escaleras de los 22 productos con oferta.
-- delete from ofertas_productos op
--  using productos p
--  where p.id_producto = op.id_producto
--    and p.nombre in (
--      'Laptop HP 15-fd000', 'Tablet Samsung Galaxy A9+', 'Monitor LG 24MK430H',
--      'Teclado Redragon Kumara K552', 'MicroSD SanDisk 128GB',
--      'Power Bank Xiaomi 20000mAh',
--      'Olla Presion Oster 6L', 'Cafetera Dolce Gusto Piccolo',
--      'Plancha Philips GC1740', 'Ventilador Peter Pan TF-1691',
--      'Licuadora Oster 600W',
--      'Casaca The North Face Polar', 'Jean Levis 511 Slim',
--      'Buzo Adidas con Capucha', 'Camisa Tommy Cuadros',
--      'Gorro Adidas de Lana',
--      'Paleta Maybelline The Blushed', 'Crema Nivea Facial Hidratante',
--      'Kit Brochas Real Techniques', 'Aceite Corporal Nivea',
--      'Shampoo Head & Shoulders 400ml', 'Protector Solar Neutrogena FPS 50');
--
-- -- Los 30 productos. Falla si alguno ya tiene ventas: en ese caso hay que
-- -- decidir a mano (desactivar con update productos set activo = false es lo
-- -- recomendable, para no romper el historial).
-- delete from productos
--  where nombre in (
--    'Laptop HP 15-fd000', 'Tablet Samsung Galaxy A9+', 'Monitor LG 24MK430H',
--    'Teclado Redragon Kumara K552', 'MicroSD SanDisk 128GB',
--    'Power Bank Xiaomi 20000mAh', 'Audifonos JBL Tune 510BT',
--    'Webcam Xiaomi Mi Web Camera',
--    'Olla Presion Oster 6L', 'Cafetera Dolce Gusto Piccolo',
--    'Plancha Philips GC1740', 'Ventilador Peter Pan TF-1691',
--    'Licuadora Oster 600W', 'Set de Toallas Coton',
--    'Cortina Blackout Home Style', 'Filtro Brita para Grifo',
--    'Casaca The North Face Polar', 'Jean Levis 511 Slim',
--    'Buzo Adidas con Capucha', 'Camisa Tommy Cuadros',
--    'Gorro Adidas de Lana', 'Medias Nike (3 pares)',
--    'Cinturon Caterpillar de Cuero',
--    'Paleta Maybelline The Blushed', 'Crema Nivea Facial Hidratante',
--    'Kit Brochas Real Techniques', 'Aceite Corporal Nivea',
--    'Shampoo Head & Shoulders 400ml', 'Protector Solar Neutrogena FPS 50',
--    'Espejo con Luz Xiaomi');
--
-- -- Las ofertas 5% y 15% solo si ningun producto las usa ya (incluidos los
-- -- de la semilla: si le diste 5% a un producto viejo, no se borra).
-- delete from ofertas o
--  where o.nombre in ('Descuento 5%', 'Descuento 15%')
--    and not exists (select 1 from ofertas_productos op
--                     where op.id_oferta = o.id_oferta);
--
-- -- Marcas y categorias: solo si quedaron sin productos. Ojo: marcas como
-- -- Oster o Xiaomi las comparten productos viejos y nuevos; el delete solo
-- -- las lleva si se quedaron sin NINGUN producto.
-- delete from marcas m
--  where m.nombre in (
--    'LG', 'Redragon', 'SanDisk', 'JBL', 'Dolce Gusto', 'Peter Pan',
--    'Coton', 'Home Style', 'Brita', 'The North Face', 'Levis',
--    'Tommy Hilfiger', 'Caterpillar', 'Maybelline', 'Real Techniques',
--    'Head & Shoulders', 'Neutrogena')
--    and not exists (select 1 from productos p where p.id_marca = m.id_marca);
-- delete from categorias c
--  where c.nombre in ('Tecnologia')
--    and not exists (select 1 from productos p where p.id_categoria = c.id_categoria);
--
-- commit;
-- ============================================================================
