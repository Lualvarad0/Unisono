import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_nearby_connections_plus/flutter_nearby_connections_plus.dart';

import 'package:app_alabanzas/models/estado_en_vivo_local.dart';

export 'package:app_alabanzas/models/estado_en_vivo_local.dart';

/// Estado de la conexión Nearby, para mostrarle a quien sigue al líder si
/// puede confiar en lo que está viendo — ver `ConexionLocalService.
/// estadoConexion` y la épica #10, sub-tarea #13.
enum EstadoConexionLocal {
  /// Nunca hubo un dispositivo conectado desde que arrancó el servicio.
  desconectado,

  /// Hubo un dispositivo conectado y se perdió — Nearby sigue buscando
  /// en segundo plano, sin que nadie tenga que reiniciar nada a mano.
  reconectando,

  /// Al menos un dispositivo conectado ahora mismo.
  recibiendo,
}

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

  /// true solo después de arrancar el plugin de verdad en [iniciar] — a
  /// diferencia de [_iniciado], `forTesting` nunca lo pone en true, así
  /// que [detener] no intenta pararle nada a un plugin que nunca arrancó
  /// (lo que rompería en test, sin binding de Flutter).
  bool _nearbyIniciado = false;
  bool _esLider = false;
  List<Device> _dispositivos = const [];
  final _yaInvitados = <String>{};

  /// Último grupo de `deviceId` conectados visto en `stateChangedSubscription`
  /// — compararlo contra el grupo nuevo es cómo se distingue "se conectó
  /// ahora" (reenviar snapshot si soy líder) de "se desconectó" (dejar que
  /// lo vuelva a invitar un seguidor, u olvidar seguidores si soy líder).
  final _conectadosAnteriores = <String>{};

  EstadoConexionLocal _estadoConexion = EstadoConexionLocal.desconectado;
  final _estadoConexionController =
      StreamController<EstadoConexionLocal>.broadcast();

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

  /// Cambia cuando se conecta o se pierde el último dispositivo Nearby —
  /// ver [EstadoConexionLocal].
  Stream<EstadoConexionLocal> get estadoConexion =>
      _estadoConexionController.stream;

  /// Para no perderse el estado si la pantalla se abre después de que ya
  /// cambió — misma razón que [ultimoEstado].
  EstadoConexionLocal get estadoConexionActual => _estadoConexion;

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
    _nearbyIniciado = true;

    _estadoConexionSub = _nearbyService.stateChangedSubscription(
      callback: (dispositivosEncontrados) {
        _dispositivos = dispositivosEncontrados;
        final conectadosAhora = {
          for (final d in dispositivosEncontrados)
            if (d.state == SessionState.connected) d.deviceId,
        };
        // Un dispositivo que se desconectó puede volver a aparecer como
        // `notConnected` — hay que poder volver a invitarlo (seguidor) o
        // volver a mandarle el snapshot cuando reconecte (líder), así que
        // sale de `_yaInvitados` apenas se nota que ya no está conectado.
        for (final idDesconectado
            in _conectadosAnteriores.difference(conectadosAhora)) {
          _yaInvitados.remove(idDesconectado);
        }
        final nuevosConectados =
            conectadosAhora.difference(_conectadosAnteriores);
        _conectadosAnteriores
          ..clear()
          ..addAll(conectadosAhora);
        _actualizarEstadoConexion(hayConectado: conectadosAhora.isNotEmpty);

        if (_esLider) {
          for (final deviceId in nuevosConectados) {
            unawaited(_reenviarSnapshotsA(deviceId));
          }
          return;
        }
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
      callback: (data) =>
          _procesarMensaje(data is String ? data : data.toString()),
    );
  }

  /// Decodifica un mensaje recibido por Nearby y, si corresponde (ver
  /// `EstadoEnVivoLocal.esMasRecienteQue`), lo adopta como estado vigente
  /// de su actividad — descarta en silencio un payload malformado o un
  /// mensaje atrasado/duplicado, sin tocar el estado vigente. Separado del
  /// callback real para poder ejercitarlo desde un test sin pasar por el
  /// plugin (ver `simularMensajeRecibido`).
  void _procesarMensaje(String texto) {
    try {
      final estado = EstadoEnVivoLocal.fromJson(
        jsonDecode(texto) as Map<String, dynamic>,
      );
      final vigente = _ultimoEstadoPorActividad[estado.actividadId];
      if (!estado.esMasRecienteQue(vigente)) return;
      _ultimoEstadoPorActividad[estado.actividadId] = estado;
      _estadosController.add(estado);
    } catch (e) {
      // Payload malformado (no era JSON, o le faltaba `actividadId`), o
      // mensaje atrasado/duplicado — ver doc de `EstadoEnVivoLocal.fromJson`
      // y `esMasRecienteQue`.
      if (kDebugMode) {
        debugPrint('ConexionLocalService: mensaje descartado ($e)');
      }
    }
  }

  /// Solo para tests: ejercita la misma validación/descarte que un mensaje
  /// real de Nearby (`dataReceivedSubscription`), sin pasar por el plugin.
  @visibleForTesting
  void simularMensajeRecibido(String mensajeJson) =>
      _procesarMensaje(mensajeJson);

  /// Pone al día a un dispositivo recién conectado con el último estado
  /// vigente de cada actividad — para que no se quede esperando el
  /// próximo cambio del líder para saber dónde está el servicio (épica
  /// #10, sub-tarea #13). Solo tiene sentido si soy líder: un seguidor no
  /// tiene estados propios para reenviar.
  Future<void> _reenviarSnapshotsA(String deviceId) async {
    for (final estado in _ultimoEstadoPorActividad.values) {
      final mensaje = jsonEncode(estado.comoSnapshot().toJson());
      await _nearbyService.sendMessage(deviceId, mensaje);
    }
  }

  void _actualizarEstadoConexion({required bool hayConectado}) {
    final nuevo = calcularEstadoConexion(
      anterior: _estadoConexion,
      hayConectado: hayConectado,
    );
    if (nuevo == _estadoConexion) return;
    _estadoConexion = nuevo;
    _estadoConexionController.add(nuevo);
  }

  /// Lógica pura detrás de [estadoConexion] — separada para poder probarla
  /// sin pasar por el plugin de Nearby. `anterior` distingue "nunca se
  /// conectó nadie" (queda `desconectado`) de "se conectó y se perdió"
  /// (pasa a `reconectando`), ya que ambos casos comparten `hayConectado:
  /// false`.
  @visibleForTesting
  static EstadoConexionLocal calcularEstadoConexion({
    required EstadoConexionLocal anterior,
    required bool hayConectado,
  }) {
    if (hayConectado) return EstadoConexionLocal.recibiendo;
    if (anterior == EstadoConexionLocal.desconectado) {
      return EstadoConexionLocal.desconectado;
    }
    return EstadoConexionLocal.reconectando;
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

  /// No deja nada corriendo (subscriptions, descubrimiento) ni nada
  /// pendiente (sesión, dispositivos vistos) — para que una próxima
  /// llamada a [iniciar] arranque una sesión limpia en vez de creer que ya
  /// está corriendo (épica #10, sub-tarea #13).
  Future<void> detener() async {
    if (!_iniciado) return;
    await _estadoConexionSub?.cancel();
    await _mensajeSub?.cancel();
    if (_nearbyIniciado) {
      await _nearbyService.stopAdvertisingPeer();
      await _nearbyService.stopBrowsingForPeers();
      _nearbyIniciado = false;
    }
    _estadoConexionSub = null;
    _mensajeSub = null;
    _iniciado = false;
    _dispositivos = const [];
    _yaInvitados.clear();
    _conectadosAnteriores.clear();
    _sesionId = null;
    _siguienteSecuencia = 0;
    // Directo a `desconectado` (no por `calcularEstadoConexion`, que
    // pasaría a `reconectando` si venía de `recibiendo`): detener() es un
    // corte explícito, no una pérdida de señal de la que haya que
    // recuperarse.
    if (_estadoConexion != EstadoConexionLocal.desconectado) {
      _estadoConexion = EstadoConexionLocal.desconectado;
      _estadoConexionController.add(_estadoConexion);
    }
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
