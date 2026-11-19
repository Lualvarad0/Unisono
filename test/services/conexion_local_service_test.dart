import 'package:flutter_test/flutter_test.dart';

import 'package:app_alabanzas/services/sync_local/conexion_local_service.dart';

void main() {
  group('ConexionLocalService.transmitir', () {
    test('un líder asigna una sesión propia y una secuencia creciente',
        () async {
      final servicio = ConexionLocalService.forTesting(esLider: true);

      await servicio.transmitir(
          actividadId: 'actividad-1', cancionActivaId: 'cancion-1');
      final primero = servicio.ultimoEstado('actividad-1')!;

      await servicio.transmitir(
        actividadId: 'actividad-1',
        cancionActivaId: 'cancion-1',
        seccionActivaIndice: 1,
      );
      final segundo = servicio.ultimoEstado('actividad-1')!;

      expect(primero.sesionId, isNotEmpty);
      expect(segundo.sesionId, primero.sesionId);
      expect(segundo.secuencia, greaterThan(primero.secuencia));
    });

    test('un seguidor no transmite nada — el líder es la única autoridad',
        () async {
      final servicio = ConexionLocalService.forTesting(esLider: false);

      await servicio.transmitir(
          actividadId: 'actividad-1', cancionActivaId: 'cancion-1');

      expect(servicio.ultimoEstado('actividad-1'), isNull);
    });

    test('detener (tipoEvento) se transmite igual que un cambio', () async {
      final servicio = ConexionLocalService.forTesting(esLider: true);

      await servicio.transmitir(
          actividadId: 'actividad-1', cancionActivaId: 'cancion-1');
      await servicio.transmitir(
        actividadId: 'actividad-1',
        cancionActivaId: null,
        tipoEvento: TipoEventoEnVivo.detener,
      );

      final estado = servicio.ultimoEstado('actividad-1')!;
      expect(estado.tipoEvento, TipoEventoEnVivo.detener);
      expect(estado.cancionActivaId, isNull);
    });
  });
}
