-- ============================================================================
-- Ayudas para las pruebas SQL.
--
-- No hay framework: cada prueba es una sentencia que, si no se cumple, lanza
-- una excepcion. psql corre con -v ON_ERROR_STOP=1, asi que la primera
-- excepcion termina el proceso con codigo distinto de cero y CI se pone en
-- rojo. Es todo lo que hace falta para probar SQL.
--
-- Se aplica una sola vez, antes de los archivos de prueba.
-- ============================================================================

create or replace function test_igual(actual text, esperado text, que text)
returns void
language plpgsql
as $fn$
begin
  if actual is distinct from esperado then
    raise exception 'FALLO - %: se esperaba "%", se obtuvo "%"', que, esperado, actual;
  end if;
end;
$fn$;

create or replace function test_cierto(condicion boolean, que text)
returns void
language plpgsql
as $fn$
begin
  if condicion is not true then
    raise exception 'FALLO - %', que;
  end if;
end;
$fn$;

-- Ejecuta [sentencia] esperando que falle. Si [pista_esperada] no es nula,
-- ademas comprueba que el error traiga exactamente esa pista (el `hint` que
-- ponen las funciones de 0002 para poder distinguir "se agoto el stock" de un
-- fallo cualquiera sin depender del texto del mensaje).
--
-- El bloque interno crea un savepoint implicito: capturar la excepcion
-- deshace lo que la sentencia hubiera tocado, y la transaccion de la prueba
-- sigue viva.
create or replace function test_falla(
  sentencia text,
  pista_esperada text,
  que text
)
returns void
language plpgsql
as $fn$
declare
  v_pista text;
begin
  begin
    execute sentencia;
  exception when others then
    get stacked diagnostics v_pista = pg_exception_hint;
    if pista_esperada is not null and coalesce(v_pista, '') <> pista_esperada then
      raise exception 'FALLO - %: fallo, pero con pista "%" en vez de "%"',
        que, coalesce(v_pista, '(ninguna)'), pista_esperada;
    end if;
    return;
  end;
  raise exception 'FALLO - %: se esperaba un error y la sentencia paso', que;
end;
$fn$;

-- Deja constancia en la salida de psql de que un bloque de pruebas termino.
create or replace function test_ok(que text)
returns void
language plpgsql
as $fn$
begin
  raise notice 'OK - %', que;
end;
$fn$;
