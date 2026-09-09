import 'package:flutter/material.dart';

/// Perfil → Acerca de Unísono. Versión fija en "v1" a propósito: todavía
/// no hubo un primer lanzamiento formal (no hay tiendas ni versiones
/// previas que distinguir todavía), así que no hace falta leerla del
/// `pubspec.yaml` — cuando eso cambie, esta pantalla es el único lugar a
/// tocar.
class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: tema.colorScheme.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.graphic_eq_rounded,
                color: tema.colorScheme.onPrimary,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Unísono', style: tema.textTheme.headlineSmall),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'v1',
              style: tema.textTheme.bodyMedium
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cuando varias voces suenan como una sola. App offline-first '
            'para equipos de alabanza: letra, acordes y tonalidades '
            'sincronizados entre celulares, con o sin conexión a internet.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyMedium
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
