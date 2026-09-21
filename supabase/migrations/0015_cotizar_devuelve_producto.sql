-- ============================================================================
-- 0015 - fn_cotizar_carrito devuelve id_producto y cantidad
--
-- La version de 0011 declara seis columnas de salida, pero el loop solo
-- asigna cuatro: precio_unitario_centavos, stock_suficiente, oferta_aplicada
-- e id_oferta. id_producto y cantidad se quedaban en NULL en cada fila,
-- porque el cuerpo trabaja con las variables locales v_pid y v_cant y hace
-- `return next` sin copiarlas a la salida.
--
-- Lo que se veia en la app: el aviso "Los precios ya no son los mismos"
-- saltaba en TODAS las compras, con un texto que se contradice solo
-- ("cambio de S/80.10 a S/80.10"). CotizacionLinea.respeta() compara
-- id_producto contra la linea del carrito, y el NULL llega a Dart como 0
-- (ver _entero en lib/data/modelos/modelos.dart), asi que la comparacion
-- nunca podia dar cierto. Como el precio y el stock SI cuadraban, el motivo
-- caia en la ultima rama del ternario y se imprimia el mismo numero dos
-- veces.
--
-- El cuerpo es copia literal del de 0011 con las dos asignaciones que
-- faltaban. No cambia ninguna regla de negocio: la cotizacion ya calculaba
-- bien el precio, solo no decia de que linea hablaba.
--
-- create or replace conserva los permisos que 0011 dejo puestos, asi que no
-- hay que volver a otorgar nada.
-- ============================================================================

create or replace function fn_cotizar_carrito(
  p_lineas jsonb
)
returns table (
  id_producto              bigint,
  cantidad                 integer,
  id_oferta                bigint,
  precio_unitario_centavos integer,
  oferta_aplicada          boolean,
  stock_suficiente         boolean
)
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  v_linea  jsonb;
  v_pid    bigint;
  v_cant   integer;
  v_ofer   bigint;
  v_precio_oferta integer;
begin
  if fn_cliente_actual() is null then
    raise exception 'Hay que iniciar sesion para cotizar'
      using hint = 'sin_sesion';
  end if;

  if p_lineas is null or jsonb_array_length(p_lineas) = 0 then
    raise exception 'El carrito esta vacio'
      using hint = 'carrito_vacio';
  end if;

  for v_linea in select * from jsonb_array_elements(p_lineas) loop
    v_pid  := (v_linea ->> 'id_producto')::bigint;
    v_cant := coalesce((v_linea ->> 'cantidad')::integer, 1);
    v_ofer := nullif(v_linea ->> 'id_oferta', '')::bigint;

    -- Un carrito con cantidad 0 o negativa es un error de la app, no un caso
    -- de negocio: se corta antes de que la cotizacion diga disparates.
    if v_cant < 1 then
      raise exception 'La cantidad debe ser al menos 1'
        using hint = 'cantidad_invalida';
    end if;

    -- El precio parte del de lista...
    select p.precio_centavos, (p.stock >= v_cant)
      into precio_unitario_centavos, stock_suficiente
      from productos p
     where p.id_producto = v_pid;

    if not found then
      raise exception 'No existe el producto %', v_pid
        using hint = 'producto_inexistente';
    end if;

    -- ...y baja si la oferta que se nego sigue jugando para quien llama.
    -- El precio se lee a una variable aparte: el SELECT INTO con "no rows"
    -- pone NULL en su destino, y si fuera directo machacaria el precio de
    -- lista que acabamos de asignar.
    oferta_aplicada := false;
    id_oferta       := v_ofer;
    if v_ofer is not null and fn_puede_usar_oferta() then
      select s.precio_final_centavos into v_precio_oferta
        from v_secuencia_ofertas s
       where s.id_producto = v_pid
         and s.id_oferta   = v_ofer;
      if found then
        precio_unitario_centavos := v_precio_oferta;
        oferta_aplicada          := true;
      end if;
      -- Si no la encontro en la secuencia vigente, el precio de lista y la
      -- bandera en false SON la respuesta: es un aviso, no un error.
    end if;

    -- Lo que faltaba en 0011. Sin esto la app no puede saber a que linea
    -- corresponde cada fila, que es justo lo que mira antes de avisar.
    id_producto := v_pid;
    cantidad    := v_cant;

    return next;
  end loop;
end;
$fn$;
