import 'package:flutter/material.dart';

import 'package:app_alabanzas/models/chordpro/chordpro_modelo.dart';
import 'package:app_alabanzas/services/chordpro/chordpro_parser.dart';
import 'package:app_alabanzas/services/chordpro/editor_simple.dart';
import 'package:app_alabanzas/widgets/acciones_dialogo.dart';
import 'package:app_alabanzas/widgets/linea_chordpro_widget.dart';

/// Nombre para mostrar en el selector de tipo y etiqueta por defecto
/// cuando el usuario no escribe una propia (ej. "Verso" a secas, sin el
/// "1" — eso lo agrega quien carga la canción si tiene varios versos).
const _nombreTipo = {
  TipoSeccion.verso: 'Verso',
  TipoSeccion.coro: 'Coro',
  TipoSeccion.puente: 'Puente',
  TipoSeccion.tag: 'Tag',
  TipoSeccion.otra: 'Verso',
};

/// Pantalla 10 (rediseñada de nuevo): se escribe la letra de cada línea
/// una sola vez y los acordes se ubican tocando arriba de la palabra que
/// corresponde — nada de dos cajas de texto paralelas para alinear a
/// mano por espacios. Igual que cualquiera escribiría una hoja de
/// acordes:
///
/// ```
///     G       D
/// Toda la tierra se inclina
/// ```
///
/// pero acá el acorde se toca y se escribe en un diálogo chico, no se
/// cuentan espacios. Acepta cifrado americano (C, D, Em) o español (Do,
/// Re, Mim) — `Acorde.parse` reconoce los dos.
///
/// Devuelve el texto ChordPro final por `Navigator.pop<String>`, igual
/// que el editor anterior — el resto de la app no sabe ni le importa
/// cómo se cargó la canción.
class EditorSimpleScreen extends StatefulWidget {
  const EditorSimpleScreen({super.key, this.contenidoInicial = ''});

  final String contenidoInicial;

  @override
  State<EditorSimpleScreen> createState() => _EditorSimpleScreenState();
}

class _EditorSimpleScreenState extends State<EditorSimpleScreen> {
  final List<_SeccionEditable> _secciones = [];

  @override
  void initState() {
    super.initState();
    if (widget.contenidoInicial.trim().isNotEmpty) {
      final parseado = ChordProParser.parse(widget.contenidoInicial);
      for (final seccion in parseado.secciones) {
        _secciones.add(_SeccionEditable.desde(seccion));
      }
    }
    if (_secciones.isEmpty) {
      _secciones.add(_SeccionEditable(tipo: TipoSeccion.verso, etiqueta: 'Verso 1'));
    }
  }

  @override
  void dispose() {
    for (final s in _secciones) {
      s.dispose();
    }
    super.dispose();
  }

  void _agregarSeccion(TipoSeccion tipo) {
    setState(() {
      _secciones.add(_SeccionEditable(tipo: tipo, etiqueta: _nombreTipo[tipo]!));
    });
  }

  void _quitarSeccion(_SeccionEditable seccion) {
    setState(() {
      seccion.dispose();
      _secciones.remove(seccion);
    });
  }

