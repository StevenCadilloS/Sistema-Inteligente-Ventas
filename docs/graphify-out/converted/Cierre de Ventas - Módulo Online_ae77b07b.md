<!-- converted from Cierre de Ventas - Módulo Online.docx -->

UNIVERSIDAD NACIONAL DE INGENIERÍA
FACULTAD DE INGENIERÍA INDUSTRIAL Y DE SISTEMAS










MÓDULO ONLINE
DISEÑO DE BASE DE DATOS
SISTEMA CIERRE DE VENTAS
Dr. Tino Reyna Monteverde
INTEGRANTES:

Cadillo Saavedra Steven Joan        	20222641G
Medina Luján Juan Carlos             	20211168C
Siccha Aquino Sebastian Gustavo 	20220163K



4 de junio, 2025
Lima, Perú
Primer Caso

Segundo caso:



















































MÓDULO ONLINE
TABLAS MAESTRAS
Maestra - Productos
Diseño Físico

Maestra - Clientes
Diseño Físico

Maestra - Estrategias
Diseño Físico

TABLAS DE MOVIMIENTO
Bitácora - Interacciones
Diseño Físco

Bitácora - Ventas
Diseño Físico

Bitácora - Detalle Venta
Diseño Físico
Protocolo





| Atributo | Tipo | Tamaño | Clave |
| --- | --- | --- | --- |
| cod_lote_producto | char | 8 | PK |
| nombre_producto | varchar | 20 | SK |
| fecha_creacion_stock | date | 8 | -- |
| total_disponible | int | 4 | -- |
| total_vendidos | int | 4 | -- |
| total_veces_mostrado | int | 4 | -- |
| estado_producto | char | 1 | -- |
| Nombre | MAESTRA - PRODUCTOS |
| --- | --- |
| Organización | indexada |
| Longitud de Registro | (53,53) |
| IC | 1024 |
| Capacidad | N=1000000, AC=19*12*18 |
| Atributo | Tipo | Tamaño | Clave |
| --- | --- | --- | --- |
| cod_cliente | char | 8 | PK |
| nombre_cliente | varchar | 20 | SK |
| fecha_ingreso | date | 8 | -- |
| cant_lecturas | int | 7 | -- |
| total_compras | int | 6 | -- |
| monto_total | dec | 10 | -- |
| última_visita | date | 8 | -- |
| estado_cliente | char | 1 | -- |
| Nombre | MAESTRA - CLIENTES |
| --- | --- |
| Organización | indexada |
| Longitud de Registro | (68,68) |
| IC | 512 |
| Capacidad | N=1000000, AC= 19*24*7 |
| Atributo | Tipo | Tamaño | Clave |
| --- | --- | --- | --- |
| cod_estrategia | char | 8 | PK |
| nombre_estrategia | varchar | 20 | SK |
| total_veces_aplicada | int | 4 | -- |
| ventas_generadas | int | 4 | -- |
| estado | char | 1 | -- |
| Nombre | MAESTRA - ESTRATEGIAS |
| --- | --- |
| Organización | indexada |
| Longitud de Registro | (37,37) |
| IC | 1536 |
| Capacidad | N=1000000, AC= 19*6*38 |
| Atributo | Tipo | Tamaño | Clave |
| --- | --- | --- | --- |
| canal | char | 1 | PK |
| correlativo | int | 4 | PK |
| id_interaccion | char | 8 | -- |
| cod_cliente | char | 8 | FK |
| cod_estrategia | char | 8 | FK |
| cod_gesto | char | 8 | FK |
| cod_producto | char | 8 | FK |
| tipo_transaccion | char | 4 | -- |
| fecha | date | 8 | -- |
| hora | date | 8 | -- |
| nivel_de_interes | float | 2 | -- |
| Nombre | BITÁCORA INTERACCIONES |
| --- | --- |
| Organización | Indexado |
| Longitud de Registro | (67,67) |
| IC | 512 |
| Capacidad | N=1000000, AC= 19*24*7 |
| Atributo | Tipo | Tamaño | Clave |
| --- | --- | --- | --- |
| canal | char | 1 | PK |
| correlativo | int | 4 | PK |
| cod_cliente | char | 8 | FK |
| cod_estrategia | char | 8 | FK |
| tipo_transaccion | char | 4 | -- |
| fecha | date | 8 | -- |
| hora | date | 8 | -- |
| Nombre | BITÁCORA VENTAS |
| --- | --- |
| Organización | Indexado |
| Longitud de Registro | (41,41) |
| IC | 1024 |
| Capacidad | N=1000000, AC= 19*12*23 |
| Atributo | Tipo | Tamaño | Clave |
| --- | --- | --- | --- |
| canal_venta | char | 1 | PK |
| correlativo | int | 4 | PK |
| cod_lote_producto | char | 8 | PK |
| cantidad | int | 4 | -- |
| Nombre | BITÁCORA DETALLE VENTA |
| --- | --- |
| Organización | Indxado |
| Longitud de Registro | (17,17) |
| IC | 512 |
| Capacidad | N=1000000, AC= 19*24*23 |