-- 0006-C: saca los combos de las escaleras individuales.
--
-- 0003 metio "Combo Gamer" y "Combo Audio" como escalones del Mouse, el
-- Teclado y los Audifonos. Un combo fija el precio de VARIOS productos
-- juntos, asi que sobre uno solo encarece: los Audifonos valen S/250 y el
-- Combo Audio S/350. La negociacion se volvia una amenaza -- el cliente
-- rechaza y el precio sube. fn_registrar_venta ya lo impedia, pero el
-- cliente veia la oferta absurda antes de que fallara.
--
-- Las ofertas de combo se conservan en "ofertas"; solo dejan de colgar de un
-- producto suelto. Aplicar despues de 0006-B.

delete from ofertas_productos op
 using ofertas o, productos p
 where o.id_oferta = op.id_oferta
   and p.id_producto = op.id_producto
   and o.precio_oferta_centavos is not null
   and o.precio_oferta_centavos >= p.precio_centavos;

-- --------------- REPONER LO QUE EL DELETE DEJO SIN ESCALERA ---------------
--
-- Los Audifonos y el Teclado tenian el combo como UNICO escalon, asi que el
-- delete de arriba los dejo sin nada que ofrecer: pasaban a comportarse como
-- los de la regla 8 por accidente, no por diseno. Van DESPUES del delete a
-- proposito; antes, el delete se llevaria tambien esto.
--
-- El Mouse no lo necesita: 0003 le dio un "Descuento 10%" ademas del combo.

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Audifonos Sony WH-CH520'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Audifonos Sony WH-CH520'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 20%'),
       (select id_producto from productos where nombre='Audifonos Sony WH-CH520'),2,1
 where not exists (select 1 from ofertas_productos where orden=2
   and id_producto=(select id_producto from productos where nombre='Audifonos Sony WH-CH520'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 10%'),
       (select id_producto from productos where nombre='Teclado Logitech K380'),1,1
 where not exists (select 1 from ofertas_productos where orden=1
   and id_producto=(select id_producto from productos where nombre='Teclado Logitech K380'));

insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
select (select id_oferta from ofertas where nombre='Descuento 20%'),
       (select id_producto from productos where nombre='Teclado Logitech K380'),2,1
 where not exists (select 1 from ofertas_productos where orden=2
   and id_producto=(select id_producto from productos where nombre='Teclado Logitech K380'));

