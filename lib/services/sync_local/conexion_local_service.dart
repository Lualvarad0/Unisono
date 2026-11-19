import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_nearby_connections_plus/flutter_nearby_connections_plus.dart';

import 'package:app_alabanzas/models/estado_en_vivo_local.dart';

export 'package:app_alabanzas/models/estado_en_vivo_local.dart';

/// Sincronización P2P de "Modo en vivo" entre celulares cercanos, sin
/// depender de internet — sale del prototipo aislado del Paso 4
/// (`prototipo_conexion_service.dart`), con dos diferencias para uso
/// real: acá el rol (líder/seguidor) lo decide `Miembro.roles` en vez de
/// elegirse a mano, y la conexión es automática — nadie tiene que tocar
/// "Conectar" en medio de un servicio.
class ConexionLocalService {
  ConexionLocalService() : _nearbyService = NearbyService();

  /// Para tests: deja asignar `esLider`/`sesionId` sin pasar por
  /// `iniciar()` (que habla con el plugin Nearby de verdad, imposible en
  /// `flutter test`). Nunca llama a `_nearbyService` — `_dispositivos`
  /// queda vacío, así que `transmitir()` tampoco lo necesita.
  @visibleForTesting
  ConexionLocalService.forTesting({bool esLider = false, String? sesionId})
      : _nearbyService = NearbyService(),
        _iniciado = true,
        _esLider = esLider,
        _sesionId = sesionId ?? (esLider ? _generarSesionId() : null);

  /// Debe matchear con `NSBonjourServices` en ios/Runner/Info.plist y
  /// tener 15 caracteres o menos (límite del paquete) — mismo valor que
  /// ya usaba el prototipo, ahí ya está configurado.
  static const _tipoDeServicio = 'app-alabanzas';

  final NearbyService _nearbyService;

  StreamSubscription? _estadoConexionSub;
  StreamSubscription? _mensajeSub;

  bool _iniciado = false;
  bool _esLider = false;
  List<Device> _dispositivos = const [];
  final _yaInvitados = <String>{};

  /// Generado una vez por sesión de Modo en vivo, solo si este celular es
  /// líder — es lo que hace que el líder (y solo el líder, mientras dure
  /// esta sesión) sea la autoridad de la sesión: ver doc de
  /// `EstadoEnVivoLocal.esMasRecienteQue`.
  String? _sesionId;
  int _siguienteSecuencia = 0;

  final _estadosController = StreamController<EstadoEnVivoLocal>.broadcast();
  final _ultimoEstadoPorActividad = <String, EstadoEnVivoLocal>{};

  /// Estados recibidos del líder, a medida que llegan.
  Stream<EstadoEnVivoLocal> get estados => _estadosController.stream;

  /// Último estado recibido para una actividad puntual — para no perderse
  /// el mensaje si la pantalla se abre después de que ya llegó.
  EstadoEnVivoLocal? ultimoEstado(String actividadId) =>
      _ultimoEstadoPorActividad[actividadId];

  /// Arranca una sola vez por sesión (ver `PrincipalShellScreen`). Quien
  /// es líder anuncia este celular; el resto busca y se conecta solo al
  /// primero que encuentra, sin ninguna pantalla de "elegí a quién
  /// conectarte" — a diferencia del prototipo, esto corre en segundo
  /// plano todo el tiempo que dure la sesión.
  Future<void> iniciar(
      {required String nombreDispositivo, required bool esLider}) async {
    if (_iniciado) return;
    _iniciado = true;
    _esLider = esLider;
    if (_esLider) _sesionId = _generarSesionId();

    final listo = Completer<void>();
    await _nearbyService.init(
      serviceType: _tipoDeServicio,
      strategy: Strategy.P2P_STAR,
      deviceName: nombreDispositivo,
      callback: (bool corriendo) {
        if (!listo.isCompleted) listo.complete();
      },
    );
    await listo.future;

    if (_esLider) {
      await _nearbyService.startAdvertisingPeer();
    } else {
      await _nearbyService.startBrowsingForPeers();
    }

    _estadoConexionSub = _nearbyService.stateChangedSubscription(
      callback: (dispositivosEncontrados) {
        _dispositivos = dispositivosEncontrados;
        if (_esLider) return;
        for (final dispositivo in dispositivosEncontrados) {
          if (dispositivo.state == SessionState.notConnected &&
              _yaInvitados.add(dispositivo.deviceId)) {
            _nearbyService.invitePeer(
              deviceID: dispositivo.deviceId,
              deviceName: dispositivo.deviceName,
            );
          }
        }
      },
    );

    _mensajeSub = _nearbyService.dataReceivedSubscription(
      callback: (data) {
        final texto = data is String ? data : data.toString();
        try {
          final estado = EstadoEnVivoLocal.fromJson(
            jsonDecode(texto) as Map<String, dynamic>,
          );
          _ultimoEstadoPorActividad[estado.actividadId] = estado;
          _estadosController.add(estado);
        } catch (e) {
          // Payload malformado (no era JSON, o le faltaba `actividadId`):
          // se descarta sin tocar el estado vigente — ver doc de
          // `EstadoEnVivoLocal.fromJson`.
          if (kDebugMode) {
            debugPrint('ConexionLocalService: mensaje descartado ($e)');
          }
        }
      },
    );
  }

  /// Transmite un cambio de estado en vivo a quien esté conectado — sin
  /// efecto si este celular no es el líder. Se llama junto con (no en vez
  /// de) el guardado en Firestore desde `EnVivoScreen` y
  /// `VistaEnVivoScreen`, pero sin esperarlo: esta llamada no depende de
  /// internet, así que no hay que bloquear la UI hasta que Firestore
  /// conteste (ver épica #10, sub-tarea #12).
  ///
  /// El líder (acá, no quien llama) asigna `sesionId` y `secuencia` —
  /// nunca confía en que alguien se las pase — para que la sesión tenga
  /// una sola autoridad real. Ver doc de `EstadoEnVivoLocal`.
  Future<void> transmitir({
    required String actividadId,
    String? cancionActivaId,
    int seccionActivaIndice = 0,
    TipoEventoEnVivo tipoEvento = TipoEventoEnVivo.cambio,
  }) async {
    if (!_esLider) return;
    final estado = EstadoEnVivoLocal(
      actividadId: actividadId,
      sesionId: _sesionId ?? '',
      secuencia: _siguienteSecuencia++,
      tipoEvento: tipoEvento,
      cancionActivaId: cancionActivaId,
      seccionActivaIndice: seccionActivaIndice,
    );
    _ultimoEstadoPorActividad[estado.actividadId] = estado;
    final mensaje = jsonEncode(estado.toJson());
    for (final dispositivo in _dispositivos) {
      if (dispositivo.state == SessionState.connected) {
        await _nearbyService.sendMessage(dispositivo.deviceId, mensaje);
      }
    }
  }

  Future<void> detener() async {
    if (!_iniciado) return;
    await _estadoConexionSub?.cancel();
    await _mensajeSub?.cancel();
    await _nearbyService.stopAdvertisingPeer();
    await _nearbyService.stopBrowsingForPeers();
  }

  /// No necesita ser criptográficamente única — solo distinguir sesiones
  /// de Modo en vivo sucesivas del mismo líder dentro del alcance de
  /// Nearby (celulares cercanos), nunca entre apps instaladas en todo el
  /// mundo. Evita sumar una dependencia nueva (`uuid`) solo para esto.
  static String _generarSesionId() {
    final aleatorio = Random().nextInt(1 << 32);
    return '${DateTime.now().microsecondsSinceEpoch}-$aleatorio';
  }
}
