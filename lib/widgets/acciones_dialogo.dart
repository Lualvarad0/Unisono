import 'package:flutter/material.dart';

/// Las dos acciones de un diálogo, del mismo tamaño — a propósito distinto
/// del patrón Material típico (`TextButton` + `FilledButton`), donde la
/// opción secundaria queda visualmente más chica/discreta que la
/// principal. Acá las dos pesan igual: quien lee el diálogo elige entre
/// dos opciones reales, no entre "la obvia" y "la de escape".
class AccionesDialogo extends StatelessWidget {
  const AccionesDialogo({
    super.key,
    required this.textoSecundario,
    required this.onSecundario,
    required this.textoPrimario,
    required this.onPrimario,
  });

  /// La opción de cerrar sin confirmar (ej. "Cancelar", "Seguir editando").
  final String textoSecundario;
  final VoidCallback? onSecundario;

  /// La opción que confirma la acción del diálogo.
  final String textoPrimario;
  final VoidCallback? onPrimario;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onSecundario,
            child: Text(textoSecundario),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onPrimario,
            child: Text(textoPrimario),
          ),
        ),
      ],
    );
  }
}
