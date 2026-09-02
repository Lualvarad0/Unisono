import 'package:flutter/material.dart';

const _escalaCromatica = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', //
];

/// Pantalla 11 del diseño original ("Detectar tonalidad") usa el
/// micrófono para escuchar el instrumento y adivinar la tonalidad —
/// detección de tono en tiempo real por audio, que es un motor de
/// procesamiento de señal aparte, no una pantalla más.
///
/// Esta versión es un selector manual con la misma forma visual (grilla
/// de tonalidades), sin fingir que escucha nada. Mostrar una "confianza
/// alta" sin haber analizado audio de verdad sería una UI que miente —
/// mejor dejar la detección real como una mejora futura documentada, y
/// mientras tanto que elegir el tono a mano sea rápido y claro.
class DetectarTonalidadScreen extends StatelessWidget {
  const DetectarTonalidadScreen({super.key, this.tonoSugerido});

  final String? tonoSugerido;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir tonalidad')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La detección automática por micrófono todavía no está '
              'implementada — elegí el tono a mano por ahora.',
              style: tema.textTheme.bodyMedium
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final nota in _escalaCromatica)
                  ChoiceChip(
                    label: Text(nota),
                    selected: nota == tonoSugerido,
                    onSelected: (_) => Navigator.of(context).pop(nota),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
