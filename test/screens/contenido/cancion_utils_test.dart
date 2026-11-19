import 'package:flutter_test/flutter_test.dart';

import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/screens/contenido/cancion_utils.dart';

Cancion _cancion(String id, {DateTime? creadaEn}) {
  return Cancion(
    id: id,
    titulo: id,
    tonoOriginal: 'C',
    contenidoChordPro: '',
    creadaEn: creadaEn,
  );
}

void main() {
  group('ordenarPorRecientes', () {
    test('ordena de la más nueva a la más antigua por creadaEn', () {
      final vieja = _cancion('vieja', creadaEn: DateTime(2026, 1, 1));
      final media = _cancion('media', creadaEn: DateTime(2026, 6, 1));
      final nueva = _cancion('nueva', creadaEn: DateTime(2026, 11, 1));

      final resultado = ordenarPorRecientes([vieja, nueva, media]);

      expect(resultado, [nueva, media, vieja]);
    });

    test('las sin creadaEn van al final, nunca antes que una con fecha', () {
      final sinFecha = _cancion('sinFecha');
      final conFecha = _cancion('conFecha', creadaEn: DateTime(2020, 1, 1));

      final resultado = ordenarPorRecientes([sinFecha, conFecha]);

      expect(resultado, [conFecha, sinFecha]);
    });

    test('si nadie tiene fecha, conserva el orden original (estable)', () {
      final a = _cancion('a');
      final b = _cancion('b');
      final c = _cancion('c');

      final resultado = ordenarPorRecientes([a, b, c]);

      expect(resultado, [a, b, c]);
    });
  });
}
