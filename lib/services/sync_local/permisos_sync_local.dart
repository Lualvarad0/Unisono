import 'package:permission_handler/permission_handler.dart';

/// Pide en tiempo de ejecución los permisos que Nearby Connections necesita
/// en Android. Sin esto, `startAdvertisingPeer`/`startBrowsingForPeers`
/// fallan en silencio o no encuentran nada — es la causa más común de "no
/// anda" reportada con este paquete. `locationWhenInUse` sigue haciendo
/// falta para que el scan de Bluetooth funcione, aunque el manifest ya
/// declare los permisos granulares de Android 12+.
Future<bool> pedirPermisosSyncLocal() async {
  final resultados = await [
    Permission.bluetoothScan,
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ].request();

  return resultados.values.every(
    (estado) => estado.isGranted || estado.isLimited,
  );
}
