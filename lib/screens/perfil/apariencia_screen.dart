import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/services/preferencias_service.dart';
import 'package:app_alabanzas/widgets/encabezado_seccion.dart';
import 'package:app_alabanzas/widgets/selector_segmentado.dart';

/// Perfil → Apariencia: tema, tamaño de letra de Vista en vivo, y dos
/// preferencias de lectura en el escenario. Cada cambio se guarda al
/// toque — no hay botón "Guardar" porque no hay nada que confirmar, el
/// valor elegido ya es el final (mismo criterio que los `ChoiceChip` que
/// reemplaza en otros formularios).
class AparienciaScreen extends StatelessWidget {
  const AparienciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferencias = context.watch<PreferenciasService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Apariencia')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const EncabezadoSeccion('TEMA'),
          const SizedBox(height: 12),
          SelectorSegmentado<ThemeMode>(
            opciones: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
            etiqueta: (modo) => switch (modo) {
              ThemeMode.system => 'Sistema',
              ThemeMode.light => 'Claro',
              ThemeMode.dark => 'Oscuro',
            },
            valor: preferencias.temaModo,
            onCambiar: preferencias.cambiarTema,
          ),
          const SizedBox(height: 28),
          const EncabezadoSeccion('TAMAÑO DE LETRA'),
          const SizedBox(height: 12),
          SelectorSegmentado<TamanoLetra>(
            opciones: TamanoLetra.values,
            etiqueta: (tamano) => tamano.etiqueta,
            valor: preferencias.tamanoLetra,
            onCambiar: preferencias.cambiarTamanoLetra,
          ),
          const SizedBox(height: 16),
          _MuestraEnVivo(
            tamano: preferencias.tamanoLetra,
            mostrarAcordes: preferencias.mostrarAcordes,
          ),
          const Divider(height: 44),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mostrar acordes'),
            subtitle: const Text('Vista del músico'),
            value: preferencias.mostrarAcordes,
            onChanged: preferencias.cambiarMostrarAcordes,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mantener pantalla encendida'),
            subtitle: const Text('Solo durante el modo en vivo'),
            value: preferencias.mantenerPantallaEncendida,
            onChanged: preferencias.cambiarMantenerPantallaEncendida,
          ),
        ],
      ),
    );
  }
}

class _MuestraEnVivo extends StatelessWidget {
  const _MuestraEnVivo({required this.tamano, required this.mostrarAcordes});

  final TamanoLetra tamano;
  final bool mostrarAcordes;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MUESTRA EN VIVO',
            style: tema.textTheme.labelSmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          if (mostrarAcordes)
            Text(
              'G',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: tema.colorScheme.primary,
              ),
            ),
          Text(
            'Toda la tierra se inclina',
            style: TextStyle(fontSize: tamano.tamanoBaseLetra, height: 1.3),
          ),
        ],
      ),
    );
  }
}
