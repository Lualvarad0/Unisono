import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Escucha el enlace de invitación (`https://app-alabanzas.web.app/invitar/<id>`,
/// ver AndroidManifest.xml) tanto si la app arranca desde cero por ese link
/// (`getInitialAppLink`) como si llega con la app ya abierta
/// (`uriLinkStream`), y expone el id del `Miembro` invitado pendiente de
/// confirmar. `SeleccionRolScreen` lo consume para saltar directo a
/// "¿Sos vos?" en vez de la lista completa del equipo.
class InviteLinkService extends ChangeNotifier {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _suscripcion;

  String? _miembroIdPendiente;
  String? get miembroIdPendiente => _miembroIdPendiente;

  Future<void> iniciar() async {
    try {
      final inicial = await _appLinks.getInitialLink();
      if (inicial != null) _procesar(inicial);
    } catch (_) {
      // Sin link inicial o plataforma sin soporte (ej. tests) — no es un
      // error real, la app sigue el flujo normal sin invitación.
    }
    _suscripcion = _appLinks.uriLinkStream.listen(_procesar);
  }

  void _procesar(Uri uri) {
    final segmentos = uri.pathSegments;
    final indice = segmentos.indexOf('invitar');
    if (indice == -1 || indice + 1 >= segmentos.length) return;
    final id = segmentos[indice + 1];
    if (id.isEmpty) return;
    _miembroIdPendiente = id;
    notifyListeners();
  }

  /// Se llama al confirmar la invitación o al elegir "No soy yo" — en
  /// ambos casos deja de haber una invitación pendiente que mostrar.
  void limpiar() {
    if (_miembroIdPendiente == null) return;
    _miembroIdPendiente = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}
