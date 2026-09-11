-- ============================================================================
-- Catalogo, secuencia de ofertas y el limite de dos ofertas por dia.
--
-- Es la regla central del sistema: la emocion no calcula el descuento, solo
-- avanza por una escalera que alguien configuro antes. Si la escalera no sale
-- ordenada, o si el limite diario no se respeta, el sistema entero deja de
-- comportarse como lo describe el README.
-- ============================================================================

begin;

-- --------------- LA SECUENCIA SALE EN ORDEN ---------------

do $$
declare
  v_producto bigint;
  v_cliente  bigint;
  v_ordenes  integer[];
begin
  select id_producto into v_producto from productos where nombre = 'Laptop Lenovo IdeaPad';
  v_cliente := fn_registrar_cliente('Escalera', 'Completa');

  select array_agg(orden order by orden) into v_ordenes
    from fn_ofertas_de(v_producto, v_cliente);

  perform test_igual(
    v_ordenes::text, '{1,2,3}',
    'la Laptop Lenovo tiene sus tres escalones en orden'
  );
end
$$;

-- --------------- CADA ESCALON REBAJA MAS QUE EL ANTERIOR ---------------
--
-- No lo garantiza ninguna restriccion de la base (el administrador podria
-- configurar 30% antes que 10%), pero si lo espera el sistema: avanzar de
-- escalon tiene que mejorar la oferta, o el cliente ve como le suben el
-- precio al poner mala cara.

do $$
declare
  v_producto bigint;
  v_cliente  bigint;
  v_precios  integer[];
begin
  select id_producto into v_producto from productos where nombre = 'Laptop Lenovo IdeaPad';
  v_cliente := fn_registrar_cliente('Precios', 'Descendentes');

  select array_agg(precio_final_centavos order by orden) into v_precios
    from fn_ofertas_de(v_producto, v_cliente);

  -- 250000 -> 10% = 225000 -> 20% = 200000 -> 30% = 175000
  perform test_igual(v_precios::text, '{225000,200000,175000}',
    'cada escalon deja un precio menor que el anterior');
end
$$;

-- --------------- UN PRODUCTO SIN OFERTAS NO TIENE ESCALERA ---------------
--
-- README regla 8: si el producto no tiene oferta, se mantiene el precio
-- normal pase lo que pase con la emocion.

do $$
declare
  v_hp      bigint;
  v_cliente bigint;
begin
  select id_producto into v_hp from productos where nombre = 'Laptop HP Pavilion';
  v_cliente := fn_registrar_cliente('Sin', 'Escalera');

  perform test_igual(
    (select count(*)::text from fn_ofertas_de(v_hp, v_cliente)),
    '0',
    'la Laptop HP no tiene ofertas configuradas'
  );
  perform test_igual(
    (select tiene_ofertas::text from v_catalogo where id_producto = v_hp),
    'false',
    'el catalogo avisa que no tiene ofertas, para no encender la camara'
  );
end
$$;

-- --------------- VIGENCIA ---------------

-- Se usa "Descuento 20%" y se deja como estaba al terminar: los bloques
-- siguientes cuentan con la escalera completa, y una prueba que ensucia el
-- estado de las demas falla de formas que no tienen que ver con lo que mide.
do $$
declare
  v_producto bigint;
  v_cliente  bigint;
  v_oferta   bigint;
  v_antes    integer;
begin
  select id_producto into v_producto from productos where nombre = 'Samsung Galaxy A55';
  v_cliente := fn_registrar_cliente('Vigencia', 'Prueba');

  select count(*) into v_antes from fn_ofertas_de(v_producto, v_cliente);
  perform test_cierto(v_antes > 0, 'el Samsung empieza con ofertas vigentes');

  select id_oferta into v_oferta from ofertas where nombre = 'Descuento 20%';

  -- Una oferta que ya vencio no cuenta, sin que nadie la desactive a mano.
  update ofertas set fecha_fin = now() - interval '1 day' where id_oferta = v_oferta;
  perform test_igual(
    (select count(*)::text from fn_ofertas_de(v_producto, v_cliente)),
    (v_antes - 1)::text,
    'una oferta vencida deja de aparecer sola'
  );

  -- Y una desactivada tampoco.
  update ofertas set fecha_fin = null, activa = false where id_oferta = v_oferta;
  perform test_igual(
    (select count(*)::text from fn_ofertas_de(v_producto, v_cliente)),
    (v_antes - 1)::text,
    'una oferta desactivada tampoco aparece'
  );

  -- Se restaura para no condicionar lo que viene despues.
  update ofertas set activa = true, fecha_fin = timestamptz '2026-12-31 23:59:59-05'
   where id_oferta = v_oferta;
  perform test_igual(
    (select count(*)::text from fn_ofertas_de(v_producto, v_cliente)),
    v_antes::text,
    'al reactivarla vuelve a la escalera'
  );
end
$$;

-- --------------- LIMITE DE DOS OFERTAS POR DIA ---------------
--
-- README regla 7. Se cuentan las COMPRAS del dia, no las que llevaron oferta:
-- a la tercera compra ya no hay oferta aunque las dos primeras fueran a
-- precio normal.

