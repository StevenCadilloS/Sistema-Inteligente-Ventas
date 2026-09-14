-- ============================================================================
-- 0012 - El historial por venta, con pantalla de detalle
--
-- fn_historial devolvia una fila por LINEA de detalle unida a la cabecera, de
-- modo que una compra con dos productos aparecia como dos tarjetas, cada una
-- repitiendo el total de la venta completa. Confundia al cliente: dos tarjetas
-- con el mismo total y la misma fecha parecen dos cobros.
--
-- El cambio es de forma, no de fondo:
--
--   1. fn_historial ahora devuelve una fila por VENTA: id, fecha, cuantas
--      lineas y unidades trae, y su total. Es lo que pinta la lista de
--      "Mis compras"; tocar una tarjeta abre el detalle.
--
--   2. fn_venta_detalle devuelve las lineas de UNA venta. El cliente sale del
--      token igual que en fn_historial: si la venta no es suya, la funcion se
--      comporta como si no existiera. La app no puede pedir el detalle de
--      otra persona ni por error, y tampoco por fuerza bruta probando ids.
-- ============================================================================

-- --------------- 1. EL HISTORIAL, UNA FILA POR VENTA ---------------
--
-- La firma no cambia (sigue siendo fn_historial(integer)) pero el tipo de
-- retorno si: las columnas nuevas no caben en la definicion vieja, y Postgres
-- no deja redefinirla con create or replace. Se suelta y se crea de nuevo;
-- drop function no toca datos, solo la definicion.

drop function if exists fn_historial(integer);

create function fn_historial(
  p_limite integer default 50
)
returns table (
  id_venta        bigint,
  fecha_hora      timestamptz,
  lineas          integer,
  unidades        integer,
  total_centavos  integer
)
language sql
stable
security definer
set search_path = public
as $$
  select v.id_venta, v.fecha_hora,
         count(d.id_detalle_venta)::integer,
         coalesce(sum(d.cantidad), 0)::integer,
         v.total_centavos
    from venta v
    left join detalle_venta d on d.id_venta = v.id_venta
   where v.id_cliente = fn_cliente_actual()
   group by v.id_venta
   order by v.fecha_hora desc
   limit greatest(p_limite, 1)
$$;

-- --------------- 2. EL DETALLE DE UNA VENTA ---------------
--
-- Nueva funcion: no hay version previa que soltar, pero drop if exists hace
-- que re-ejecutar el archivo completo no falle.

drop function if exists fn_venta_detalle(bigint);

create function fn_venta_detalle(
  p_id_venta bigint
)
returns table (
  fecha_hora            timestamptz,
  producto              varchar,
  cantidad              integer,
  precio_total_centavos integer,
  nombre_oferta         varchar
)
language sql
stable
security definer
set search_path = public
as $$
  select v.fecha_hora, p.nombre, d.cantidad, d.precio_total_centavos, o.nombre
    from detalle_venta d
    join venta v    on v.id_venta = d.id_venta
    join productos p on p.id_producto = d.id_producto
    left join ofertas o on o.id_oferta = d.id_oferta
   where d.id_venta = p_id_venta
     and v.id_cliente = fn_cliente_actual()
   order by d.id_detalle_venta
$$;

-- --------------- 3. PERMISOS ---------------
--
-- La receta de 0011: las funciones de compra son para clientes con sesion;
-- anon no ejecuta nada.

do $do$
declare f text;
begin
  foreach f in array array[
    'fn_historial(integer)',
    'fn_venta_detalle(bigint)'
  ]
  loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end
$do$;
