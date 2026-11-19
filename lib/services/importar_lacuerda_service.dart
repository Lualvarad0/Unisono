import 'package:cloud_functions/cloud_functions.dart';

/// Resultado de importar una canción desde acordes.lacuerda.net —
/// `tono` es solo una sugerencia (el primer acorde que aparece en la
/// canción), el líder lo revisa como cualquier otro campo antes de
/// guardar.
class CancionImportada {
  const CancionImportada({
    required this.titulo,
    required this.artista,
    required this.tono,
    required this.contenidoChordPro,
  });

  final String titulo;
  final String artista;
  final String? tono;
  final String contenidoChordPro;
}

/// Envoltorio sobre la Cloud Function `importarCancionLacuerda` (issue
/// #26) — el parseo en sí corre del lado del servidor (ver
/// `functions/lacuerda.js`), acá solo se llama y se traducen los
/// códigos de error a mensajes que el líder puede entender.
class ImportarLacuerdaService {
  ImportarLacuerdaService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<CancionImportada> importarDesdeUrl(String url) async {
    try {
      final resultado = await _functions
          .httpsCallable('importarCancionLacuerda')
          .call<Map<String, dynamic>>({'url': url.trim()});
      final datos = resultado.data;
      return CancionImportada(
        titulo: datos['titulo'] as String? ?? '',
        artista: datos['artista'] as String? ?? '',
        tono: datos['tono'] as String?,
        contenidoChordPro: datos['contenidoChordPro'] as String? ?? '',
      );
    } on FirebaseFunctionsException catch (e) {
      throw ImportarLacuerdaExcepcion(_mensaje(e));
    }
  }

  String _mensaje(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Solo el líder del equipo puede importar canciones.';
      case 'invalid-argument':
        return e.message ?? 'Esa URL no se pudo importar.';
      case 'not-found':
        return 'No se encontró esa canción — revisá la URL.';
      case 'unavailable':
        return 'No se pudo conectar con lacuerda.net — probá de nuevo en un rato.';
      case 'resource-exhausted':
        return 'Demasiados intentos — esperá un momento y probá de nuevo.';
      case 'unauthenticated':
        return 'Hace falta estar logueado.';
      default:
        return 'No se pudo importar la canción.';
    }
  }
}

class ImportarLacuerdaExcepcion implements Exception {
  const ImportarLacuerdaExcepcion(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
