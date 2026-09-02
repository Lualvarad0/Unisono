import 'package:app_alabanzas/models/chordpro/chordpro_modelo.dart';
import 'package:app_alabanzas/services/chordpro/chordpro_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const _fuente = '''
{title: Cuán Grande Es Mi Dios}
{key: G}
{start_of_verse: Verso 1}
[G]Cuán grande [D]es tu amor
[Em]Grande en poder[C]
{end_of_verse}
{start_of_chorus}
[G]Cuán grande [D]es mi Dios
{end_of_chorus}
''';

void main() {
  test('separa el documento en secciones con su tipo y etiqueta', () {
    final cancion = ChordProParser.parse(_fuente);
    expect(cancion.secciones, hasLength(2));
    expect(cancion.secciones[0].tipo, TipoSeccion.verso);
    expect(cancion.secciones[0].etiqueta, 'Verso 1');
    expect(cancion.secciones[1].tipo, TipoSeccion.coro);
    expect(cancion.secciones[1].etiqueta, 'Coro'); // etiqueta por defecto
  });

  test('ignora directivas de metadata como title y key', () {
    final cancion = ChordProParser.parse(_fuente);
    final todaLaLetra =
        cancion.secciones.expand((s) => s.lineas).map((l) => l.soloLetra).join(' ');
    expect(todaLaLetra, isNot(contains('Cuán Grande Es Mi Dios')));
  });

  test('parsea acordes y letra intercalados en una línea', () {
    final cancion = ChordProParser.parse(_fuente);
    final primeraLinea = cancion.secciones[0].lineas[0];
    expect(primeraLinea.soloLetra, 'Cuán grande es tu amor');
    expect(primeraLinea.segmentos.first.acorde?.toString(), 'G');
  });

  test('transponer cambia los acordes pero no la letra', () {
    final original = ChordProParser.parse(_fuente);
    final transportada = original.transponer(2);
    expect(
      transportada.secciones[0].lineas[0].soloLetra,
      original.secciones[0].lineas[0].soloLetra,
    );
    expect(
      transportada.secciones[0].lineas[0].segmentos.first.acorde?.toString(),
      'A',
    );
  });

  test('round-trip: parse -> toChordPro -> parse da el mismo resultado', () {
    final original = ChordProParser.parse(_fuente);
    final reconstruido = ChordProParser.parse(original.toChordPro());
    expect(reconstruido, original);
  });

  test('ignora líneas de comentario que empiezan con #', () {
    const conComentario = '''
# esto es un comentario, no debe aparecer
{start_of_verse}
[C]Hola
{end_of_verse}
''';
    final cancion = ChordProParser.parse(conComentario);
    expect(cancion.secciones, hasLength(1));
    expect(cancion.secciones[0].lineas[0].soloLetra, 'Hola');
  });

  test('conserva líneas en blanco dentro de una sección (separan estrofas)', () {
    const conBlanco = '''
{start_of_verse}
[C]Primera línea

[C]Segunda línea después de un espacio
{end_of_verse}
''';
    final cancion = ChordProParser.parse(conBlanco);
    expect(cancion.secciones[0].lineas, hasLength(3));
    expect(cancion.secciones[0].lineas[1].soloLetra, '');
  });
}
