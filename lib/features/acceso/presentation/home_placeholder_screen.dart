import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/services/autenticacion_service.dart';

/// Placeholder TEMPORAL: la sesión ya está lista (cuenta creada, perfil de
/// Miembro vinculado), pero el Home real (pantallas 6-13, "Preparación")
/// todavía no se construyó. Esto solo confirma que todo el flujo de
/// Acceso funciona de punta a punta — se reemplaza en esa próxima ronda.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.read<AutenticacionService>().usuarioActual;
    return Scaffold(
      appBar: AppBar(title: const Text('Unísono')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Sesión iniciada como\n${usuario?.email ?? ''}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '(Acá va el Home real — Repertorio, Setlists, Modo en '
                'vivo — todavía no construido)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () =>
                    context.read<AutenticacionService>().cerrarSesion(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
