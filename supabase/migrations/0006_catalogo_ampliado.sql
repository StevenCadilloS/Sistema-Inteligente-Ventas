-- ============================================================================
-- 0006 - Catalogo ampliado a multi-rubro
--
-- El catalogo de demostracion eran 6 productos de tecnologia, y el repositorio
-- trae 16 imagenes de las que solo 5 encajaban en esas categorias: las otras
-- 11 son de hogar, ropa y belleza. Antes que descartarlas o inventar
-- categorias forzadas para meterlas donde no van, la tienda pasa a ser
-- multi-rubro.
--
-- Eso no es solo cosmetico para la demostracion: con 7 categorias y 16
-- productos, la regla de cambiar de rubro cuando el cliente rechaza tiene
-- material de verdad sobre el que operar. Con 6 productos de dos categorias,
-- cualquier recorrido agotaba el catalogo en dos pasos.
--
-- Las marcas son inventadas a proposito. Es un proyecto academico en un
-- repositorio publico: poner marcas reales sobre productos que no son suyos
-- mezcla la demostracion con nombres de terceros sin ninguna necesidad.
--
-- Las imagenes NO se asignan aqui. Viven en el bucket `productos` (0005) y se
-- suben desde el panel; sembrar nombres de archivo en una migracion fue
-- exactamente el error que 0005 tuvo que limpiar. La correspondencia entre
-- cada producto y su foto esta en el comentario de cada fila, para quien las
-- suba.
-- ============================================================================

-- --------------- CATEGORIAS NUEVAS ---------------

insert into categorias (nombre) values
  ('Hogar'), ('Ropa'), ('Belleza')
on conflict (nombre) do nothing;

-- --------------- MARCAS NUEVAS ---------------

insert into marcas (nombre) values
  ('CasaBella'),    -- hogar
  ('UrbanFit'),     -- ropa
  ('NaturaSkin'),   -- belleza
  ('TecnoPlus')     -- accesorios de tecnologia sin marca propia
on conflict (nombre) do nothing;

-- --------------- PRODUCTOS ---------------
--
-- Precios en centavos: 18000 = S/180.00. El comentario de cada fila dice que
-- imagen de assets/products/ le corresponde al subirla al bucket.

insert into productos (id_categoria, id_marca, nombre, descripcion,
                       precio_centavos, stock)
select c.id_categoria, m.id_marca, v.nombre, v.descripcion,
       v.precio_centavos, v.stock
  from (values
    -- ── Tecnologia (completan las categorias que ya existian) ──────────────
    ('Accesorios', 'TecnoPlus',  'Smartwatch Deportivo',
     'Reloj inteligente con medidor de ritmo cardiaco',   29900, 18),
     -- P0000002_smartwatch.jpg
    ('Accesorios', 'Sony',       'Parlante Bluetooth Portatil',
     'Parlante resistente al agua, 12 horas de bateria',  18000, 22),
     -- P0000003_parlante.jpg
    ('Accesorios', 'TecnoPlus',  'Cargador Rapido 65W',
     'Carga rapida para laptop y celular, USB-C',          8900, 40),
     -- P0000004_cargador.jpg

    -- ── Hogar ──────────────────────────────────────────────────────────────
    ('Hogar',      'CasaBella',  'Juego de Sartenes Antiadherentes',
     'Tres piezas con recubrimiento ceramico',            15900, 14),
     -- P0000006_sartenes.jpg
    ('Hogar',      'CasaBella',  'Lampara de Escritorio LED',
     'Luz regulable en tres tonos, brazo articulado',      6900, 30),
     -- P0000007_lampara.jpg
    ('Hogar',      'CasaBella',  'Organizador Multiuso',
     'Cajonera de tela plegable para closet',              4500, 35),
     -- P0000008_organizador.jpg
    ('Hogar',      'CasaBella',  'Aspiradora de Mano',
     'Inalambrica, ideal para auto y espacios pequenos',   21900, 11),
     -- P0000009_aspiradora.jpg

    -- ── Ropa ───────────────────────────────────────────────────────────────
    ('Ropa',       'UrbanFit',   'Polo Basico de Algodon',
     'Algodon peinado, corte regular',                     3900, 50),
     -- P0000010_polo.jpg
    ('Ropa',       'UrbanFit',   'Zapatillas Urbanas',
     'Suela de goma antideslizante, uso diario',          16900, 20),
     -- P0000011_zapatillas.jpg
    ('Ropa',       'UrbanFit',   'Mochila Antirrobo',
     'Compartimento para laptop de 15", cierre oculto',    12900, 25),
     -- P0000012_mochila.jpg
    ('Ropa',       'UrbanFit',   'Casaca Impermeable',
     'Cortavientos ligero con capucha',                    13900, 16),
     -- P0000013_casaca.jpg

    -- ── Belleza ────────────────────────────────────────────────────────────
    ('Belleza',    'NaturaSkin', 'Kit de Cuidado Facial',
     'Limpiador, tonico e hidratante para piel mixta',     11900, 28),
     -- P0000014_skincare.jpg
    ('Belleza',    'NaturaSkin', 'Secadora de Cabello Ionica',
     'Dos velocidades, tecnologia ionica antifrizz',       14900, 15),
     -- P0000015_secadora.jpg
    ('Belleza',    'NaturaSkin', 'Perfume Floral 50ml',
     'Fragancia floral de larga duracion',                 17900, 19)
     -- P0000016_perfume.jpg
  ) as v(categoria, marca, nombre, descripcion, precio_centavos, stock)
  join categorias c on c.nombre = v.categoria
  join marcas     m on m.nombre = v.marca
 where not exists (select 1 from productos p where p.nombre = v.nombre);

