import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:app_alabanzas/repositories/miembro_repository.dart';

/// Notificaciones push. Quién las manda de verdad son las Cloud
/// Functions (carpeta `functions/`, se despliegan aparte) — esto solo
/// hace la parte del celular:
///
/// 1. Pide permiso (Android 13+ lo necesita en tiempo de ejecución).
/// 2. Guarda el token de este dispositivo en el `Miembro` de quien
///    inició sesión — las Cloud Functions lo leen de ahí para saber a
///    qué dispositivo mandarle cada aviso.
/// 3. Mientras la app está *abierta*, FCM no pinta nada solo — a
///    diferencia de segundo plano o cerrada, donde el sistema operativo
///    ya lo hace por su cuenta. Acá se muestra a mano con
///    `flutter_local_notifications` para que se vea igual en los tres
///    casos.
class NotificacionesService {
  NotificacionesService(this._miembroRepository);

  final MiembroRepository _miembroRepository;
  final _notificacionesLocales = FlutterLocalNotificationsPlugin();

  static const _canalId = 'avisos_unisono';
  static const _canalNombre = 'Avisos de Unísono';
  static const _canalDescripcion =
      'Setlists, canciones asignadas, y cuando el equipo se conecta en vivo.';

  bool _inicializado = false;

  /// Se llama una vez por sesión, apenas hay alguien logueado (ver
  /// `PrincipalShellScreen`) — antes de eso no hay a qué `Miembro`
  /// guardarle el token.
  Future<void> inicializar(String uid) async {
    if (_inicializado) return;
    _inicializado = true;

    await _configurarCanalAndroid();

    final permiso = await FirebaseMessaging.instance.requestPermission();
    if (permiso.authorizationStatus == AuthorizationStatus.denied) return;

    await _guardarToken(uid);
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => _guardarToken(uid));
    FirebaseMessaging.onMessage.listen(_mostrarNotificacionLocal);
  }

  Future<void> _guardarToken(String uid) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    final miembro = await _miembroRepository.buscarPorUid(uid);
    if (miembro == null || miembro.fcmToken == token) return;
    await _miembroRepository.actualizar(miembro.id, miembro.copyWith(fcmToken: token));
  }

  Future<void> _configurarCanalAndroid() async {
    await _notificacionesLocales.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _notificacionesLocales
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _canalId,
            _canalNombre,
            description: _canalDescripcion,
            importance: Importance.high,
          ),
        );
  }

  Future<void> _mostrarNotificacionLocal(RemoteMessage mensaje) async {
    final notificacion = mensaje.notification;
    if (notificacion == null) return;
    await _notificacionesLocales.show(
      notificacion.hashCode,
      notificacion.title,
      notificacion.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          _canalNombre,
          channelDescription: _canalDescripcion,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
