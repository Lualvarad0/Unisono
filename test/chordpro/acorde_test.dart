import 'package:app_alabanzas/features/contenido/domain/chordpro/acorde.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Acorde.parse', () {
    test('acorde mayor simple', () {
      final a = Acorde.parse('G');
      expect(a.reconocido, isTrue);
      expect(a.nota, 'G');
      expect(a.sufijo, '');
      expect(a.bajo, isNull);
    });

    test('acorde con sufijo compuesto', () {
      final a = Acorde.parse('Am7');
      expect(a.nota, 'A');
      expect(a.sufijo, 'm7');
    });

    test('acorde con sostenido', () {
      final a = Acorde.parse('F#m');
      expect(a.nota, 'F#');
      expect(a.sufijo, 'm');
    });

    test('acorde con bajo alterado (slash chord)', () {
      final a = Acorde.parse('D/F#');
      expect(a.nota, 'D');
      expect(a.bajo, 'F#');
    });

    test('texto que no es un acorde pasa intacto', () {
      final a = Acorde.parse('N.C.');
      expect(a.reconocido, isFalse);
      expect(a.toString(), 'N.C.');
    });
  });

  group('Acorde.transponer', () {
    test('sube semitonos dentro de la escala', () {
      expect(Acorde.parse('C').transponer(2).toString(), 'D');
    });

    test('envuelve la octava (B + 1 semitono = C)', () {
      expect(Acorde.parse('B').transponer(1).toString(), 'C');
    });

    test('baja semitonos con offset negativo', () {
      expect(Acorde.parse('D').transponer(-2).toString(), 'C');
    });

    test('preserva el sufijo al transportar', () {
      expect(Acorde.parse('Am7').transponer(2).toString(), 'Bm7');
    });

    test('mantiene bemoles si el original usaba bemoles', () {
      expect(Acorde.parse('Bb').transponer(2).toString(), 'C');
      expect(Acorde.parse('Bb').transponer(3).toString(), 'Db');
    });

    test('transporta también la nota de bajo', () {
      expect(Acorde.parse('D/F#').transponer(2).toString(), 'E/G#');
    });

    test('acordes no reconocidos no cambian', () {
      expect(Acorde.parse('N.C.').transponer(5).toString(), 'N.C.');
    });

    test('semitonos 0 es un no-op', () {
      final original = Acorde.parse('G');
      expect(original.transponer(0), original);
    });
  });
}
