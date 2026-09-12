-- 0006-B: escaleras de ofertas.
-- Aplicar despues de 0006-A. Idempotente.
--
-- Sin escalera a proposito: Lampara, Organizador y Polo, que se suman a
-- la Laptop HP de 0003. Son el caso de la regla 8: sin oferta el precio
-- no se mueve pase lo que pase con la emocion.

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Smartwatch Deportivo'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Smartwatch Deportivo'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 20%'),
       (select id_producto from productos where nombre='Smartwatch Deportivo'),2,1
 where not exists (select 1 from ofertas_productos where orden=2
   and id_producto=(select id_producto from productos where nombre='Smartwatch Deportivo'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 30%'),
       (select id_producto from productos where nombre='Smartwatch Deportivo'),3,1
 where not exists (select 1 from ofertas_productos where orden=3
   and id_producto=(select id_producto from productos where nombre='Smartwatch Deportivo'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Aspiradora de Mano'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Aspiradora de Mano'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 20%'),
       (select id_producto from productos where nombre='Aspiradora de Mano'),2,1
 where not exists (select 1 from ofertas_productos where orden=2
   and id_producto=(select id_producto from productos where nombre='Aspiradora de Mano'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 30%'),
       (select id_producto from productos where nombre='Aspiradora de Mano'),3,1
 where not exists (select 1 from ofertas_productos where orden=3
   and id_producto=(select id_producto from productos where nombre='Aspiradora de Mano'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Zapatillas Urbanas'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Zapatillas Urbanas'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 20%'),
       (select id_producto from productos where nombre='Zapatillas Urbanas'),2,1
 where not exists (select 1 from ofertas_productos where orden=2
   and id_producto=(select id_producto from productos where nombre='Zapatillas Urbanas'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 30%'),
       (select id_producto from productos where nombre='Zapatillas Urbanas'),3,1
 where not exists (select 1 from ofertas_productos where orden=3
   and id_producto=(select id_producto from productos where nombre='Zapatillas Urbanas'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Parlante Bluetooth Portatil'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Parlante Bluetooth Portatil'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 20%'),
       (select id_producto from productos where nombre='Parlante Bluetooth Portatil'),2,1
 where not exists (select 1 from ofertas_productos where orden=2
   and id_producto=(select id_producto from productos where nombre='Parlante Bluetooth Portatil'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Juego de Sartenes Antiadherentes'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Juego de Sartenes Antiadherentes'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 20%'),
       (select id_producto from productos where nombre='Juego de Sartenes Antiadherentes'),2,1
 where not exists (select 1 from ofertas_productos where orden=2
   and id_producto=(select id_producto from productos where nombre='Juego de Sartenes Antiadherentes'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Mochila Antirrobo'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Mochila Antirrobo'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 20%'),
       (select id_producto from productos where nombre='Mochila Antirrobo'),2,1
 where not exists (select 1 from ofertas_productos where orden=2
   and id_producto=(select id_producto from productos where nombre='Mochila Antirrobo'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Secadora de Cabello Ionica'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Secadora de Cabello Ionica'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 20%'),
       (select id_producto from productos where nombre='Secadora de Cabello Ionica'),2,1
 where not exists (select 1 from ofertas_productos where orden=2
   and id_producto=(select id_producto from productos where nombre='Secadora de Cabello Ionica'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Perfume Floral 50ml'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Perfume Floral 50ml'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 20%'),
       (select id_producto from productos where nombre='Perfume Floral 50ml'),2,1
 where not exists (select 1 from ofertas_productos where orden=2
   and id_producto=(select id_producto from productos where nombre='Perfume Floral 50ml'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Casaca Impermeable'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Casaca Impermeable'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Kit de Cuidado Facial'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Kit de Cuidado Facial'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Cargador Rapido 65W'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Cargador Rapido 65W'));