  Future<void> _elegirTipoNuevaSeccion() async {
    final tipo = await showModalBottomSheet<TipoSeccion>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final tipo in TipoSeccion.values.where((t) => t != TipoSeccion.otra))
              ListTile(
                title: Text(_nombreTipo[tipo]!),
                onTap: () => Navigator.of(context).pop(tipo),
              ),
          ],
        ),
      ),
    );
    if (tipo != null) _agregarSeccion(tipo);
  }

  CancionChordPro _construir() {
    final secciones = <SeccionChordPro>[];
    for (final s in _secciones) {
      final lineas = s.lineas
          .where((l) =>
              l.acordesPorPosicion.isNotEmpty || l.letraController.text.trim().isNotEmpty)
          .map((l) => EditorSimpleConversor.aLinea(
                _lineaAcordesDesdePosiciones(l.acordesPorPosicion),
                l.letraController.text,
              ))
          .toList();
      if (lineas.isEmpty) continue;
      final etiqueta = s.etiquetaController.text.trim();
      secciones.add(
        SeccionChordPro(
          tipo: s.tipo,
          etiqueta: etiqueta.isEmpty ? _nombreTipo[s.tipo]! : etiqueta,
          lineas: lineas,
        ),
      );
    }
    return CancionChordPro(secciones: secciones);
  }

  void _confirmar() {
    Navigator.of(context).pop(_construir().toChordPro());
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final vistaPrevia = _construir();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Letra y acordes'),
        actions: [
          TextButton(onPressed: _confirmar, child: const Text('Listo')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Escribí la letra de cada línea y tocá arriba de una palabra '
            'para ponerle un acorde.',
            style: tema.textTheme.bodySmall
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (final seccion in _secciones)
            _SeccionEditor(
              key: ObjectKey(seccion),
              seccion: seccion,
              onCambiar: () => setState(() {}),
              onQuitar: _secciones.length > 1 ? () => _quitarSeccion(seccion) : null,
            ),
          OutlinedButton.icon(
            onPressed: _elegirTipoNuevaSeccion,
            icon: const Icon(Icons.add),
            label: const Text('Agregar sección'),
          ),
          if (vistaPrevia.secciones.isNotEmpty) ...[
            const Divider(height: 40),
            Text(
              'VISTA PREVIA',
              style: tema.textTheme.labelLarge
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            for (final seccion in vistaPrevia.secciones) ...[
              Text(
                seccion.etiqueta.toUpperCase(),
                style: tema.textTheme.labelLarge?.copyWith(
                  color: tema.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final linea in seccion.lineas) LineaChordProWidget(linea: linea),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

/// Arma la misma "línea de acordes alineada por espacios" que ya sabía
/// leer `EditorSimpleConversor.aLinea` — así la construcción del
/// `LineaChordPro` final sigue siendo ese único camino ya probado
/// (`editor_simple_test.dart`), en vez de reimplementar la lógica de
/// segmentos acá con las posiciones tocadas en pantalla.
String _lineaAcordesDesdePosiciones(Map<int, String> posiciones) {
  final entradas = posiciones.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  final buffer = StringBuffer();
  for (final entrada in entradas) {
    while (buffer.length < entrada.key) {
      buffer.write(' ');
    }
    buffer.write(entrada.value);
  }
  return buffer.toString();
}

class _SeccionEditor extends StatelessWidget {
  const _SeccionEditor({
    super.key,
    required this.seccion,
    required this.onCambiar,
    required this.onQuitar,
  });

  final _SeccionEditable seccion;
  final VoidCallback onCambiar;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TipoSeccion>(
                    initialValue: seccion.tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: [
                      for (final tipo
                          in TipoSeccion.values.where((t) => t != TipoSeccion.otra))
                        DropdownMenuItem(value: tipo, child: Text(_nombreTipo[tipo]!)),
                    ],
                    onChanged: (tipo) {
                      if (tipo != null) {
                        seccion.tipo = tipo;
                        onCambiar();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: seccion.etiquetaController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    onChanged: (_) => onCambiar(),
                  ),
                ),
                if (onQuitar != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Quitar sección',
                    onPressed: onQuitar,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final linea in seccion.lineas)
              _LineaEditor(
                key: ObjectKey(linea),
                linea: linea,
                onCambiar: onCambiar,
                onQuitar: seccion.lineas.length > 1
                    ? () {
                        linea.dispose();
                        seccion.lineas.remove(linea);
                        onCambiar();
                      }
                    : null,
              ),
            TextButton.icon(
              onPressed: () {
                seccion.lineas.add(_LineaEditable());
                onCambiar();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar línea'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineaEditor extends StatelessWidget {
  const _LineaEditor({
    super.key,
    required this.linea,
    required this.onCambiar,
    required this.onQuitar,
  });

  final _LineaEditable linea;
  final VoidCallback onCambiar;
  final VoidCallback? onQuitar;

  static const _estiloMono = TextStyle(fontFamily: 'monospace', fontSize: 15);

  List<({int inicio, String palabra})> _palabras() => [
        for (final m in RegExp(r'\S+').allMatches(linea.letraController.text))
          (inicio: m.start, palabra: m.group(0)!),
      ];

  Future<void> _editarAcorde(BuildContext context, int posicion) async {
    final tema = Theme.of(context);
    final actual = linea.acordesPorPosicion[posicion];
    final controller = TextEditingController(text: actual ?? '');
    final resultado = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Acorde'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: _estiloMono,
          decoration: const InputDecoration(
            labelText: 'Acorde',
            hintText: 'Ej. G, Em7, D/F#',
          ),
        ),
        actions: [
          if (actual != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(''),
                  style: TextButton.styleFrom(
                    foregroundColor: tema.colorScheme.error,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text('Quitar acorde'),
                ),
              ),
            ),
          AccionesDialogo(
            textoSecundario: 'Cancelar',
            onSecundario: () => Navigator.of(context).pop(),
            textoPrimario: 'Guardar',
            onPrimario: () => Navigator.of(context).pop(controller.text.trim()),
          ),
        ],
      ),
    );
    controller.dispose();
    if (resultado == null) return;
    if (resultado.isEmpty) {
      linea.acordesPorPosicion.remove(posicion);
    } else {
      linea.acordesPorPosicion[posicion] = resultado;
    }
    onCambiar();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final palabras = _palabras();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: linea.letraController,
                  style: _estiloMono,
                  decoration: const InputDecoration(
                    labelText: 'Letra',
                    hintText: 'Toda la tierra se inclina',
                    isDense: true,
                  ),
                  onChanged: (_) => onCambiar(),
                ),
                const SizedBox(height: 6),
                if (palabras.isEmpty)
                  TextButton.icon(
                    onPressed: () => _editarAcorde(context, 0),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Acorde (línea instrumental)'),
                  )
                else
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      for (final palabra in palabras)
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => _editarAcorde(context, palabra.inicio),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 18,
                                  child: linea.acordesPorPosicion[palabra.inicio] != null
                                      ? Text(
                                          linea.acordesPorPosicion[palabra.inicio]!,
                                          style: _estiloMono.copyWith(
                                            color: tema.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : Icon(
                                          Icons.add,
                                          size: 14,
                                          color: tema.colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.4),
                                        ),
                                ),
                                Text(palabra.palabra, style: _estiloMono),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (onQuitar != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              tooltip: 'Quitar línea',
              onPressed: onQuitar,
            ),
        ],
      ),
    );
  }
}

class _LineaEditable {
  _LineaEditable({String letra = '', Map<int, String>? acordesPorPosicion})
      : letraController = TextEditingController(text: letra),
        acordesPorPosicion = acordesPorPosicion ?? {};

  final TextEditingController letraController;

  /// Posición de caracter dentro de `letraController.text` -> texto del
  /// acorde que va arriba de esa palabra. Se toca la palabra para
  /// editarlo — ver `_LineaEditor._editarAcorde`.
  final Map<int, String> acordesPorPosicion;

  void dispose() {
    letraController.dispose();
  }
}

class _SeccionEditable {
  _SeccionEditable({required this.tipo, required String etiqueta})
      : etiquetaController = TextEditingController(text: etiqueta),
        lineas = [_LineaEditable()];

  _SeccionEditable._cargada(this.tipo, this.etiquetaController, this.lineas);

  factory _SeccionEditable.desde(SeccionChordPro seccion) {
    final tipo = seccion.tipo == TipoSeccion.otra ? TipoSeccion.verso : seccion.tipo;
    final lineas = seccion.lineas.map((linea) {
      // Reusa la conversión ya probada (línea de acordes alineada por
      // espacios) y de ahí saca las posiciones de caracter — evita
      // reimplementar la lógica de "dónde cae cada acorde" acá.
      final texto = EditorSimpleConversor.desdeLinea(linea);
      final posiciones = <int, String>{
        for (final m in RegExp(r'\S+').allMatches(texto.acordes))
          m.start.clamp(0, texto.letra.length): m.group(0)!,
      };
      return _LineaEditable(letra: texto.letra, acordesPorPosicion: posiciones);
    }).toList();
    if (lineas.isEmpty) lineas.add(_LineaEditable());
    return _SeccionEditable._cargada(
      tipo,
      TextEditingController(text: seccion.etiqueta),
      lineas,
    );
  }

  TipoSeccion tipo;
  final TextEditingController etiquetaController;
  final List<_LineaEditable> lineas;

  void dispose() {
    etiquetaController.dispose();
    for (final l in lineas) {
      l.dispose();
    }
  }
}
