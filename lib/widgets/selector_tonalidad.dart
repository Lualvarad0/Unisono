import 'package:flutter/material.dart';

/// Pastilla "− G +" para transportar de a un semitono — reemplaza tanto
/// la grilla de 12 notas de `DetalleAlabanzaScreen` como el stepper de
/// ancho completo de `_DialogoEntradaSetlist`, un solo control en toda
/// la app para "subir/bajar el tono".
///
/// Cada toque mueve un semitono (medio tono) nada más — no hay un botón
/// aparte para "un tono entero": tocar dos veces ya cubre eso, y
/// mantenerlo así de simple evita cuatro botones donde alcanza con dos.
class SelectorTonalidad extends StatelessWidget {
  const SelectorTonalidad({
    super.key,
    required this.tono,
    required this.onBajar,
    required this.onSubir,
  });

  final String tono;
  final VoidCallback onBajar;
  final VoidCallback onSubir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BotonTono(icon: Icons.remove, onPressed: onBajar, tooltip: 'Bajar medio tono'),
          SizedBox(
            width: 40,
            child: Text(
              tono,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleMedium?.copyWith(
                color: tema.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _BotonTono(icon: Icons.add, onPressed: onSubir, tooltip: 'Subir medio tono'),
        ],
      ),
    );
  }
}

class _BotonTono extends StatelessWidget {
  const _BotonTono({required this.icon, required this.onPressed, required this.tooltip});

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: tema.colorScheme.surfaceContainer,
        minimumSize: const Size(36, 36),
        shape: const CircleBorder(),
      ),
    );
  }
}
