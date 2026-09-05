<!-- converted from Módulo Online - Cierre de Ventas .xlsx -->

## Sheet: Modelo
|  |  |  |  |  |  |  | Transaccion |
| --- | --- | --- | --- | --- | --- | --- | --- |
|  |  |  | Estrategias |  |  |  | codTRX |
|  | Cliente |  | cod_estrategia |  |  |  | Tipo_TRX |
|  | cod_cliente |  | nombre_estrategia |  |  |  | cod_protocolo |
|  | nombre |  | tipo_estrategia |  |  |  | estado |
|  | dni |  | cod_gesto |  |  |
|  | tipo_cliente |  | min interes |
|  | edad |  | max interes |
|  | sexo |
|  |  |  |  |  |  |  | MOV-INTERACCIONES |
|  |  |  |  |  |  |  | canal |
|  |  |  |  |  |  |  | correlativo |
|  |  |  |  |  |  |  | id_interaccion |
|  |  |  |  |  |  |  | cod_cliente |
|  |  |  |  |  |  |  | cod_estrategia |
|  |  |  |  |  |  |  | cod_gesto |
|  |  |  |  |  |  |  | cod_producto |
|  |  |  |  |  |  |  | tipo_transaccion |
|  |  |  |  |  |  |  | fecha |
|  |  |  |  |  |  |  | hora |
|  |  |  |  |  |  |  | nivel_de_interes |
|  |  |  | Cuenta-Productos |
|  |  |  | cod_lote_producto |
|  |  |  | nombre_producto |
|  |  |  | fecha_creacion_stock |
|  |  |  | total_disponible |
|  |  |  | total_vendidos |
|  |  |  | total_veces_mostrado |
|  |  |  | estado_producto |
|  |  |  |  |  |  |  | canal |
|  |  |  |  |  |  |  | correlativo |
|  |  |  |  |  |  |  | cod_cliente |
|  |  |  |  |  |  |  | cod_estrategia |
|  |  |  |  |  |  |  | tipo_transaccion |
|  |  |  |  |  |  |  | fecha |
|  |  |  |  |  |  |  | hora |
## Sheet: TABLA PROPUESTAS
|  |  |  |  |  |  |  |  |  | TABLAS MAESTRAS |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |  |  | MAESTRA - PRODUCTOS |
|  |  |  |  |  |  |  |  |  | Atributo | Tipo | Tamaño  | Clave |  | Diseño Físico |
|  |  |  |  |  |  |  |  |  | cod_lote_producto | char | 8.0 | PK |  | Nombre | MAESTRA - PRODUCTOS |
|  |  |  |  |  |  |  |  |  | nombre_producto | varchar | 20.0 | SK |  | Organización | indexada |
|  |  |  |  |  |  |  |  |  | fecha_creacion_stock | date | 8.0 | -- |  | Longitud de Registro | (53,53) |
|  |  |  |  |  |  |  |  |  | total_disponible | int | 4.0 | -- |  | IC | 1024.0 |
|  |  |  |  |  |  |  |  |  | total_vendidos | int | 4.0 | -- |  | Capacidad | N=1000000, AC=19*12*18 |
|  |  |  |  |  |  |  |  |  | cierres_venta |
|  |  |  |  |  |  |  |  |  | total_veces_mostrado | int | 4.0 | -- |
| TABLAS DE MOVIMIENTOS |  |  |  |  |  |  |  |  | estado_producto | char | 1.0 | -- |
| BITÁCORA INTERACCIONES |
| Atributo | Tipo | Tamaño  | Clave |
| canal | char | 1.0 | PK |
| correlativo | int | 4.0 |  |  | Nombre | BITÁCORA INTERACCIONES |  |  | MAESTRA - CLIENTES |
| cod_cliente | char | 8.0 | SK |  | Organización | Indexado |  |  | Atributo | Tipo | Tamaño  | Clave |
| id_proceso_venta | date | 6.0 |  |  | Longitud de Registro | (67,67) |  |  | cod_cliente | char | 8.0 | PK |
| tipo_cliente | char | 4.0 | FK |  | IC | 512.0 |  |  | nombre_cliente | varchar | 20.0 | SK |  | Nombre | MAESTRA - CLIENTES |
| cod_estrategia | char | 8.0 | FK |  | Capacidad | N=1000000, AC= 19*24*7 |  |  | fecha_ingreso | date | 8.0 | -- |  | Organización | indexada |
| cod_gesto | char | 8.0 | FK |  |  |  |  |  | cant_entradas | int | 7.0 | -- |  | Longitud de Registro | (68,68) |
| cod_producto | char | 8.0 | FK |  |  |  |  |  | total_cierres_ventas | int | 6.0 | -- |  | IC | 512.0 |
| tipo_transaccion | char | 4.0 | -- |  |  |  |  |  | última_visita | date | 8.0 | -- |  | Capacidad | N=1000000, AC= 19*24*7 |
| fecha | date | 8.0 | -- |  |  |  |  |  | estado_cliente | char | 1.0 | -- |
| hora | date | 8.0 | -- |
| nivel_de_interes | float | 2.0 | -- |
|  |  |  |  |  |  |  |  |  | MAESTRA - ESTRATEGIAS |
| BITÁCORA VENTAS |  |  |  |  |  |  |  |  | Atributo | Tipo | Tamaño  | Clave |
| Atributo | Tipo | Tamaño  | Clave |  |  |  |  |  | cod_estrategia | char | 8.0 | PK |  | Nombre | MAESTRA - ESTRATEGIAS |
| canal | #REF! | 1.0 | PK |  | Nombre | BITÁCORA VENTAS |  |  | nombre_estrategia | varchar | 20.0 | SK |  | Organización | indexada |
| correlativo | #REF! | 4.0 |  |  | Organización | Indexado |  |  | tipo_cliente | char | 6.0 | -FK |  | Longitud de Registro | (37,37) |
| cod_cliente | #REF! | 8.0 | SK |  | Longitud de Registro | (41,41) |  |  | total_veces_aplicada | int | 4.0 | -- |  | IC | 1536.0 |
| cod_producto | char | 8.0 | FK | FK | IC | 1024.0 |  |  | ventas_generadas | int | 4.0 | -- |  | Capacidad | N=1000000, AC= 19*6*38 |
| cantidad | int | 3.0 | --- |  | Capacidad | N=1000000, AC= 19*12*23 |  |  | estado | char | 1.0 | -- |
| cod_estrategia | #REF! | 8.0 | FK |
| tipo_transaccion | #REF! | 4.0 | -- |
| fecha | #REF! | 8.0 | -- |  |  |  |  |  | E1 |
| hora | #REF! | 8.0 | -- |  |  |  |  |  | E2 |
|  |  |  |  |  |  |  |  |  | E3 |
|  |  |  |  |  |  |  |  |  | E4 |
| BITÁCORA DETALLE VENTA |
| Atributo | Tipo | Tamaño  | Clave |
| canal_venta | char | 1.0 | PK |  | Nombre | BITÁCORA DETALLE VENTA |
| correlativo | int | 4.0 |  |  | Organización | Indexado |
| cod_lote_producto | char | 8.0 |  |  | Longitud de Registro | (17,17) |
| cantidad | int | 4.0 | -- |  | IC | 512.0 |
|  |  |  |  |  | Capacidad | N=1000000, AC= 19*24*23 |
|  |  |  |  |  | W | 1.0 | C000001 | 2025-06-04 00:00:00 | T0001 | E000001 | G000001 | 0000000 | TRX0001 | 09:01:25 | 60.0 |
|  |  |  |  |  | W | 2.0 | C000001 | 2025-06-04 00:00:00 | T0001 | E000002 | G000002 | P000002 | TRX0002 | 09:05:17 | 75.0 |
|  |  |  |  |  | W | 3.0 | C000001 | 2025-06-04 00:00:00 | T0001 | E000003 | G000003 | P000003 | TRX0003 | 09:07:30 | 90.0 |
|  |  |  |  |  | W | 4.0 | C000001 | 2025-06-04 00:00:00 | T0001 | E000003 | G000004 | P000004 | TRX0004 | 09:09:50 | 100.0 |
|  | CASO 1: BITÁCORA INTERACCIONES |
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | MAESTRA PRODUCTOS |
|  | canal | correlativo | cod_cliente | id_proceso_venta | tipo_cliente | cod_estrategia | cod_gesto | cod_lote_producto | tipo_transaccion | fecha | hora | nivel_de_interes |
|  | W | 0001 | C0000002 | I00001 | T00001 | E0000012 | G0000004 | 00000000 | TRX0003 | 2025-06-04 00:00:00 | 09:12:11 | 70.0 |  |  | cod_lote_producto | nombre_producto | fecha_creacion_stock | total_disponible | total_vendidos | total_veces_mostrado | estado_producto |
|  | ... | ... | ... | ... | ,,, | ... | ... | ... | ... | ... | ... | ... |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |  |  | P0000005 | Camiseta básica | 2023-05-02 00:00:00 | 50.0 | 150.0 | 18.0 | Activo |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | canal | correlativo | cod_cliente | id_proceso_venta | tipo_cliente | cod_estrategia | cod_gesto | cod_lote_producto | tipo_transaccion | fecha | hora | nivel_de_interes |  |  | cod_lote_producto | nombre_producto | fecha_creacion_stock | total_disponible | total_vendidos | total_veces_mostrado | estado_producto |
|  | W | 0001 | C0000002 | I00001 | T00001 | E0000012 | G0000004 | 00000000 | TRX0003 | 2025-06-04 00:00:00 | 09:12:11 | 70.0 |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | W | 0002 | C0000002 | I00001 | T00001 | E0000002 | G0000002 | P0000005 | TRX0004 | 2025-06-04 00:00:00 | 09:13:12 | 90.0 |  |  | P0000005 | Camiseta básica | 2023-05-02 00:00:00 | 50.0 | 150.0 | 19.0 | Activo |
|  | ... | ... | ... | ... | ... |  | ... | ... | ... | ... | ... | ... |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | cod_lote_producto | nombre_producto | fecha_creacion_stock | total_disponible | total_vendidos | total_veces_mostrado | estado_producto |
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | canal | correlativo | cod_cliente | id_proceso_venta | tipo_cliente | cod_estrategia | cod_gesto | cod_lote_producto | tipo_transaccion | fecha | hora | nivel_de_interes |  |  | P0000005 | Camiseta básica | 2023-05-02 00:00:00 | 49.0 | 151.0 | 19.0 | Activo |
|  | W | 0001 | C0000002 | I00001 | T00001 | E0000012 | G0000004 | 00000000 | TRX0003 | 2025-06-04 00:00:00 | 09:12:11 | 70.0 |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | W | 0002 | C0000002 | I00001 | T00001 | E0000002 | G0000002 | P0000005 | TRX0004 | 2025-06-04 00:00:00 | 09:13:12 | 90.0 |
|  | W | 0003 | C0000002 | I00001 | T00001 | E0000003 | G0000006 | P0000005 | TRX0005 | 2025-06-04 00:00:00 | 09:13:47 | 100.0 |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |
|  | BITACORA VENTAS |
|  | canal | correlativo | cod_cliente | cod_estrategia | tipo_transaccion | fecha | hora |
|  | W | 0001 | C0000002 | E0000003 | TRX0005 | 2025-06-04 00:00:00 | 09:13:47 |
|  | ... | ... | ... | ... | ... | ... | ... |
|  | DETALLE VENTA |
|  | canal_venta | correlativo | cod_lote_producto | cantidad |
|  | W | 0001 | P0000005 | 1.0 |
|  | ... | ... | ... | ... |
|  | CASO 2: BITACORA INTERACCIONES |
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | MAESTRA PRODUCTOS |
|  | canal | correlativo | cod_cliente | id_proceso_venta | tipo_cliente | cod_estrategia | cod_gesto | cod_lote_producto | tipo_transaccion | fecha | hora | nivel_de_interes |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |  |  | cod_lote_producto | nombre_producto | fecha_creacion_stock | total_disponible | total_vendidos | total_veces_mostrado | estado_producto |
|  | A | 0001 | C0000023 | I00002 | T00003 | E0000012 | G0000004 | 00000000 | TRX0003 | 2025-05-26 00:00:00 | 17:20:11 | 30.0 |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |  |  | P0000024 | Pantalon gris | 2025-02-02 00:00:00 | 33.0 | 120.0 | 20.0 | Activo |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |  |  | P0000028 | Jean clásico | 2025-02-02 00:00:00 | 18.0 | 160.0 | 37.0 | Activo |
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | canal | correlativo | cod_cliente | id_proceso_venta | tipo_cliente | cod_estrategia | cod_gesto | cod_lote_producto | tipo_transaccion | fecha | hora | nivel_de_interes |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |
|  | A | 0001 | C0000023 | I00002 | T00003 | E0000012 | G0000004 | 00000000 | TRX0003 | 2025-05-26 00:00:00 | 17:20:11 | 30.0 |  |  | cod_lote_producto | nombre_producto | fecha_creacion_stock | total_disponible | total_vendidos | total_veces_mostrado | estado_producto |
|  | A | 0002 | C0000023 | I00002 | T00003 | E0000001 | G0000008 | P0000024 | TRX0003 | 2025-05-26 00:00:00 | 17:21:11 | 80.0 |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |  |  | P0000024 | Pantalon gris | 2025-02-02 00:00:00 | 33.0 | 120.0 | 21.0 | Activo |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |  |  | P0000028 | Jean clásico | 2025-02-02 00:00:00 | 18.0 | 160.0 | 37.0 | Activo |
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | canal | correlativo | cod_cliente | id_proceso_venta | tipo_cliente | cod_estrategia | cod_gesto | cod_lote_producto | tipo_transaccion | fecha | hora | nivel_de_interes |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |
|  | A | 0001 | C0000023 | I00002 | T00003 | E0000012 | G0000004 | 00000000 | TRX0003 | 2025-05-26 00:00:00 | 17:20:11 | 30.0 |  |  | cod_lote_producto | nombre_producto | fecha_creacion_stock | total_disponible | total_vendidos | total_veces_mostrado | estado_producto |
|  | A | 0002 | C0000023 | I00002 | T00003 | E0000001 | G0000008 | P0000024 | TRX0003 | 2025-05-26 00:00:00 | 17:21:11 | 80.0 |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | A | 0003 | C0000023 | I00002 | T00003 | E0000002 | G0000011 | P0000028 | TRX0003 | 2025-05-26 00:00:00 | 17:22:11 | 90.0 |  |  | P0000024 | Pantalon gris | 2025-02-02 00:00:00 | 33.0 | 120.0 | 19.0 | Activo |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |  |  | P0000028 | Jean clásico | 2025-02-02 00:00:00 | 18.0 | 160.0 | 38.0 | Activo |
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | canal | correlativo | cod_cliente | id_proceso_venta | tipo_cliente | cod_estrategia | cod_gesto | cod_lote_producto | tipo_transaccion | fecha | hora | nivel_de_interes |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |
|  | A | 0001 | C0000023 | I00002 | T00003 | E0000012 | G0000004 | 00000000 | TRX0003 | 2025-05-26 00:00:00 | 17:20:11 | 30.0 |  |  | cod_lote_producto | nombre_producto | fecha_creacion_stock | total_disponible | total_vendidos | total_veces_mostrado | estado_producto |
|  | A | 0002 | C0000023 | I00002 | T00003 | E0000001 | G0000008 | P0000024 | TRX0003 | 2025-05-26 00:00:00 | 17:21:11 | 80.0 |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | A | 0003 | C0000023 | I00002 | T00003 | E0000002 | G0000011 | P0000028 | TRX0004 | 2025-05-26 00:00:00 | 17:22:11 | 90.0 |  |  | P0000024 | Pantalon gris | 2025-02-02 00:00:00 | 33.0 | 120.0 | 19.0 | Activo |
|  | A | 0004 | C0000023 | I00002 | T00003 | E0000005 | G0000015 | P0000028 | TRX0005 | 2025-05-26 00:00:00 | 17:24:11 | 100.0 |  |  | P0000028 | Jean clásico | 2025-02-02 00:00:00 | 17.0 | 161.0 | 38.0 | Activo |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |  |  | ... | ... | ... | ... | ... | ... | ... |
|  | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |
|  | BITACORA VENTAS |  |  |  |  |  |  |  |  |  |  |  |
|  | canal | correlativo | cod_cliente | cod_estrategia | tipo_transaccion | fecha | hora |  |  |  |  |  |
|  | ... | ... | ... | ... | ... | ... | ... |  |  |  |  |  |
|  | A | 0001 | C0000023 | E0000005 | TRX0005 | 2025-05-26 00:00:00 | 17:24:11 |  |  |  |  |  |
|  | ... | ... | ... | ... | ... | ... | ... |  |
|  | DETALLE VENTA |
|  | canal_venta | correlativo | cod_lote_producto | cantidad |
|  | ... | ... | ... | ... |
|  | A | 0001 | P0000028 | 1.0 |
|  | ... | ... | ... | ... |
## Sheet: Consulta crítica
|  |  |  |  | Consulta de Cierres de venta por Tipo de producto |  |  |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |  |  |  | Maestra clientes |  | cod_cliente | nombre | apellido |
|  |  |  |  |  | Tipo de producto | T00002 |  |  |  | Maestra productos |  | cod_producto | nombre | tipo_producto | total_ventasxtipoProducto (se conseguira a treves de calculo) |
|  |  |  |  |  |  |  |  |  |  | Estrategias |  | cod_estrategia | nombre_estrategia |
|  |  |  |  |  |  |  |  |  |  | bitacora venta |  | cantidad | fecha | hora |
|  |  |  |  |  | Nombre tipo | Casaca |
|  |  | cod cliente | nombre | apellido | cod_producto | nombre_producto | cantidad | cod_estrategia | nombre_estrategia | fecha | hora |  |
|  |  | C0000001 | Diego | Moran | P0000001 | Casaca Ultimate | 3.0 | E000001 | Oferta persuasiva | 24/'02/2025 | 12:03:04 | Ver detalles |
|  |  | C0000002 | Steven | Cadillo | P0000002 | Casaca Ligth | 1.0 | E000008 | Producto alternativo | 2025-01-23 00:00:00 | 13:03:04 | Ver detalles |
|  |  | C0000003 | Tino | Reyna | P0000003 | Casaca Deluxe Verano | 2.0 | E000005 | Producto alternativo | ´10/01/2025 | 14:03:04 | Ver detalles |
|  |  | ... | ... | ... | .. | ... | ... | ... | ... | ... | ... | ... |
|  |  |  |  |  | 1.0 | 2.0 | 3.0 | 4.0 | 5.0 |
|  |  |  | DISEÑO LÓGICO |
|  |  |  | tipo_producto | char | 6.0 | PK |  |  | clave primaria | tipo_producto |
|  |  |  | nombre_tipo_producto | char | 10.0 | SK |  |  | clave secundaria | nombre_tipo_producto |
|  |  |  | total_ventas | int | 3.0 |  |  |  |  |  |
|  |  |  | ventas | ´1-99 |
|  |  |  |  | cod_cliente | char | 8.0 | FK |
|  |  |  |  | nombre | char | 20.0 |
|  |  |  |  | apellido | char | 20.0 |
|  |  |  |  | cod_producto | char | 8.0 |
|  |  |  |  | nombre_producto | char | 20.0 |
|  |  |  |  | cantidad | int | 3.0 |
|  |  |  |  | cod_estrategia | char | 8.0 |
|  |  |  |  | nombre_estrategia | char | 20.0 |
|  |  |  |  | fecha | date | 8.0 |
|  |  |  |  | hora | date | 8.0 |
|  | a. | Nombre | Tabla consulta Cierres de ventas - tipo Producto |
|  |  | Organizacion | Indexada |
|  |  | Clave-Primaria | tipo_producto |
|  |  | Clave-Secundaria | nombre_tipo_producto |  |  |  |  |  |  | RL | ER |
|  |  |  |  |  |  |  | 10216.0 |  |  | 0.0 | 508.0 |
|  | b. | Longitud-Registro | (12196,2479) |  |  |  |  |  | 512.0 | 0.0 | 1020.0 |
|  |  |  |  |  |  |  |  |  | 1024.0 | 0.0 | 10.0 |
|  | c. | Espacio Libre | (0,0) |  |  |  |  |  | 1536.0 | 0.0 | 1532.0 |
|  |  |  |  |  |  |  |  |  | 2048.0 | 1.0 | 2044.0 |
|  | d. | Longitud de BLOQUE (IC) | 2560.0 |  |  |  |  |  | 2560.0 | 1.0 | 74.0 | se elige este |
|  |  |  |  |  |  |  |  |  | 3072.0 | 1.0 | 1098.0 |
|  | e.  | Longitud de EXTENT (AC) | 19*3*1 RLS |  |  |  |  |  | 3584.0 | 1.0 | 1610.0 |
|  | f. | Capacidad | (N=1000000, AC= 19*3*2 RLS) |
|  |  |  |  |  |  |  |  |  | IC |  | RL |  | ER |
|  |  |  |  |  |  |  |  | 2479.0 | 512.0 | 0.2046736503 | 0 | 0.2046736503 | 508 |
|  |  |  |  |  |  |  |  |  | 1024.0 | 0.4109589041 | 0 | 0.4109589041 | 1020 |
|  |  |  |  |  |  |  |  |  | 1536.0 | 0.6172441579 | 0 | 0.6172441579 | 1532 |
|  |  |  |  |  |  |  |  |  | 2048.0 | 0.8235294118 | 0 | 0.8235294118 | 2044 |
|  |  |  |  |  |  |  |  |  | 2560.0 | 1.029814666 | 1 | 0.02981466559 | 74 |
|  |  |  |  |  |  |  |  |  | 3072.0 | 1.236099919 | 1 | 0.2360999194 | 586 |
|  | En la carpeta se encuentra el diagrama |  |  |  |  |  |  |  | 3584.0 | 1.442385173 | 1 | 0.4423851732 | 1098 |