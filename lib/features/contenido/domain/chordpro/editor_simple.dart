import 'acorde.dart';
import 'chordpro_modelo.dart';

/// Convierte entre el modelo ChordPro (`SeccionChordPro`/`LineaChordPro`,
/// con acordes intercalados en la letra vía corchetes) y la forma en la
/// que la mayoría de los músicos ya escriben una canción a mano: una
/// línea de acordes arriba, alineada por posición de caracter, y la línea
/// de letra debajo.
///
/// ```
/// G       D
/// Toda la tierra se inclina
/// ```
///
/// Nadie tiene que aprender `{start_of_verse}` ni `[G]` — el editor
/// (`EditorSimpleScreen`) solo pide "acordes" y "letra" por línea, y esto
/// hace la conversión en los dos sentidos.
class EditorSimpleConversor {
  const EditorSimpleConversor._();

  /// Arma una `LineaChordPro` ubicando cada palabra de [lineaAcordes] en
  /// la misma posición de caracter sobre [lineaLetra]. Si un acorde cae
  /// después del final de la letra (ej. una línea instrumental sin
  /// texto), queda pegado al final — igual que pasaría a mano.
  static LineaChordPro aLinea(String lineaAcordes, String lineaLetra) {
    final coincidencias = RegExp(r'\S+').allMatches(lineaAcordes).toList();
    final segmentos = <SegmentoChordPro>[];
    var cursor = 0;
    Acorde? acordeActual;

    for (final m in coincidencias) {
      final posicion = m.start.clamp(0, lineaLetra.length);
      final letraPrevia = lineaLetra.substring(cursor, posicion);
      if (letraPrevia.isNotEmpty || acordeActual != null) {
        segmentos.add(SegmentoChordPro(acorde: acordeActual, letra: letraPrevia));
      }
      acordeActual = Acorde.parse(m.group(0)!);
      cursor = posicion;
    }
    segmentos.add(
      SegmentoChordPro(acorde: acordeActual, letra: lineaLetra.substring(cursor)),
    );
    return LineaChordPro(segmentos: List.unmodifiable(segmentos));
  }

  /// La operación inversa: dada una `LineaChordPro` ya parseada, reconstruye
  /// las dos líneas de texto plano que se le muestran al usuario en el
  /// editor simple (para cuando abre una canción existente para editarla).
  static ({String acordes, String letra}) desdeLinea(LineaChordPro linea) {
    final letra = StringBuffer();
    final acordes = StringBuffer();
    for (final segmento in linea.segmentos) {
      if (segmento.acorde != null) {
        while (acordes.length < letra.length) {
          acordes.write(' ');
        }
        acordes.write(segmento.acorde.toString());
      }
      letra.write(segmento.letra);
    }
    return (acordes: acordes.toString(), letra: letra.toString());
  }
}
