import 'package:flutter_test/flutter_test.dart';

import 'package:app_alabanzas/models/estado_en_vivo_local.dart';

void main() {
  group('EstadoEnVivoLocal JSON', () {
    test(
        'round-trip conserva actividad, sesión, secuencia, evento, canción y sección',
        () {
      final original = EstadoEnVivoLocal(
        actividadId: 'actividad-123',
        sesionId: 'sesion-abc',
        secuencia: 42,
        tipoEvento: TipoEventoEnVivo.cambio,
        emitidoEn: DateTime.utc(2026, 10, 27, 18, 42),
        cancionActivaId: 'cancion-456',
        seccionActivaIndice: 2,
      );

      final reconstruido = EstadoEnVivoLocal.fromJson(original.toJson());

      expect(reconstruido, original);
    });

    test('un payload sin los campos nuevos decodifica con valores por omisión',
        () {
      final estado = EstadoEnVivoLocal.fromJson(const {
        'actividadId': 'actividad-123',
        'cancionActivaId': 'cancion-456',
        'seccionActivaIndice': 2,
      });

      expect(estado.actividadId, 'actividad-123');
      expect(estado.sesionId, '');
      expect(estado.secuencia, 0);
      expect(estado.tipoEvento, TipoEventoEnVivo.snapshot);
      expect(estado.cancionActivaId, 'cancion-456');
      expect(estado.seccionActivaIndice, 2);
    });

    test('un payload sin actividadId lanza FormatException', () {
      expect(
        () => EstadoEnVivoLocal.fromJson(
            const {'cancionActivaId': 'cancion-456'}),
        throwsFormatException,
      );
    });

    test('un actividadId vacío también se trata como inválido', () {
      expect(
        () => EstadoEnVivoLocal.fromJson(const {'actividadId': ''}),
        throwsFormatException,
      );
    });

    test('un tipoEvento desconocido cae al valor por omisión en vez de fallar',
        () {
      final estado = EstadoEnVivoLocal.fromJson(const {
        'actividadId': 'actividad-123',
        'tipoEvento': 'algo-que-no-existe-todavia',
      });

      expect(estado.tipoEvento, TipoEventoEnVivo.snapshot);
    });
  });

  group('EstadoEnVivoLocal.esMasRecienteQue', () {
    EstadoEnVivoLocal estado({
      String sesionId = 'sesion-1',
      int secuencia = 0,
      DateTime? emitidoEn,
    }) {
      return EstadoEnVivoLocal(
        actividadId: 'actividad-1',
        sesionId: sesionId,
        secuencia: secuencia,
        emitidoEn: emitidoEn ?? DateTime.utc(2026, 1, 1),
      );
    }

    test('cualquier estado es más reciente que ningún estado vigente', () {
      expect(estado().esMasRecienteQue(null), isTrue);
    });

    test('rechaza una secuencia antigua de la misma sesión', () {
      final vigente = estado(sesionId: 'sesion-1', secuencia: 8);
      final atrasado = estado(sesionId: 'sesion-1', secuencia: 7);

      expect(atrasado.esMasRecienteQue(vigente), isFalse);
    });

    test('acepta una secuencia mayor de la misma sesión', () {
      final vigente = estado(sesionId: 'sesion-1', secuencia: 8);
      final nuevo = estado(sesionId: 'sesion-1', secuencia: 9);

      expect(nuevo.esMasRecienteQue(vigente), isTrue);
    });

    test('aísla un mensaje atrasado de una sesión anterior', () {
      final vigente = estado(
        sesionId: 'sesion-nueva',
        secuencia: 0,
        emitidoEn: DateTime.utc(2026, 1, 2),
      );
      final deSesionVieja = estado(
        sesionId: 'sesion-vieja',
        secuencia: 99,
        emitidoEn: DateTime.utc(2026, 1, 1),
      );

      expect(deSesionVieja.esMasRecienteQue(vigente), isFalse);
    });

    test('acepta una sesión nueva que empieza después de la vigente', () {
      final vigente = estado(
        sesionId: 'sesion-vieja',
        secuencia: 99,
        emitidoEn: DateTime.utc(2026, 1, 1),
      );
      final deSesionNueva = estado(
        sesionId: 'sesion-nueva',
        secuencia: 0,
        emitidoEn: DateTime.utc(2026, 1, 2),
      );

      expect(deSesionNueva.esMasRecienteQue(vigente), isTrue);
    });
  });

  group('EstadoEnVivoLocal.comoSnapshot', () {
    test('conserva sesión, secuencia y contenido, cambia el tipo de evento',
        () {
      final original = EstadoEnVivoLocal(
        actividadId: 'actividad-1',
        sesionId: 'sesion-1',
        secuencia: 8,
        tipoEvento: TipoEventoEnVivo.cambio,
        emitidoEn: DateTime.utc(2026, 1, 1),
        cancionActivaId: 'cancion-456',
        seccionActivaIndice: 2,
      );

      final snapshot = original.comoSnapshot();

      expect(snapshot.tipoEvento, TipoEventoEnVivo.snapshot);
      expect(snapshot.sesionId, original.sesionId);
      expect(snapshot.secuencia, original.secuencia);
      expect(snapshot.emitidoEn, original.emitidoEn);
      expect(snapshot.cancionActivaId, original.cancionActivaId);
      expect(snapshot.seccionActivaIndice, original.seccionActivaIndice);
    });

    test('un snapshot reenviado no gana contra lo que ya se había aceptado',
        () {
      final original = EstadoEnVivoLocal(
        actividadId: 'actividad-1',
        sesionId: 'sesion-1',
        secuencia: 8,
        emitidoEn: DateTime.utc(2026, 1, 1),
      );
      final siguiente = EstadoEnVivoLocal(
        actividadId: 'actividad-1',
        sesionId: 'sesion-1',
        secuencia: 9,
        emitidoEn: DateTime.utc(2026, 1, 1, 0, 0, 1),
      );

      expect(original.comoSnapshot().esMasRecienteQue(siguiente), isFalse);
    });
  });
}
