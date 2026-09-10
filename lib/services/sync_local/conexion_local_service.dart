import 'dart:async';
import 'dart:convert';

import 'package:flutter_nearby_connections_plus/flutter_nearby_connections_plus.dart';

/// Estado de "Modo en vivo" tal como lo transmite el líder por red local
/// — mismos dos campos que ya vive en `Actividad` (`cancionActivaId`,
/// `seccionActivaIndice`), pero viajando directo entre celulares cercanos
/// por Bluetooth/Wi-Fi Direct en vez de por Firestore. No reemplaza a
/// Firestore (`EnVivoScreen`/`VistaEnVivoScreen` lo usan además de, no en
/// vez de, el repositorio real): esto es la capa rápida que funciona
/// aunque no haya internet en el lugar.
class EstadoEnVivoLocal {
  const EstadoEnVivoLocal({
    required this.actividadId,
    this.cancionActivaId,
    this.seccionActivaIndice = 0,
  });

  final String actividadId;
  final String? cancionActivaId;
  final int seccionActivaIndice;

  factory EstadoEnVivoLocal.fromJson(Map<String, dynamic> json) => EstadoEnVivoLocal(
        actividadId: json['actividadId'] as String? ?? '',
        cancionActivaId: json['cancionActivaId'] as String?,
        seccionActivaIndice: (json['seccionActivaIndice'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'actividadId': actividadId,
        'cancionActivaId': cancionActivaId,
        'seccionActivaIndice': seccionActivaIndice,
      };
}

/// Sincronización P2P de "Modo en vivo" entre celulares cercanos, sin
/// depender de internet — sale del prototipo aislado del Paso 4
/// (`prototipo_conexion_service.dart`), con dos diferencias para uso
/// real: acá el rol (líder/seguidor) lo decide `Miembro.roles` en vez de
/// elegirse a mano, y la conexión es automática — nadie tiene que tocar
/// "Conectar" en medio de un servicio.
class ConexionLocalService {
  ConexionLocalService() : _nearbyService = NearbyService();

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
  Future<void> iniciar({required String nombreDispositivo, required bool esLider}) async {
    if (_iniciado) return;
    _iniciado = true;
    _esLider = esLider;

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
        } catch (_) {
          // No era un mensaje de estado en vivo — se ignora.
        }
      },
    );
  }

  /// Sin efecto si este celular no es el líder — se llama junto con (no
  /// en vez de) el guardado en Firestore desde `EnVivoScreen` y
  /// `VistaEnVivoScreen`.
  Future<void> transmitir(EstadoEnVivoLocal estado) async {
    if (!_esLider) return;
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
}
