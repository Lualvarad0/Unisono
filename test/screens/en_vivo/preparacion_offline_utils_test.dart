import 'package:flutter_test/flutter_test.dart';

import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/setlist_entry.dart';
import 'package:app_alabanzas/screens/en_vivo/preparacion_offline_utils.dart';

void main() {
  group('entradasSinCancionDisponible', () {
    const cancionDisponible = Cancion(
      id: 'cancion-1',
      titulo: 'Disponible',
      tonoOriginal: 'C',
      contenidoChordPro: '',
    );
    const entradaDisponible = SetlistEntry(
      cancionId: 'cancion-1',
      orden: 0,
      cantanteId: 'miembro-1',
    );
    const entradaFaltante = SetlistEntry(
      cancionId: 'cancion-2',
      orden: 1,
      cantanteId: 'miembro-1',
    );

    test('vacío cuando todas las canciones del setlist están disponibles',
        () {
      final faltantes = entradasSinCancionDisponible(
        [entradaDisponible],
        {'cancion-1': cancionDisponible},
      );

      expect(faltantes, isEmpty);
    });

    test('identifica las entradas cuya canción no está en el caché', () {
      final faltantes = entradasSinCancionDisponible(
        [entradaDisponible, entradaFaltante],
        {'cancion-1': cancionDisponible},
      );

      expect(faltantes, [entradaFaltante]);
    });

    test('un setlist vacío no tiene nada faltante', () {
      expect(entradasSinCancionDisponible(const [], const {}), isEmpty);
    });
  });
}
