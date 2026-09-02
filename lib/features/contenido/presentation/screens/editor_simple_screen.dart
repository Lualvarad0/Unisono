import 'package:flutter/material.dart';

import '../../domain/chordpro/chordpro_modelo.dart';
import '../../domain/chordpro/chordpro_parser.dart';
import '../../domain/chordpro/editor_simple.dart';
import '../widgets/linea_chordpro_widget.dart';

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

/// Pantalla 10 (rediseñada): cargar la letra y los acordes de una alabanza
/// sin que haga falta saber ChordPro. Por cada línea de la canción se
/// piden dos cosas nada más — dónde van los acordes y qué dice la letra
/// — igual que cualquiera ya escribiría una hoja de acordes a mano:
///
/// ```
/// G       D
/// Toda la tierra se inclina
/// ```
///
/// Acepta cifrado americano (C, D, Em) o español (Do, Re, Mim) en la
/// misma entrada — `Acorde.parse` reconoce los dos. La conversión al
/// modelo interno la hace `EditorSimpleConversor`; esta pantalla solo
/// junta los datos y arma la vista previa.
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
              l.acordesController.text.trim().isNotEmpty ||
              l.letraController.text.trim().isNotEmpty)
          .map(
            (l) => EditorSimpleConversor.aLinea(
              l.acordesController.text,
              l.letraController.text,
            ),
          )
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
            'Escribí los acordes arriba, alineados sobre la sílaba donde '
            'cambian — como en cualquier hoja de acordes.',
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: linea.acordesController,
                  style: _estiloMono,
                  decoration: const InputDecoration(
                    labelText: 'Acordes (opcional)',
                    hintText: 'G       D',
                    isDense: true,
                  ),
                  onChanged: (_) => onCambiar(),
                ),
                const SizedBox(height: 4),
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
  _LineaEditable({String acordes = '', String letra = ''})
      : acordesController = TextEditingController(text: acordes),
        letraController = TextEditingController(text: letra);

  final TextEditingController acordesController;
  final TextEditingController letraController;

  void dispose() {
    acordesController.dispose();
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
      final texto = EditorSimpleConversor.desdeLinea(linea);
      return _LineaEditable(acordes: texto.acordes, letra: texto.letra);
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
