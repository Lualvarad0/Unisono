import 'package:flutter/material.dart';

/// Chip de género con el color de ese género (ver `colorDeGenero`) en vez
/// del gris genérico de `ChoiceChip` — mismo lenguaje de color que los
/// cuadros de "Explorar por género" en Repertorio, para que un género se
/// reconozca por su color en cualquier pantalla donde aparezca.
class ChipGenero extends StatelessWidget {
  const ChipGenero({
    super.key,
    required this.nombre,
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  final String nombre;
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: seleccionado ? color : color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: seleccionado ? null : Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          nombre,
          style: TextStyle(
            color: seleccionado ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
