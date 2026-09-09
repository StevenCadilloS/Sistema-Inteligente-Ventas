import 'package:flutter/material.dart';

import '../../data/modelos/modelos.dart';

/// Imagen de un producto, resuelta desde el dato y no desde el codigo.
///
/// `productos.imagen` guarda el nombre de un archivo de `assets/products/`
/// (los 16 del catalogo sembrado viajan dentro del APK, que es lo que permite
/// que la tienda se vea bien sin descargar nada) o una URL completa, para los
/// productos que el administrador crea desde el panel.
///
/// Vive en un solo widget porque antes vivia en dos: la tarjeta del feed y el
/// popup de oferta tenian cada una su propio mapa de 16 lineas con las mismas
/// rutas. Con productos que ahora nacen en el servidor, mantener ese mapa al
/// dia era imposible por definicion.
class ImagenProducto extends StatelessWidget {
  const ImagenProducto({
    super.key,
    required this.producto,
    required this.respaldo,
    this.ancho = double.infinity,
    this.alto = double.infinity,
    this.radio = 8,
  });

  final Producto producto;

  /// Lo que se pinta cuando no hay imagen o cuando falla la descarga. Lo pone
  /// quien usa el widget: en el feed es el icono de la categoria sobre el
  /// fondo de la tarjeta, en el popup un recuadro propio.
  final Widget respaldo;

  final double ancho;
  final double alto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final ruta = producto.imagen;
    if (ruta == null || ruta.isEmpty) return respaldo;

    final esUrl = ruta.startsWith('http://') || ruta.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: esUrl
          ? Image.network(
              ruta,
              width: ancho,
              height: alto,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => respaldo,
            )
          : Image.asset(
              'assets/products/$ruta',
              width: ancho,
              height: alto,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => respaldo,
            ),
    );
  }
}
