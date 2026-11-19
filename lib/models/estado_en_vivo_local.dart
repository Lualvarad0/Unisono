import 'package:equatable/equatable.dart';

/// Qué representa un [EstadoEnVivoLocal] dentro de una sesión de Modo en
/// vivo — info únicamente para quien recibe (no cambia qué datos trae el
/// mensaje), pero documenta la intención de quien lo mandó.
enum TipoEventoEnVivo {
  /// Estado completo reenviado a quien se conecta/reconecta — repite el
  /// último estado vigente, no representa un avance nuevo por sí mismo.
  snapshot,

  /// El líder cambió de canción o de sección.
  cambio,

  /// El líder detuvo la transmisión — ya no hay canción activa.
  detener,
}

/// Estado de "Modo en vivo" tal como lo transmite el líder por red local
/// — viaja directo entre celulares cercanos por Bluetooth/Wi-Fi Direct
/// (`ConexionLocalService`) en vez de por Firestore. No reemplaza a
/// Firestore (`EnVivoScreen`/`VistaEnVivoScreen` lo usan además de, no en
/// vez de, el repositorio real): esto es la capa rápida que funciona
/// aunque no haya internet en el lugar. No transporta letra ni acordes —
/// esos ya tienen que estar sincronizados en caché en cada teléfono (ver
/// `docs/épica #10`).
///
/// Contrato JSON (lo que viaja por Nearby):
/// ```json
/// {
///   "actividadId": "actividad-123",
///   "sesionId": "uuid-generado-por-lider",
///   "secuencia": 42,
///   "tipoEvento": "snapshot",
///   "cancionActivaId": "cancion-456",
///   "seccionActivaIndice": 2,
///   "emitidoEn": "2026-10-27T18:42:00.000Z"
/// }
/// ```
///
/// `sesionId` lo genera el líder una vez por sesión de Modo en vivo (al
/// iniciar `ConexionLocalService` como líder — ver esa clase) y `secuencia`
/// crece de a uno por cada cambio que ese líder transmite dentro de esa
/// sesión. Ninguno de los dos solo no alcanza para ordenar dos mensajes de
/// sesiones distintas (un UUID no tiene orden temporal propio), por eso
/// [esMasRecienteQue] también usa `emitidoEn`.
class EstadoEnVivoLocal extends Equatable {
  EstadoEnVivoLocal({
    required this.actividadId,
    this.sesionId = '',
    this.secuencia = 0,
    this.tipoEvento = TipoEventoEnVivo.snapshot,
    DateTime? emitidoEn,
    this.cancionActivaId,
    this.seccionActivaIndice = 0,
  }) : emitidoEn = emitidoEn ?? DateTime.now();

  final String actividadId;
  final String sesionId;
  final int secuencia;
  final TipoEventoEnVivo tipoEvento;
  final DateTime emitidoEn;
  final String? cancionActivaId;
  final int seccionActivaIndice;

  /// Decodifica un mensaje recibido por Nearby. Solo `actividadId` es
  /// estrictamente requerido — es el único campo que ya existía antes de
  /// este protocolo versionado (épica #10); si falta o no es un String no
  /// vacío, lanza [FormatException] en vez de devolver un estado a medias,
  /// para que quien reciba decida explícitamente qué hacer con un payload
  /// malformado (ver `ConexionLocalService`, que lo registra y lo
  /// descarta sin tocar el estado vigente).
  ///
  /// El resto de los campos nuevos (`sesionId`, `secuencia`, `tipoEvento`,
  /// `emitidoEn`) son defensivos: un mensaje viejo que no los incluya se
  /// decodifica igual, con los valores por omisión del constructor, en vez
  /// de rechazarse — compatibilidad con emisores que todavía no actualizaron
  /// el protocolo.
  factory EstadoEnVivoLocal.fromJson(Map<String, dynamic> json) {
    final actividadId = json['actividadId'];
    if (actividadId is! String || actividadId.isEmpty) {
      throw const FormatException('actividadId faltante o inválido');
    }
    TipoEventoEnVivo? tipoEvento;
    for (final valor in TipoEventoEnVivo.values) {
      if (valor.name == json['tipoEvento']) {
        tipoEvento = valor;
        break;
      }
    }
    final emitidoEnRaw = json['emitidoEn'];
    final emitidoEn =
        emitidoEnRaw is String ? DateTime.tryParse(emitidoEnRaw) : null;
    return EstadoEnVivoLocal(
      actividadId: actividadId,
      sesionId: json['sesionId'] as String? ?? '',
      secuencia: (json['secuencia'] as num?)?.toInt() ?? 0,
      tipoEvento: tipoEvento ?? TipoEventoEnVivo.snapshot,
      emitidoEn: emitidoEn,
      cancionActivaId: json['cancionActivaId'] as String?,
      seccionActivaIndice: (json['seccionActivaIndice'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'actividadId': actividadId,
        'sesionId': sesionId,
        'secuencia': secuencia,
        'tipoEvento': tipoEvento.name,
        'cancionActivaId': cancionActivaId,
        'seccionActivaIndice': seccionActivaIndice,
        'emitidoEn': emitidoEn.toUtc().toIso8601String(),
      };

  /// true si este estado debería reemplazar a [vigente] como el estado
  /// vigente de la sesión — la regla que usa `ConexionLocalService` para
  /// descartar duplicados, mensajes atrasados y sesiones viejas (épica
  /// #10, sub-tareas #12/#13).
  ///
  /// Dentro de la misma sesión (`sesionId` igual) alcanza con comparar
  /// `secuencia`, que el líder incrementa en cada cambio. Entre sesiones
  /// distintas no hay secuencia comparable — un UUID no tiene orden — así
  /// que se decide por `emitidoEn`: la sesión que empezó después gana, y un
  /// mensaje atrasado de una sesión ya vieja (con `emitidoEn` anterior al
  /// último estado aceptado) se descarta.
  bool esMasRecienteQue(EstadoEnVivoLocal? vigente) {
    if (vigente == null) return true;
    if (sesionId == vigente.sesionId) return secuencia > vigente.secuencia;
    return emitidoEn.isAfter(vigente.emitidoEn);
  }

  /// Copia de este estado marcada como [TipoEventoEnVivo.snapshot] — mismo
  /// contenido y la misma `secuencia`/`emitidoEn` originales, para que
  /// [esMasRecienteQue] lo siga ordenando igual que al mensaje del que
  /// viene. La usa `ConexionLocalService` para poner al día a quien se
  /// conecta o reconecta, sin que ese reenvío se confunda con un avance
  /// nuevo (épica #10, sub-tarea #13).
  EstadoEnVivoLocal comoSnapshot() => EstadoEnVivoLocal(
        actividadId: actividadId,
        sesionId: sesionId,
        secuencia: secuencia,
        tipoEvento: TipoEventoEnVivo.snapshot,
        emitidoEn: emitidoEn,
        cancionActivaId: cancionActivaId,
        seccionActivaIndice: seccionActivaIndice,
      );

  @override
  List<Object?> get props => [
        actividadId,
        sesionId,
        secuencia,
        tipoEvento,
        emitidoEn,
        cancionActivaId,
        seccionActivaIndice,
      ];
}
