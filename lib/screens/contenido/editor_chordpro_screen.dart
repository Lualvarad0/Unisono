import 'package:flutter/material.dart';

import 'package:app_alabanzas/services/chordpro/chordpro_parser.dart';

/// Pantalla 10: editor de texto crudo en formato ChordPro, con
/// previsualización en vivo usando el mismo parser del Paso 3 — lo que se
/// ve acá es exactamente lo que va a mostrar la Vista Músico/Cantante más
/// adelante.
///
/// Devuelve el texto final por `Navigator.pop<String>` cuando se confirma.
class EditorChordProScreen extends StatefulWidget {
  const EditorChordProScreen({super.key, this.contenidoInicial = ''});

  final String contenidoInicial;

  @override
  State<EditorChordProScreen> createState() => _EditorChordProScreenState();
}

class _EditorChordProScreenState extends State<EditorChordProScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.contenidoInicial)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cancionParseada = ChordProParser.parse(_controller.text);
    final secciones = cancionParseada.secciones;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor ChordPro'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('Listo'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Las directivas de sección se convierten en secciones '
              'navegables: {start_of_verse: Verso 1} ... {end_of_verse}, '
              '{start_of_chorus} ... {end_of_chorus}. Acordes entre '
              'corchetes: [G]como esto.',
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '{title: ...}\n{key: G}\n\n'
                      '{start_of_verse: Verso 1}\n[G]Letra de ejemplo\n'
                      '{end_of_verse}',
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PREVISUALIZACIÓN',
                  style: tema.textTheme.labelLarge
                      ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                ),
                Text(
                  '${secciones.length} secciones · sin errores',
                  style: tema.textTheme.bodySmall
                      ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: secciones.isEmpty
                ? Center(
                    child: Text(
                      'Escribí algo para ver la vista previa.',
                      style: tema.textTheme.bodySmall,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Text(
                        secciones.first.etiqueta.toUpperCase(),
                        style: tema.textTheme.labelLarge?.copyWith(
                          color: tema.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      for (final linea in secciones.first.lineas)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: RichText(
                            text: TextSpan(
                              style: tema.textTheme.bodyMedium
                                  ?.copyWith(color: tema.colorScheme.onSurface),
                              children: [
                                for (final segmento in linea.segmentos) ...[
                                  if (segmento.acorde != null)
                                    TextSpan(
                                      text: '[${segmento.acorde}]',
                                      style: TextStyle(
                                        color: tema.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  TextSpan(text: segmento.letra),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
