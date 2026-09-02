import 'package:app_alabanzas/features/contenido/domain/chordpro/chordpro_parser.dart';
import 'package:app_alabanzas/features/contenido/domain/chordpro/editor_simple.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorSimpleConversor.aLinea', () {
    test('ubica cada acorde en la posición de caracter que le corresponde', () {
      final linea = EditorSimpleConversor.aLinea(
        'G       D',
        'Toda la tierra se inclina',
      );
      expect(linea.soloLetra, 'Toda la tierra se inclina');
      expect(linea.toChordPro(), '[G]Toda la [D]tierra se inclina');
    });

    test('sin acordes, la línea queda como texto plano', () {
      final linea = EditorSimpleConversor.aLinea('', 'solo letra, sin acordes');
      expect(linea.toChordPro(), 'solo letra, sin acordes');
    });

    test('acordes que caen después del final de la letra quedan al final '
        '(línea instrumental)', () {
      final linea = EditorSimpleConversor.aLinea('        G   D', 'Intro');
      expect(linea.soloLetra, 'Intro');
      expect(linea.toChordPro(), 'Intro[G][D]');
    });

    test('acepta cifrado español en la línea de acordes', () {
      final linea = EditorSimpleConversor.aLinea('Sol', 'Cuán grande es');
      expect(linea.toChordPro(), '[G]Cuán grande es');
    });
  });

  group('EditorSimpleConversor — ida y vuelta con ChordProParser', () {
    test('aLinea -> toChordPro -> parse da la misma letra y los mismos '
        'acordes', () {
      final original =
          EditorSimpleConversor.aLinea('G       D', 'Toda la tierra se inclina');
      final reconstruida = ChordProParser.parse(
        '{start_of_verse}\n${original.toChordPro()}\n{end_of_verse}',
      ).secciones.first.lineas.first;

      expect(reconstruida.soloLetra, original.soloLetra);
      expect(reconstruida.toChordPro(), original.toChordPro());
    });
  });

  group('EditorSimpleConversor.desdeLinea', () {
    test('reconstruye las dos líneas de texto a partir de una LineaChordPro', () {
      final cancion = ChordProParser.parse(
        '{start_of_verse}\n[G]Toda la t[D]ierra se inclina\n{end_of_verse}',
      );
      final resultado =
          EditorSimpleConversor.desdeLinea(cancion.secciones.first.lineas.first);

      expect(resultado.letra, 'Toda la tierra se inclina');
      // El acorde D tiene que caer en el mismo índice de caracter que
      // ocupa en la letra ("Toda la t|ierra..." -> índice 9).
      expect(resultado.acordes.indexOf('D'), 9);
      expect(resultado.acordes.startsWith('G'), isTrue);
    });

    test('ida y vuelta: desdeLinea(aLinea(x)) reproduce la misma línea', () {
      final original = EditorSimpleConversor.aLinea(
        'G       D',
        'Toda la tierra se inclina',
      );
      final comoTexto = EditorSimpleConversor.desdeLinea(original);
      final reconstruida =
          EditorSimpleConversor.aLinea(comoTexto.acordes, comoTexto.letra);

      expect(reconstruida, original);
    });
  });
}
