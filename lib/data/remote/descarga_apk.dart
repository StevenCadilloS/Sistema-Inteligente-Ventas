import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Trae la APK nueva y se la entrega al instalador del sistema.
///
/// Antes esto lo hacia el navegador, y en un equipo del equipo la descarga
/// llegaba al 100% y ahi se quedaba: el archivo no aparecia por ningun lado y
/// el instalador nunca se abria. Haciendolo desde la app se ve el avance y se
/// sabe si fallo.
///
/// Android sigue mandando: pide autorizar a esta app a instalar (una vez) y
/// confirmar cada instalacion. No se instala nada a escondidas.
class DescargaApk {
  const DescargaApk._();

  /// Descarga [url] informando el avance en 0..1 y abre el instalador.
  ///
  /// El avance solo llega si el servidor manda `Content-Length`; si no, se
  /// informa -1 para que la interfaz muestre un indicador indeterminado en vez
  /// de una barra congelada en cero.
  static Future<void> descargarEInstalar(
    String url, {
    required void Function(double avance) onAvance,
  }) async {
    final destino = File('${(await getTemporaryDirectory()).path}/tienda.apk');

    // Una descarga a medias de una vez anterior instalaria un archivo corrupto.
    if (await destino.exists()) await destino.delete();

    final cliente = HttpClient();
    try {
      final peticion = await cliente.getUrl(Uri.parse(url));
      final respuesta = await peticion.close();

      if (respuesta.statusCode != HttpStatus.ok) {
        throw HttpException('El servidor respondio ${respuesta.statusCode}');
      }

      final total = respuesta.contentLength;
      var recibido = 0;
      final salida = destino.openWrite();
      try {
        await for (final trozo in respuesta) {
          salida.add(trozo);
          recibido += trozo.length;
          onAvance(total > 0 ? recibido / total : -1);
        }
      } finally {
        await salida.close();
      }

      // Un corte de red a mitad deja el archivo corto sin lanzar nada: sin esta
      // comprobacion se abriria el instalador con una APK incompleta y el error
      // que veria el usuario ("no se pudo analizar el paquete") no diria nada
      // de la causa real.
      if (total > 0 && await destino.length() != total) {
        throw const HttpException('La descarga quedo incompleta');
      }
    } finally {
      cliente.close();
    }

    final resultado = await OpenFilex.open(destino.path);
    if (resultado.type != ResultType.done) {
      throw HttpException('No se pudo abrir el instalador: ${resultado.message}');
    }
  }
}
