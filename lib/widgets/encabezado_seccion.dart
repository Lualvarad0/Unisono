import 'package:flutter/material.dart';

/// Encabezado de sección chico, en mayúsculas — mismo estilo que
/// "RECIENTES"/"PRÓXIMO SERVICIO" en Home, para que el mismo patrón
/// visual signifique lo mismo ("acá empieza un grupo nuevo de campos")
/// en toda la app: formularios largos sin ninguna separación visual son
/// justo lo que hacía difícil de entender "Nueva alabanza" antes de esto.
class EncabezadoSeccion extends StatelessWidget {
  const EncabezadoSeccion(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Text(
      texto,
      style: tema.textTheme.labelLarge?.copyWith(
        color: tema.colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
