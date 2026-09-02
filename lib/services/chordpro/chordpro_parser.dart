import 'package:app_alabanzas/services/chordpro/acorde.dart';
import 'package:app_alabanzas/models/chordpro/chordpro_modelo.dart';

/// Convierte texto crudo en formato ChordPro (spec:
/// https://www.chordpro.org/chordpro/chordpro-file-format-specification/)
/// en un [CancionChordPro] navegable por secciones.
///
/// Reconoce las directivas estándar de sección, en su forma larga y corta:
/// `start_of_verse`/`sov`, `start_of_chorus`/`soc`, `start_of_bridge`/`sob`,
/// `start_of_tag`/`sot`, y sus `end_of_*`/`eo*` correspondientes.
///
/// Cualquier otra directiva entre llaves (`{title: ...}`, `{key: ...}`,
/// `{comment: ...}`, etc.) se ignora a propósito: esos metadatos ya viven
/// como campos propios en el modelo `Cancion` de Firestore (`titulo`,
/// `tonoOriginal`), así que no hace falta que el parser los entienda para
/// que el import de un archivo `.cho` real no falle.
class ChordProParser {
  const ChordProParser._();

  static final RegExp _directiva =
      RegExp(r'^\{\s*([a-zA-Z_]+)\s*(?::\s*(.*?)\s*)?\}$');
  static final RegExp _acordeEntreCorchetes = RegExp(r'\[([^\]]*)\]');

  static const _directivasInicio = {
    'start_of_verse': TipoSeccion.verso,
    'sov': TipoSeccion.verso,
    'start_of_chorus': TipoSeccion.coro,
    'soc': TipoSeccion.coro,
    'start_of_bridge': TipoSeccion.puente,
    'sob': TipoSeccion.puente,
    'start_of_tag': TipoSeccion.tag,
    'sot': TipoSeccion.tag,
  };

  static const _directivasFin = {
    'end_of_verse', 'eov', //
    'end_of_chorus', 'eoc', //
    'end_of_bridge', 'eob', //
    'end_of_tag', 'eot', //
  };

  static const _etiquetaPorDefecto = {
    TipoSeccion.verso: 'Verso',
    TipoSeccion.coro: 'Coro',
    TipoSeccion.puente: 'Puente',
    TipoSeccion.tag: 'Tag',
  };

  static CancionChordPro parse(String fuente) {
    final secciones = <SeccionChordPro>[];
    var tipoActual = TipoSeccion.otra;
    var etiquetaActual = '';
    var lineasActuales = <LineaChordPro>[];

    void cerrarSeccionActual() {
      if (lineasActuales.isNotEmpty || tipoActual != TipoSeccion.otra) {
        secciones.add(SeccionChordPro(
          tipo: tipoActual,
          etiqueta: etiquetaActual,
          lineas: List.unmodifiable(lineasActuales),
        ));
      }
      lineasActuales = <LineaChordPro>[];
    }

    for (final lineaCruda in fuente.split('\n')) {
      final linea = lineaCruda.trimRight();
      final sinEspaciosIniciales = linea.trimLeft();

      if (sinEspaciosIniciales.startsWith('#')) continue; // comentario

      final match = _directiva.firstMatch(sinEspaciosIniciales);
      if (match != null) {
        final nombre = match.group(1)!.toLowerCase();
        final argumento = match.group(2);

        final tipoInicio = _directivasInicio[nombre];
        if (tipoInicio != null) {
          cerrarSeccionActual();
          tipoActual = tipoInicio;
          etiquetaActual = (argumento != null && argumento.isNotEmpty)
              ? argumento
              : _etiquetaPorDefecto[tipoInicio]!;
          continue;
        }
        if (_directivasFin.contains(nombre)) {
          cerrarSeccionActual();
          tipoActual = TipoSeccion.otra;
          etiquetaActual = '';
          continue;
        }
        continue; // metadata u otra directiva no soportada: se ignora
      }

      // Línea en blanco fuera de cualquier sección: es solo separación
      // visual del archivo fuente, no contenido. Dentro de una sección sí
      // se conserva (separa estrofas dentro del mismo bloque).
      if (linea.trim().isEmpty && tipoActual == TipoSeccion.otra) continue;

      lineasActuales.add(_parseLinea(linea));
    }
    cerrarSeccionActual();

    return CancionChordPro(secciones: List.unmodifiable(secciones));
  }

  static LineaChordPro _parseLinea(String raw) {
    final segmentos = <SegmentoChordPro>[];
    var cursor = 0;
    Acorde? acordeActual;

    for (final match in _acordeEntreCorchetes.allMatches(raw)) {
      final letraPrevia = raw.substring(cursor, match.start);
      if (letraPrevia.isNotEmpty || acordeActual != null) {
        segmentos.add(SegmentoChordPro(acorde: acordeActual, letra: letraPrevia));
      }
      acordeActual = Acorde.parse(match.group(1)!);
      cursor = match.end;
    }
    segmentos.add(SegmentoChordPro(acorde: acordeActual, letra: raw.substring(cursor)));

    return LineaChordPro(segmentos: List.unmodifiable(segmentos));
  }
}
