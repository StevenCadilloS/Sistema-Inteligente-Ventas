-- ============================================================================
-- 0008 - Conecta los 16 archivos de assets/products/ con sus productos
--
-- 0005 subio las fotos empaquetadas a Storage como opcion, pero nunca se
-- asigno la columna `imagen` de ningun producto: por eso el catalogo entero
-- se veia sin fotos pese a que los archivos ya viajaban dentro del APK.
--
-- Requisito antes de correr esto: los 16 archivos de assets/products/ tienen
-- que estar subidos al bucket `productos` de Supabase Storage (Storage ->
-- productos -> Upload file, arrastrando los 16 de una vez). fn_url_imagen
-- arma la URL publica; si el archivo no esta en el bucket, la URL existe
-- pero la foto no carga y la tarjeta cae al icono de categoria.
--
-- Laptop Lenovo IdeaPad y Laptop HP Pavilion comparten categoria pero solo
-- hay una foto de laptop (P0000005_laptop.jpg): se le asigna a la Lenovo.
-- La HP, la Samsung Galaxy A55, el Mouse G203 y el Teclado K380 se quedan
-- sin foto propia hasta que se suba una para cada una.
-- ============================================================================

update productos set imagen = fn_url_imagen('P0000001_audifonos.jpg')
 where nombre = 'Audifonos Sony WH-CH520';

update productos set imagen = fn_url_imagen('P0000002_smartwatch.jpg')
 where nombre = 'Smartwatch Deportivo';

update productos set imagen = fn_url_imagen('P0000003_parlante.jpg')
 where nombre = 'Parlante Bluetooth Portatil';

update productos set imagen = fn_url_imagen('P0000004_cargador.jpg')
 where nombre = 'Cargador Rapido 65W';

update productos set imagen = fn_url_imagen('P0000005_laptop.jpg')
 where nombre = 'Laptop Lenovo IdeaPad';

update productos set imagen = fn_url_imagen('P0000006_sartenes.jpg')
 where nombre = 'Juego de Sartenes Antiadherentes';

update productos set imagen = fn_url_imagen('P0000007_lampara.jpg')
 where nombre = 'Lampara de Escritorio LED';

update productos set imagen = fn_url_imagen('P0000008_organizador.jpg')
 where nombre = 'Organizador Multiuso';

update productos set imagen = fn_url_imagen('P0000009_aspiradora.jpg')
 where nombre = 'Aspiradora de Mano';

update productos set imagen = fn_url_imagen('P0000010_polo.jpg')
 where nombre = 'Polo Basico de Algodon';

update productos set imagen = fn_url_imagen('P0000011_zapatillas.jpg')
 where nombre = 'Zapatillas Urbanas';

update productos set imagen = fn_url_imagen('P0000012_mochila.jpg')
 where nombre = 'Mochila Antirrobo';

update productos set imagen = fn_url_imagen('P0000013_casaca.jpg')
 where nombre = 'Casaca Impermeable';

update productos set imagen = fn_url_imagen('P0000014_skincare.jpg')
 where nombre = 'Kit de Cuidado Facial';

update productos set imagen = fn_url_imagen('P0000015_secadora.jpg')
 where nombre = 'Secadora de Cabello Ionica';

update productos set imagen = fn_url_imagen('P0000016_perfume.jpg')
 where nombre = 'Perfume Floral 50ml';
