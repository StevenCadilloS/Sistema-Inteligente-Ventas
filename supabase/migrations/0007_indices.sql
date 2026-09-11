-- ============================================================================
-- 0007 - Indices para las consultas que corren en cada pantalla
--
-- Con 20 productos cualquier plan es rapido y estos indices no cambian nada
-- medible. Estan por lo que pasa despues: `v_catalogo` se recalcula en cada
-- carga de la tienda Y en cada evento de Realtime, y `v_ofertas_vigentes`
-- filtra por fechas en cada una de esas veces. Son las dos consultas que mas
-- corren de todo el sistema.
--
-- Los indices se declaran aqui y no en 0001 a proposito: 0001 ya esta aplicado
-- en proyectos reales, y reescribir una migracion ya ejecutada deja las bases
-- existentes distintas de lo que dice el archivo.
-- ============================================================================

-- --------------- VIGENCIA DE OFERTAS ---------------
--
-- `v_ofertas_vigentes` filtra por activa + rango de fechas. El indice parcial
-- solo cubre las activas, que son las unicas que la vista mira: una oferta
-- desactivada no ocupa sitio en el indice.

create index if not exists ix_ofertas_vigentes
  on ofertas (fecha_inicio, fecha_fin) where activa;

-- --------------- OFERTAS POR PRODUCTO ---------------
--
-- El `exists` de `tiene_ofertas` en v_catalogo entra por id_producto. Ya existe
-- ix_ofertas_productos_secuencia (id_producto, orden), que lo cubre, pero la
-- union con ofertas entra por el otro lado y no tenia indice propio.

create index if not exists ix_ofertas_productos_oferta
  on ofertas_productos (id_oferta);

-- --------------- LIMITE DIARIO ---------------
--
-- fn_compras_del_dia cuenta las ventas del cliente de hoy. ix_venta_cliente_fecha
-- (id_cliente, fecha_hora desc) ya sirve: el planificador lo usa para el
-- filtro por cliente y luego descarta por fecha. No hace falta uno por fecha
-- sola -- con el volumen de una tienda, un cliente no acumula tantas ventas
-- como para que ese descarte pese.

-- --------------- DETALLE DE VENTA ---------------
--
-- fn_historial une venta con detalle_venta por id_venta. Ya existe
-- ix_detalle_venta_venta en 0001.

-- Recuento de lo que queda cubierto, para quien venga despues:
--
--   consulta                     indice que la sostiene
--   ---------------------------  ------------------------------------------
--   catalogo (tienda)            ix_productos_disponibles (0001)
--   ofertas vigentes             ix_ofertas_vigentes (aqui)
--   escalera de un producto      ix_ofertas_productos_secuencia (0001)
--   union ofertas_productos      ix_ofertas_productos_oferta (aqui)
--   limite diario                ix_venta_cliente_fecha (0001)
--   historial                    ix_detalle_venta_venta (0001)
