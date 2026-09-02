import 'dart:async';

import 'package:flutter_nearby_connections_plus/flutter_nearby_connections_plus.dart';

/// Envoltorio delgado sobre [NearbyService] para el prototipo aislado del
/// Paso 4. No es la integración final de la Capa 2 — es a propósito lo
/// mínimo indispensable para probar, en dos celulares reales, que un
/// "líder" puede transmitir un valor que cambia y un "seguidor" lo recibe
/// en tiempo real sin internet, antes de conectar esto al estado real de
/// la app (`actividadId`, `indiceCancion`, `seccion`, `tonoActual` — eso
/// llega en el Paso 5, integrado a `sync_local`).
///
/// IMPORTANTE: no funciona en emulador — Nearby Connections necesita
/// radios de Bluetooth/Wi-Fi Direct reales. Probar solo en dispositivos
/// físicos (ver README, sección Paso 4).
class PrototipoConexionService {
  PrototipoConexionService() : _nearbyService = NearbyService();

  /// Debe matchear _exactamente_ con `NSBonjourServices` en
  /// ios/Runner/Info.plist (`_app-alabanzas._tcp`) y tener 15 caracteres
  /// o menos (límite del paquete).
  static const tipoDeServicio = 'app-alabanzas';

  final NearbyService _nearbyService;

  StreamSubscription? _estadoSubscription;
  StreamSubscription? _mensajeSubscription;

  final _dispositivosController = StreamController<List<Device>>.broadcast();
  final _mensajesController = StreamController<String>.broadcast();

  /// Dispositivos descubiertos/conectados, con su [SessionState].
  Stream<List<Device>> get dispositivos => _dispositivosController.stream;

  /// Mensajes de texto recibidos de un peer conectado.
  Stream<String> get mensajes => _mensajesController.stream;

  /// Arranca el servicio y espera la confirmación nativa de que está
  /// corriendo antes de devolver el control — recién ahí tiene sentido
  /// llamar [anunciarse] o [buscarPeers].
  Future<void> iniciar({required String nombreDispositivo}) async {
    final listo = Completer<void>();

    await _nearbyService.init(
      serviceType: tipoDeServicio,
      strategy: Strategy.P2P_STAR, // un líder (hub) + varios seguidores
      deviceName: nombreDispositivo,
      callback: (bool corriendo) {
        if (!listo.isCompleted) listo.complete();
      },
    );
    await listo.future;

    _estadoSubscription = _nearbyService.stateChangedSubscription(
      callback: (dispositivosEncontrados) {
        _dispositivosController.add(dispositivosEncontrados);
      },
    );

    _mensajeSubscription = _nearbyService.dataReceivedSubscription(
      callback: (data) => _mensajesController.add(_comoTexto(data)),
    );
  }

  Future<void> anunciarse() async => await _nearbyService.startAdvertisingPeer();

  Future<void> buscarPeers() async => await _nearbyService.startBrowsingForPeers();

  Future<void> conectarA(Device dispositivo) async => await _nearbyService.invitePeer(
        deviceID: dispositivo.deviceId,
        deviceName: dispositivo.deviceName,
      );

  Future<void> enviar(String deviceId, String mensaje) async =>
      await _nearbyService.sendMessage(deviceId, mensaje);

  static String _comoTexto(dynamic data) =>
      data is String ? data : data.toString();

  Future<void> detener() async {
    await _estadoSubscription?.cancel();
    await _mensajeSubscription?.cancel();
    await _nearbyService.stopAdvertisingPeer();
    await _nearbyService.stopBrowsingForPeers();
    await _dispositivosController.close();
    await _mensajesController.close();
  }
}
