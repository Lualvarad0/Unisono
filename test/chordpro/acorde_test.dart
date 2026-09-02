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

  group('Acorde.parse — cifrado español', () {
    test('notas simples se traducen a americano', () {
      expect(Acorde.parse('Do').nota, 'C');
      expect(Acorde.parse('Re').nota, 'D');
      expect(Acorde.parse('Mi').nota, 'E');
      expect(Acorde.parse('Fa').nota, 'F');
      expect(Acorde.parse('Sol').nota, 'G');
      expect(Acorde.parse('La').nota, 'A');
      expect(Acorde.parse('Si').nota, 'B');
    });

    test('conserva el sufijo (menor, séptima, etc.)', () {
      final a = Acorde.parse('Rem7');
      expect(a.nota, 'D');
      expect(a.sufijo, 'm7');
      expect(a.toString(), 'Dm7');
    });

    test('sostenidos y bemoles en español', () {
      expect(Acorde.parse('Do#').nota, 'C#');
      expect(Acorde.parse('Sib').nota, 'Bb');
    });

    test('bajo alterado en español (Re/Fa#)', () {
      final a = Acorde.parse('Re/Fa#');
      expect(a.nota, 'D');
      expect(a.bajo, 'F#');
    });

    test('no distingue mayúsculas/minúsculas', () {
      expect(Acorde.parse('sol').nota, 'G');
      expect(Acorde.parse('SOL').nota, 'G');
    });

    test('no confunde un acorde americano con una nota española', () {
      // "D7" no debe leerse como "Do" + sufijo "7" — al no encontrar la
      // "o" de "Do", tiene que caer en la rama de una sola letra.
      final a = Acorde.parse('D7');
      expect(a.nota, 'D');
      expect(a.sufijo, '7');
    });

    test('se transporta igual que uno escrito en americano', () {
      expect(
        Acorde.parse('Sol').transponer(2).toString(),
        Acorde.parse('G').transponer(2).toString(),
      );
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
