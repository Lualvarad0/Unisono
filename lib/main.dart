import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:app_alabanzas/app.dart';

/// `Firebase.initializeApp()` se mueve a `AppAlabanzas` (ver `app.dart`):
/// así el primer frame se pinta de inmediato con nuestra propia pantalla
/// de carga en vez de una pantalla blanca mientras se espera el `await`
/// acá arriba, y una falla de red o de configuración termina en un botón
/// "Reintentar" en vez de un crash antes de que exista una sola pantalla.
///
/// `runZonedGuarded` + `FlutterError.onError` son la red de seguridad
/// contra lo que se nos escape: sin esto, un error no capturado en
/// cualquier parte de la app (una excepción async fuera del árbol de
/// widgets, por ejemplo) puede tirar abajo toda la app en vivo, en medio
/// de un servicio — con esto, al menos queda registrado y no se lleva
/// puesto el proceso entero.
void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) debugPrint('Error no controlado: ${details.exceptionAsString()}');
  };

  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const AppAlabanzas());
    },
    (error, stack) {
      if (kDebugMode) debugPrint('Error fuera del árbol de widgets: $error');
    },
  );
}
