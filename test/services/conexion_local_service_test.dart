import 'dart:convert';

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

  group('ConexionLocalService.simularMensajeRecibido', () {
    EstadoEnVivoLocal estado({
      String actividadId = 'actividad-1',
      String sesionId = 'sesion-1',
      int secuencia = 0,
      String? cancionActivaId,
    }) {
      return EstadoEnVivoLocal(
        actividadId: actividadId,
        sesionId: sesionId,
        secuencia: secuencia,
        cancionActivaId: cancionActivaId,
      );
    }

    test('acepta el primer estado que llega para una actividad', () {
      final servicio = ConexionLocalService.forTesting();

      servicio.simularMensajeRecibido(
        jsonEncode(estado(cancionActivaId: 'cancion-1').toJson()),
      );

      expect(
          servicio.ultimoEstado('actividad-1')?.cancionActivaId, 'cancion-1');
    });

    test('descarta un mensaje atrasado de la misma sesión', () {
      final servicio = ConexionLocalService.forTesting();

      servicio.simularMensajeRecibido(
        jsonEncode(estado(secuencia: 5, cancionActivaId: 'cancion-2').toJson()),
      );
      servicio.simularMensajeRecibido(
        jsonEncode(estado(secuencia: 3, cancionActivaId: 'cancion-1').toJson()),
      );

      expect(
          servicio.ultimoEstado('actividad-1')?.cancionActivaId, 'cancion-2');
      expect(servicio.ultimoEstado('actividad-1')?.secuencia, 5);
    });

    test('un payload malformado no pisa el estado vigente', () {
      final servicio = ConexionLocalService.forTesting();
      servicio.simularMensajeRecibido(
        jsonEncode(estado(cancionActivaId: 'cancion-1').toJson()),
      );

      servicio.simularMensajeRecibido('esto no es JSON válido');

      expect(
          servicio.ultimoEstado('actividad-1')?.cancionActivaId, 'cancion-1');
    });
  });

  group('ConexionLocalService.calcularEstadoConexion', () {
    test('sin conexión y sin historial previo queda desconectado', () {
      expect(
        ConexionLocalService.calcularEstadoConexion(
          anterior: EstadoConexionLocal.desconectado,
          hayConectado: false,
        ),
        EstadoConexionLocal.desconectado,
      );
    });

    test('con algún dispositivo conectado pasa a recibiendo', () {
      expect(
        ConexionLocalService.calcularEstadoConexion(
          anterior: EstadoConexionLocal.desconectado,
          hayConectado: true,
        ),
        EstadoConexionLocal.recibiendo,
      );
    });

    test('perder la conexión que sí había pasa a reconectando (no a desconectado)',
        () {
      expect(
        ConexionLocalService.calcularEstadoConexion(
          anterior: EstadoConexionLocal.recibiendo,
          hayConectado: false,
        ),
        EstadoConexionLocal.reconectando,
      );
    });

    test('reconectando sigue reconectando mientras no haya nadie conectado',
        () {
      expect(
        ConexionLocalService.calcularEstadoConexion(
          anterior: EstadoConexionLocal.reconectando,
          hayConectado: false,
        ),
        EstadoConexionLocal.reconectando,
      );
    });
  });

  group('ConexionLocalService.detener', () {
    test('deja el servicio listo para iniciar() de nuevo', () async {
      final servicio = ConexionLocalService.forTesting(esLider: true);
      final sesionOriginal = servicio.ultimoEstado('actividad-1');
      expect(sesionOriginal, isNull);

      await servicio.transmitir(
          actividadId: 'actividad-1', cancionActivaId: 'cancion-1');
      await servicio.detener();

      expect(servicio.estadoConexionActual, EstadoConexionLocal.desconectado);
    });
  });
}