do $$
declare
  v_cliente  bigint;
  v_lenovo   bigint;
  v_hp       bigint;
  v_oferta   bigint;
begin
  v_cliente := fn_registrar_cliente('Limite', 'Diario');
  select id_producto into v_lenovo from productos where nombre = 'Laptop Lenovo IdeaPad';
  select id_producto into v_hp     from productos where nombre = 'Laptop HP Pavilion';
  select id_oferta   into v_oferta from ofertas   where nombre = 'Descuento 10%';

  perform test_cierto(fn_puede_usar_oferta(v_cliente),
    'un cliente sin compras hoy puede usar oferta');

  -- Primera compra: a precio normal, pero cuenta para el limite.
  perform fn_registrar_venta(v_cliente, v_hp, 1, null);
  perform test_cierto(fn_puede_usar_oferta(v_cliente),
    'tras una compra todavia puede usar oferta');

  -- Segunda compra: con oferta.
  perform fn_registrar_venta(v_cliente, v_lenovo, 1, v_oferta);
  perform test_igual(fn_compras_del_dia(v_cliente)::text, '2',
    'lleva dos compras hoy');
  perform test_cierto(not fn_puede_usar_oferta(v_cliente),
    'a la tercera compra ya no puede usar oferta');

  -- La escalera se le vacia: no hay a donde avanzar.
  perform test_igual(
    (select count(*)::text from fn_ofertas_de(v_lenovo, v_cliente)),
    '0',
    'sin derecho a oferta, la escalera viene vacia'
  );

  -- Y el servidor lo rechaza aunque la app lo intente igual.
  perform test_falla(
    format('select fn_registrar_venta(%s, %s, 1, %s)', v_cliente, v_lenovo, v_oferta),
    'limite_diario',
    'el servidor rechaza la tercera oferta del dia'
  );

  -- A precio normal si puede seguir comprando: el limite es de ofertas, no
  -- de compras.
  perform fn_registrar_venta(v_cliente, v_hp, 1, null);
  perform test_igual(fn_compras_del_dia(v_cliente)::text, '3',
    'puede seguir comprando a precio normal');
end
$$;

-- --------------- LAS COMPRAS DE AYER NO CUENTAN ---------------

do $$
declare
  v_cliente bigint;
  v_hp      bigint;
  v_venta   bigint;
begin
  v_cliente := fn_registrar_cliente('Compras', 'Ayer');
  select id_producto into v_hp from productos where nombre = 'Laptop HP Pavilion';

  v_venta := fn_registrar_venta(v_cliente, v_hp, 1, null);
  v_venta := fn_registrar_venta(v_cliente, v_hp, 1, null);
  perform test_cierto(not fn_puede_usar_oferta(v_cliente), 'hoy ya gasto sus dos');

  -- Se mueven ambas compras a ayer.
  update venta set fecha_hora = fecha_hora - interval '1 day'
   where id_cliente = v_cliente;

  perform test_igual(fn_compras_del_dia(v_cliente)::text, '0',
    'las compras de ayer no cuentan para el limite de hoy');
  perform test_cierto(fn_puede_usar_oferta(v_cliente),
    'el limite se renueva cada dia');
end
$$;

-- --------------- COHERENCIA DE LAS OFERTAS ---------------

-- Una oferta no puede ser de las dos clases a la vez...
select test_falla(
  $q$ insert into ofertas (id_admin, nombre, id_tipo, porcentaje_descuento,
                           precio_oferta_centavos, fecha_inicio)
      values ((select min(id_admin) from administradores), 'Incoherente',
              (select min(id_tipo) from tipos_oferta), 10, 5000, now()) $q$,
  null,
  'una oferta no puede tener porcentaje y precio de combo a la vez'
);

-- ...ni de ninguna.
select test_falla(
  $q$ insert into ofertas (id_admin, nombre, id_tipo, porcentaje_descuento,
                           precio_oferta_centavos, fecha_inicio)
      values ((select min(id_admin) from administradores), 'Vacia',
              (select min(id_tipo) from tipos_oferta), null, null, now()) $q$,
  null,
  'una oferta tiene que rebajar algo'
);

-- El tope del 90% evita regalar el producto.
select test_falla(
  $q$ insert into ofertas (id_admin, nombre, id_tipo, porcentaje_descuento, fecha_inicio)
      values ((select min(id_admin) from administradores), 'Regalo',
              (select min(id_tipo) from tipos_oferta), 100, now()) $q$,
  null,
  'no se puede publicar un descuento del 100%'
);

-- Dos ofertas no pueden ocupar el mismo escalon del mismo producto.
select test_falla(
  $q$ insert into ofertas_productos (id_oferta, id_producto, orden, cantidad)
      values ((select id_oferta from ofertas where nombre = 'Descuento 30%'),
              (select id_producto from productos where nombre = 'Samsung Galaxy A55'),
              1, 1) $q$,
  null,
  'el orden 1 del Samsung ya esta ocupado'
);

select test_ok('02_catalogo_y_ofertas');

rollback;
