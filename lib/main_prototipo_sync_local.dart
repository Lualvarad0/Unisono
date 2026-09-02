import 'package:flutter/material.dart';

import 'package:app_alabanzas/screens/sync_local/prototipo_lider_screen.dart';
import 'package:app_alabanzas/screens/sync_local/prototipo_seguidor_screen.dart';

/// Punto de entrada SEPARADO del de la app real (`lib/main.dart`).
///
/// Corré esto con:
///   flutter run -t lib/main_prototipo_sync_local.dart
///
/// Es el prototipo aislado del Paso 4: no usa Firebase, no usa Provider, no
/// toca nada del resto de la app — solo valida que la sincronización P2P
/// (Nearby Connections/Multipeer) funciona de verdad entre dos celulares
/// reales, antes de conectarla al estado real de la app en el Paso 5.
///
/// Necesita DOS dispositivos físicos (no funciona en emulador): uno abre
/// esto y elige "Soy el líder", el otro "Soy el seguidor".
void main() {
  runApp(const _AppPrototipoSyncLocal());
}

class _AppPrototipoSyncLocal extends StatelessWidget {
  const _AppPrototipoSyncLocal();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Prototipo Sync Local',
      debugShowCheckedModeBanner: false,
      home: _SeleccionRolScreen(),
    );
  }
}

class _SeleccionRolScreen extends StatelessWidget {
  const _SeleccionRolScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prototipo Paso 4 — Sync Local')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Elegí un rol para este celular.\n'
                'Usá dos celulares reales, uno con cada rol.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrototipoLiderScreen(),
                  ),
                ),
                child: const Text('Soy el líder'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrototipoSeguidorScreen(),
                  ),
                ),
                child: const Text('Soy el seguidor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
