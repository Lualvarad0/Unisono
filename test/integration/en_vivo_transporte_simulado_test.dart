import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_alabanzas/services/sync_local/conexion_local_service.dart';

/// Transporte simulado para esta prueba: en vez de Nearby de verdad,
/// reenvía a mano el mismo JSON que `ConexionLocalService.transmitir`
/// mandaría por `NearbyService.sendMessage` — ejercita serialización,
/// descarte de atrasados y reenvío de snapshot con el código real de
/// producción, sin plugin ni radio (épica #10, sub-tarea #14).
class _CanalSimulado {
  _CanalSimulado(this.lider);

  final ConexionLocalService lider;
  final _conectados = <ConexionLocalService>[];

  /// Transmite desde el líder y reparte el mensaje resultante a cada
  /// seguidor conectado ahora — como el broadcast real de P2P_STAR.
  Future<void> transmitir({
    required String actividadId,
    String? cancionActivaId,
    int seccionActivaIndice = 0,
    TipoEventoEnVivo tipoEvento = TipoEventoEnVivo.cambio,
  }) async {
    await lider.transmitir(
      actividadId: actividadId,
      cancionActivaId: cancionActivaId,
      seccionActivaIndice: seccionActivaIndice,
      tipoEvento: tipoEvento,
    );
    final mensaje = jsonEncode(lider.ultimoEstado(actividadId)!.toJson());
    for (final seguidor in _conectados) {
      seguidor.simularMensajeRecibido(mensaje);
    }
  }

  /// Conecta a `seguidor`: recibe el snapshot vigente de cada actividad
  /// en `actividadIds` que el líder ya tenga — igual que
  /// `ConexionLocalService` le reenviaría a un dispositivo recién
  /// conectado o reconectado — y pasa a recibir las próximas
  /// transmisiones.
  void conectar(ConexionLocalService seguidor, List<String> actividadIds) {
    for (final id in actividadIds) {
      final estado = lider.ultimoEstado(id);
      if (estado == null) continue;
      seguidor.simularMensajeRecibido(
        jsonEncode(estado.comoSnapshot().toJson()),
      );
    }
    _conectados.add(seguidor);
  }

  /// Desconecta a `seguidor`: deja de recibirle transmisiones hasta que
  /// se lo vuelva a conectar.
  void desconectar(ConexionLocalService seguidor) =>
      _conectados.remove(seguidor);
}

void main() {
  group('Flujo de Modo en vivo con transporte simulado', () {
    test(
        'músico y cantante reciben canción, sección y detener en orden, '
        'y conservan la última versión', () async {
      final lider = ConexionLocalService.forTesting(esLider: true);
      final musico = ConexionLocalService.forTesting();
      final cantante = ConexionLocalService.forTesting();
      final canal = _CanalSimulado(lider)..conectar(musico, const []);
      canal.conectar(cantante, const []);

      await canal.transmitir(
          actividadId: 'actividad-1', cancionActivaId: 'cancion-1');
      await canal.transmitir(
        actividadId: 'actividad-1',
        cancionActivaId: 'cancion-1',
        seccionActivaIndice: 1,
      );
      await canal.transmitir(
        actividadId: 'actividad-1',
        cancionActivaId: null,
        tipoEvento: TipoEventoEnVivo.detener,
      );

      for (final seguidor in [musico, cantante]) {
        final estado = seguidor.ultimoEstado('actividad-1')!;
        expect(estado.tipoEvento, TipoEventoEnVivo.detener);
        expect(estado.cancionActivaId, isNull);
        expect(estado.secuencia, 2);
        expect(estado.sesionId, lider.ultimoEstado('actividad-1')!.sesionId);
      }
    });

    test(
        'un seguidor que pierde la red conserva la última sección y, al '
        'reconectar, converge al snapshot vigente sin reiniciar', () async {
      final lider = ConexionLocalService.forTesting(esLider: true);
      final seguidor = ConexionLocalService.forTesting();
      final canal = _CanalSimulado(lider)..conectar(seguidor, const []);

      await canal.transmitir(
          actividadId: 'actividad-1', cancionActivaId: 'cancion-1');
      canal.desconectar(seguidor);

      // El líder sigue avanzando mientras el seguidor está desconectado.
      await canal.transmitir(
        actividadId: 'actividad-1',
        cancionActivaId: 'cancion-1',
        seccionActivaIndice: 3,
      );
      expect(seguidor.ultimoEstado('actividad-1')!.seccionActivaIndice, 0);

      canal.conectar(seguidor, ['actividad-1']);

      expect(seguidor.ultimoEstado('actividad-1')!.seccionActivaIndice, 3);
    });

    test('un mensaje atrasado de secuencia menor no reemplaza la vigente',
        () async {
      final lider = ConexionLocalService.forTesting(esLider: true);
      final seguidor = ConexionLocalService.forTesting();
      final canal = _CanalSimulado(lider)..conectar(seguidor, const []);

      await canal.transmitir(
        actividadId: 'actividad-1',
        cancionActivaId: 'cancion-1',
        seccionActivaIndice: 0,
      );
      await canal.transmitir(
        actividadId: 'actividad-1',
        cancionActivaId: 'cancion-1',
        seccionActivaIndice: 5,
      );

      // Un paquete de la red local llega reordenado: repite el primer
      // mensaje (secuencia 0) después del segundo (secuencia 1).
      final sesionId = lider.ultimoEstado('actividad-1')!.sesionId;
      final mensajeAtrasado = jsonEncode({
        'actividadId': 'actividad-1',
        'sesionId': sesionId,
        'secuencia': 0,
        'tipoEvento': 'cambio',
        'cancionActivaId': 'cancion-1',
        'seccionActivaIndice': 0,
      });
      seguidor.simularMensajeRecibido(mensajeAtrasado);

      expect(seguidor.ultimoEstado('actividad-1')!.seccionActivaIndice, 5);
    });

    test(
        'un seguidor conectado desde antes recibe el snapshot al unirse '
        'a una sesión que ya estaba en curso', () async {
      final lider = ConexionLocalService.forTesting(esLider: true);
      final canal = _CanalSimulado(lider);

      await canal.transmitir(
        actividadId: 'actividad-1',
        cancionActivaId: 'cancion-1',
        seccionActivaIndice: 2,
      );

      final seguidorNuevo = ConexionLocalService.forTesting();
      canal.conectar(seguidorNuevo, ['actividad-1']);

      final snapshot = seguidorNuevo.ultimoEstado('actividad-1')!;
      expect(snapshot.tipoEvento, TipoEventoEnVivo.snapshot);
      expect(snapshot.cancionActivaId, 'cancion-1');
      expect(snapshot.seccionActivaIndice, 2);
    });
  });
}
