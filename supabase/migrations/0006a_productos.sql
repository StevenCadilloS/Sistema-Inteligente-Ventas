-- 0006-A: categorias, marcas y los 14 productos nuevos.
-- Idempotente: aplicarla dos veces no duplica nada.

insert into categorias (nombre) values ('Hogar') on conflict (nombre) do nothing;
insert into categorias (nombre) values ('Ropa') on conflict (nombre) do nothing;
insert into categorias (nombre) values ('Belleza') on conflict (nombre) do nothing;

insert into marcas (nombre) values ('CasaBella') on conflict (nombre) do nothing;
insert into marcas (nombre) values ('UrbanFit') on conflict (nombre) do nothing;
insert into marcas (nombre) values ('NaturaSkin') on conflict (nombre) do nothing;
insert into marcas (nombre) values ('TecnoPlus') on conflict (nombre) do nothing;

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Accesorios'),
       (select id_marca from marcas where nombre='TecnoPlus'),
       'Smartwatch Deportivo','Reloj inteligente con medidor de ritmo cardiaco',29900,18
 where not exists (select 1 from productos where nombre='Smartwatch Deportivo');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Accesorios'),
       (select id_marca from marcas where nombre='Sony'),
       'Parlante Bluetooth Portatil','Parlante resistente al agua, 12 horas de bateria',18000,22
 where not exists (select 1 from productos where nombre='Parlante Bluetooth Portatil');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Accesorios'),
       (select id_marca from marcas where nombre='TecnoPlus'),
       'Cargador Rapido 65W','Carga rapida para laptop y celular, USB-C',8900,40
 where not exists (select 1 from productos where nombre='Cargador Rapido 65W');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Hogar'),
       (select id_marca from marcas where nombre='CasaBella'),
       'Juego de Sartenes Antiadherentes','Tres piezas con recubrimiento ceramico',15900,14
 where not exists (select 1 from productos where nombre='Juego de Sartenes Antiadherentes');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Hogar'),
       (select id_marca from marcas where nombre='CasaBella'),
       'Lampara de Escritorio LED','Luz regulable en tres tonos, brazo articulado',6900,30
 where not exists (select 1 from productos where nombre='Lampara de Escritorio LED');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Hogar'),
       (select id_marca from marcas where nombre='CasaBella'),
       'Organizador Multiuso','Cajonera de tela plegable para closet',4500,35
 where not exists (select 1 from productos where nombre='Organizador Multiuso');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Hogar'),
       (select id_marca from marcas where nombre='CasaBella'),
       'Aspiradora de Mano','Inalambrica, ideal para auto y espacios pequenos',21900,11
 where not exists (select 1 from productos where nombre='Aspiradora de Mano');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Ropa'),
       (select id_marca from marcas where nombre='UrbanFit'),
       'Polo Basico de Algodon','Algodon peinado, corte regular',3900,50
 where not exists (select 1 from productos where nombre='Polo Basico de Algodon');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Ropa'),
       (select id_marca from marcas where nombre='UrbanFit'),
       'Zapatillas Urbanas','Suela de goma antideslizante, uso diario',16900,20
 where not exists (select 1 from productos where nombre='Zapatillas Urbanas');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Ropa'),
       (select id_marca from marcas where nombre='UrbanFit'),
       'Mochila Antirrobo','Compartimento para laptop de 15 pulgadas',12900,25
 where not exists (select 1 from productos where nombre='Mochila Antirrobo');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Ropa'),
       (select id_marca from marcas where nombre='UrbanFit'),
       'Casaca Impermeable','Cortavientos ligero con capucha',13900,16
 where not exists (select 1 from productos where nombre='Casaca Impermeable');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Belleza'),
       (select id_marca from marcas where nombre='NaturaSkin'),
       'Kit de Cuidado Facial','Limpiador, tonico e hidratante para piel mixta',11900,28
 where not exists (select 1 from productos where nombre='Kit de Cuidado Facial');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Belleza'),
       (select id_marca from marcas where nombre='NaturaSkin'),
       'Secadora de Cabello Ionica','Dos velocidades, tecnologia ionica antifrizz',14900,15
 where not exists (select 1 from productos where nombre='Secadora de Cabello Ionica');

insert into productos (id_categoria, id_marca, nombre, descripcion, precio_centavos, stock)
select (select id_categoria from categorias where nombre='Belleza'),
       (select id_marca from marcas where nombre='NaturaSkin'),
       'Perfume Floral 50ml','Fragancia floral de larga duracion',17900,19
 where not exists (select 1 from productos where nombre='Perfume Floral 50ml');