-- --------------- ESCALERAS DE OFERTAS ---------------
--
-- No todos los productos negocian: el README es explicito en que un producto
-- sin oferta se queda en su precio normal pase lo que pase con la emocion
-- (regla 8), y si todo el catalogo tuviera escalera ese caso no se veria
-- nunca en la demostracion.
--
-- Llevan escalera los productos de precio medio-alto, que es donde un
-- descuento tiene sentido comercial: rebajar un polo de S/39 no mueve a nadie.

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select o.id_oferta, p.id_producto, v.orden, 1
  from (values
    -- Escalera completa (10 -> 20 -> 30): los mas caros del catalogo
    ('Smartwatch Deportivo',             'Descuento 10%', 1),
    ('Smartwatch Deportivo',             'Descuento 20%', 2),
    ('Smartwatch Deportivo',             'Descuento 30%', 3),
    ('Aspiradora de Mano',               'Descuento 10%', 1),
    ('Aspiradora de Mano',               'Descuento 20%', 2),
    ('Aspiradora de Mano',               'Descuento 30%', 3),
    ('Zapatillas Urbanas',               'Descuento 10%', 1),
    ('Zapatillas Urbanas',               'Descuento 20%', 2),
    ('Zapatillas Urbanas',               'Descuento 30%', 3),

    -- Dos escalones: precio medio
    ('Parlante Bluetooth Portatil',      'Descuento 10%', 1),
    ('Parlante Bluetooth Portatil',      'Descuento 20%', 2),
    ('Juego de Sartenes Antiadherentes', 'Descuento 10%', 1),
    ('Juego de Sartenes Antiadherentes', 'Descuento 20%', 2),
    ('Mochila Antirrobo',                'Descuento 10%', 1),
    ('Mochila Antirrobo',                'Descuento 20%', 2),
    ('Secadora de Cabello Ionica',       'Descuento 10%', 1),
    ('Secadora de Cabello Ionica',       'Descuento 20%', 2),
    ('Perfume Floral 50ml',              'Descuento 10%', 1),
    ('Perfume Floral 50ml',              'Descuento 20%', 2),

    -- Un solo escalon
    ('Casaca Impermeable',               'Descuento 10%', 1),
    ('Kit de Cuidado Facial',            'Descuento 10%', 1),
    ('Cargador Rapido 65W',              'Descuento 10%', 1)

    -- Sin escalera a proposito: Lampara de Escritorio, Organizador Multiuso y
    -- Polo Basico, que se suman a la Laptop HP de 0003. Son el caso de la
    -- regla 8 —sin oferta el precio no se mueve— y conviene tenerlo a mano en
    -- la demostracion. Cuatro sobre veinte productos: suficiente para que
    -- aparezca sin que la tienda parezca que no negocia.
  ) as v(producto, oferta, orden)
  join productos p on p.nombre = v.producto
  join ofertas   o on o.nombre = v.oferta
 where not exists (
   select 1 from ofertas_productos op
    where op.id_producto = p.id_producto and op.orden = v.orden
 );

-- --------------- LOS COMBOS SALEN DE LAS ESCALERAS INDIVIDUALES ---------------
--
-- La semilla de 0003 metio "Combo Gamer" y "Combo Audio" como escalones del
-- Mouse, el Teclado y los Audifonos. Un combo fija el precio de VARIOS
-- productos juntos, asi que sobre uno solo encarece:
--
--   Audifonos solos      S/250  ->  Combo Audio  S/350
--   Teclado solo         S/180  ->  Combo Gamer  S/200
--
-- Eso convierte la negociacion en una amenaza: el cliente rechaza y el precio
-- SUBE. fn_registrar_venta lo rechaza con `oferta_incoherente` y la venta
-- nunca se cierra, pero para entonces el cliente ya vio la oferta absurda.
--
-- Las ofertas de combo se conservan en `ofertas` —son datos validos y el
-- esquema las soporta— pero dejan de colgar de la escalera de un producto
-- suelto. Cuando la app sepa vender varios productos a la vez, volveran por
-- la puerta correcta.

delete from ofertas_productos op
 using ofertas o, productos p
 where o.id_oferta = op.id_oferta
   and p.id_producto = op.id_producto
   and o.precio_oferta_centavos is not null
   and o.precio_oferta_centavos >= p.precio_centavos;

-- Los huecos de orden que deja el delete no importan: fn_ofertas_de ordena
-- por `orden`, no exige que sea consecutivo.

-- --------------- REPONER LO QUE EL DELETE DEJO SIN ESCALERA ---------------
--
-- Sacar los combos tuvo un efecto que hay que reparar: los Audifonos Sony y el
-- Teclado Logitech tenian el combo como UNICO escalon, asi que se quedaron sin
-- nada que ofrecer. Eran productos que la demostracion presentaba como
-- negociables, y sin esto pasan a comportarse como los de la regla 8 por
-- accidente, no por diseno.
--
-- El Mouse conserva su "Descuento 10%", que 0003 le habia dado ademas del
-- combo, asi que no necesita reparacion.

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select o.id_oferta, p.id_producto, v.orden, 1
  from (values
    ('Audifonos Sony WH-CH520', 'Descuento 10%', 1),
    ('Audifonos Sony WH-CH520', 'Descuento 20%', 2),
    ('Teclado Logitech K380',   'Descuento 10%', 1),
    ('Teclado Logitech K380',   'Descuento 20%', 2)
  ) as v(producto, oferta, orden)
  join productos p on p.nombre = v.producto
  join ofertas   o on o.nombre = v.oferta
 where not exists (
   select 1 from ofertas_productos op
    where op.id_producto = p.id_producto and op.orden = v.orden
 );
