import 'package:flutter/material.dart';

import 'package:app_alabanzas/models/chordpro/chordpro_modelo.dart';
import 'package:app_alabanzas/services/chordpro/chordpro_parser.dart';
import 'package:app_alabanzas/services/chordpro/editor_simple.dart';
import 'package:app_alabanzas/widgets/linea_chordpro_widget.dart';

/// Nombre para mostrar en el selector de tipo. La etiqueta final de cada
/// sección (la que se guarda) no se escribe a mano — ver
/// `_EditorSimpleScreenState._etiquetas`.
const _nombreTipo = {
  TipoSeccion.verso: 'Verso',
  TipoSeccion.preCoro: 'Pre-Coro',
  TipoSeccion.coro: 'Coro',
  TipoSeccion.puente: 'Puente',
  TipoSeccion.tag: 'Tag',
  TipoSeccion.otra: 'Verso',
};

/// Pantalla 10 (rediseñada otra vez, Paso de pulido): se escribe la letra
/// de cada línea y los acordes se ubican tocando arriba de la palabra que
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
/// Tres cosas que antes hacían esto lento y pedían volver a esta pantalla
/// se resolvieron acá:
/// - "Agregar sección" ya no abre un selector aparte — agrega la tarjeta
///   directo (el tipo se cambia ahí mismo) — ver `_agregarSeccion`.
/// - Cada línea se puede escribir de a una, pero también se puede pegar
///   un bloque entero de letra de un tirón — ver `_DialogoPegarLetra`.
/// - Los acordes de una misma línea se cargan sin cerrar el diálogo:
///   tocás la primera palabra y de ahí navegás con ‹ › o el "Siguiente"
///   del teclado — ver `_DialogoAcordesLinea`.
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
      _secciones.add(_SeccionEditable(tipo: TipoSeccion.verso));
    }
  }

  @override
  void dispose() {
    for (final s in _secciones) {
      s.dispose();
    }
    super.dispose();
  }

  /// Agrega la tarjeta directo, sin preguntar el tipo antes — es el paso
  /// que más se repite al cargar una canción, así que no amerita un
  /// selector aparte. El tipo que sugiere es "lo que suele seguir" (un
  /// Verso después de un Coro, Coro después de un Verso/Pre-Coro) y se
  /// puede cambiar al toque desde la tarjeta misma si no adivinó bien.
  void _agregarSeccion() {
    final ultimo = _secciones.isEmpty ? null : _secciones.last.tipo;
    final sugerido = switch (ultimo) {
      TipoSeccion.coro => TipoSeccion.verso,
      TipoSeccion.verso || TipoSeccion.preCoro => TipoSeccion.coro,
      _ => TipoSeccion.verso,
    };
    setState(() {
      _secciones.add(_SeccionEditable(tipo: sugerido));
    });
  }

  void _duplicarSeccion(_SeccionEditable seccion) {
    setState(() {
      final indice = _secciones.indexOf(seccion);
      _secciones.insert(indice + 1, _SeccionEditable.duplicadaDe(seccion));
    });
  }

  void _quitarSeccion(_SeccionEditable seccion) {
    setState(() {
      seccion.dispose();
      _secciones.remove(seccion);
    });
  }

  void _reordenarSecciones(int viejo, int nuevo) {
    // `onReorderItem` (a diferencia de `onReorder`, deprecado) ya entrega
    // `nuevo` ajustado por el hueco que deja sacar el elemento de
    // `viejo` — mismo criterio que ya usa el setlist de Actividad.
    setState(() {
      final seccion = _secciones.removeAt(viejo);
      _secciones.insert(nuevo, seccion);
    });
  }

  /// La etiqueta de cada sección no se escribe a mano: se arma sola a
  /// partir del tipo elegido y de cuántas secciones de ese mismo tipo ya
  /// vienen antes en la lista — la primera queda "Verso" a secas, la
  /// segunda "Verso 2", etc. Así alcanza con elegir el tipo (y, para una
  /// sección que se repite en la canción como un segundo coro, "Duplicar"
  /// o "Agregar sección" de nuevo — el número se acomoda solo.
  Map<_SeccionEditable, String> _etiquetas() {
    final conteoPorTipo = <TipoSeccion, int>{};
    final resultado = <_SeccionEditable, String>{};
    for (final s in _secciones) {
      final ocurrencia = (conteoPorTipo[s.tipo] ?? 0) + 1;
      conteoPorTipo[s.tipo] = ocurrencia;
      resultado[s] =
          ocurrencia == 1 ? _nombreTipo[s.tipo]! : '${_nombreTipo[s.tipo]} $ocurrencia';
    }
    return resultado;
  }

  CancionChordPro _construir() {
    final etiquetas = _etiquetas();
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
      final tono = s.tonoController.text.trim();
      secciones.add(
        SeccionChordPro(
          tipo: s.tipo,
          etiqueta: etiquetas[s]!,
          lineas: lineas,
          tonoBase: tono.isEmpty ? null : tono,
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
    final etiquetas = _etiquetas();

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
            'Escribí (o pegá) la letra y tocá arriba de una palabra para '
            'ponerle un acorde.',
            style: tema.textTheme.bodySmall
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _secciones.length,
            onReorderItem: _reordenarSecciones,
            itemBuilder: (context, i) {
              final seccion = _secciones[i];
              return _SeccionEditor(
                key: ObjectKey(seccion),
                indice: i,
                seccion: seccion,
                etiqueta: etiquetas[seccion]!,
                onCambiar: () => setState(() {}),
                onDuplicar: () => _duplicarSeccion(seccion),
                onQuitar: _secciones.length > 1 ? () => _quitarSeccion(seccion) : null,
              );
            },
          ),
          OutlinedButton.icon(
            onPressed: _agregarSeccion,
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
              Row(
                children: [
                  Text(
                    seccion.etiqueta.toUpperCase(),
                    style: tema.textTheme.labelLarge?.copyWith(
                      color: tema.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (seccion.tonoBase != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Tono ${seccion.tonoBase}',
                      style: tema.textTheme.labelMedium
                          ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
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
    required this.indice,
    required this.seccion,
    required this.etiqueta,
    required this.onCambiar,
    required this.onDuplicar,
    required this.onQuitar,
  });

  /// Posición real dentro de `ReorderableListView` — el handle de
  /// arrastre lo necesita para saber qué ítem está moviendo.
  final int indice;
  final _SeccionEditable seccion;

  /// Se calcula sola a partir del tipo — ver
  /// `_EditorSimpleScreenState._etiquetas`. Es de solo lectura acá, no
  /// hay campo para escribirla a mano.
  final String etiqueta;
  final VoidCallback onCambiar;
  final VoidCallback onDuplicar;
  final VoidCallback? onQuitar;

  Future<void> _pegarLetra(BuildContext context) async {
    final lineas = await showDialog<List<String>>(
      context: context,
      builder: (_) => const _DialogoPegarLetra(),
    );
    if (lineas == null || lineas.isEmpty) return;
    // Si la sección todavía está vacía (el placeholder inicial sin tocar),
    // el bloque pegado la reemplaza en vez de sumarse después — si no,
    // cualquiera que pegue como primer paso terminaría con una línea en
    // blanco suelta arriba de todo.
    final estaVacia = seccion.lineas.length == 1 &&
        seccion.lineas.first.letraController.text.trim().isEmpty &&
        seccion.lineas.first.acordesPorPosicion.isEmpty;
    if (estaVacia) {
      seccion.lineas.first.dispose();
      seccion.lineas.clear();
    }
    for (final linea in lineas) {
      seccion.lineas.add(_LineaEditable(letra: linea));
    }
    onCambiar();
  }

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // El handle de arrastre (ReorderableListView) necesita un
                // ancestro Material con ink bien definido — un ícono fijo
                // acá, en vez de arrastrar desde cualquier punto de la
                // tarjeta, para no competir con los toques de los campos
                // de abajo.
                ReorderableDragStartListener(
                  index: indice,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14, right: 4),
                    child: Icon(
                      Icons.drag_handle,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<TipoSeccion>(
                    initialValue: seccion.tipo,
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      helperText: 'Se va a llamar "$etiqueta"',
                    ),
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
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: seccion.tonoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Tono',
                      hintText: 'Si cambia',
                    ),
                    onChanged: (_) => onCambiar(),
                  ),
                ),
                PopupMenuButton<void>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onDuplicar,
                      child: const ListTile(
                        leading: Icon(Icons.copy_outlined),
                        title: Text('Duplicar sección'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (onQuitar != null)
                      PopupMenuItem(
                        onTap: onQuitar,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error),
                          title: Text('Quitar sección',
                              style:
                                  TextStyle(color: Theme.of(context).colorScheme.error)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
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
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () {
                    seccion.lineas.add(_LineaEditable());
                    onCambiar();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar línea'),
                ),
                TextButton.icon(
                  onPressed: () => _pegarLetra(context),
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: const Text('Pegar letra'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pegar varias líneas de una sola vez — la alternativa rápida a tocar
/// "Agregar línea" una por una. Cada renglón del texto pegado se separa
/// por `\n`, igual que cualquier letra copiada de una Biblia, un
/// cancionero o un documento — los acordes se siguen poniendo después,
/// tocando cada palabra (ver `_DialogoAcordesLinea`), no acá: mezclar
/// "pegar letra" con sintaxis de acordes forzaría a aprender un formato,
/// justo lo que este editor evita.
class _DialogoPegarLetra extends StatefulWidget {
  const _DialogoPegarLetra();

  @override
  State<_DialogoPegarLetra> createState() => _DialogoPegarLetraState();
}

class _DialogoPegarLetraState extends State<_DialogoPegarLetra> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final lineas = _controller.text.split('\n');
    Navigator.of(context).pop(lineas);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pegar letra'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 8,
        minLines: 4,
        decoration: const InputDecoration(
          hintText: 'Pegá o escribí varias líneas — cada renglón nuevo '
              'queda como una línea separada.',
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: const Text('Agregar'),
        ),
      ],
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

  /// Abre el diálogo de acordes ya posicionado en `indiceInicial` — de
  /// ahí se puede seguir a cualquier otra palabra de la misma línea sin
  /// volver a tocar nada en la pantalla de atrás. Antes cada palabra
  /// abría y cerraba su propio diálogo — para una línea con 4 acordes
  /// eran 4 idas y vueltas en vez de una sola.
  Future<void> _editarAcordes(BuildContext context, int indiceInicial) async {
    final palabras = _palabras();
    if (palabras.isEmpty) {
      final resultado = await showDialog<String>(
        context: context,
        builder: (_) => _DialogoAcordeSuelto(
          valorInicial: linea.acordesPorPosicion[0],
        ),
      );
      if (resultado == null) return;
      if (resultado.isEmpty) {
        linea.acordesPorPosicion.remove(0);
      } else {
        linea.acordesPorPosicion[0] = resultado;
      }
      onCambiar();
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _DialogoAcordesLinea(
        palabras: palabras,
        indiceInicial: indiceInicial,
        acordesPorPosicion: linea.acordesPorPosicion,
        onCambiar: onCambiar,
      ),
    );
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
                const SizedBox(height: 8),
                // Fondo propio + etiqueta a propósito: sin esto, la fila de
                // palabras tocables de abajo se ve como la misma letra
                // repetida dos veces en vez de la zona para poner acordes.
                Text(
                  'ACORDES (tocá una palabra)',
                  style: tema.textTheme.labelSmall
                      ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: palabras.isEmpty
                      ? TextButton.icon(
                          onPressed: () => _editarAcordes(context, 0),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Acorde (línea instrumental)'),
                        )
                      : Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            for (var i = 0; i < palabras.length; i++)
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => _editarAcordes(context, i),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 18,
                                        child: linea.acordesPorPosicion[
                                                    palabras[i].inicio] !=
                                                null
                                            ? Text(
                                                linea.acordesPorPosicion[
                                                    palabras[i].inicio]!,
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
                                      Text(palabras[i].palabra, style: _estiloMono),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
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

/// Acorde para una línea instrumental (sin palabras) — caso puntual, no
/// necesita la navegación ‹ › de `_DialogoAcordesLinea`, que es para
/// recorrer varias palabras de la misma línea.
class _DialogoAcordeSuelto extends StatefulWidget {
  const _DialogoAcordeSuelto({this.valorInicial});

  final String? valorInicial;

  @override
  State<_DialogoAcordeSuelto> createState() => _DialogoAcordeSueltoState();
}

class _DialogoAcordeSueltoState extends State<_DialogoAcordeSuelto> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.valorInicial ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Acorde'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        style: _LineaEditor._estiloMono,
        decoration: const InputDecoration(
          labelText: 'Acorde',
          hintText: 'Ej. G, Em7, D/F#',
        ),
        onSubmitted: (_) => Navigator.of(context).pop(_controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Todos los acordes de una línea, sin cerrar el diálogo entre palabra y
/// palabra: tocás la primera, escribís, "Siguiente" en el teclado (o ›)
/// pasa a la que sigue — se guarda sola al navegar o al cerrar. Antes
/// cada palabra era un diálogo propio que había que abrir y cerrar.
class _DialogoAcordesLinea extends StatefulWidget {
  const _DialogoAcordesLinea({
    required this.palabras,
    required this.indiceInicial,
    required this.acordesPorPosicion,
    required this.onCambiar,
  });

  final List<({int inicio, String palabra})> palabras;
  final int indiceInicial;

  /// Referencia mutable compartida con `_LineaEditable` — se escribe acá
  /// mismo a medida que se navega, no al final.
  final Map<int, String> acordesPorPosicion;
  final VoidCallback onCambiar;

  @override
  State<_DialogoAcordesLinea> createState() => _DialogoAcordesLineaState();
}

class _DialogoAcordesLineaState extends State<_DialogoAcordesLinea> {
  late int _indice = widget.indiceInicial;
  late final TextEditingController _controller = TextEditingController(
    text: widget.acordesPorPosicion[widget.palabras[_indice].inicio] ?? '',
  );

  bool get _esUltima => _indice >= widget.palabras.length - 1;
  bool get _esPrimera => _indice <= 0;

  void _guardarPosicionActual() {
    final posicion = widget.palabras[_indice].inicio;
    final valor = _controller.text.trim();
    if (valor.isEmpty) {
      widget.acordesPorPosicion.remove(posicion);
    } else {
      widget.acordesPorPosicion[posicion] = valor;
    }
    widget.onCambiar();
  }

  void _irA(int nuevoIndice) {
    _guardarPosicionActual();
    setState(() {
      _indice = nuevoIndice;
      final valor = widget.acordesPorPosicion[widget.palabras[_indice].inicio] ?? '';
      _controller.value = TextEditingValue(
        text: valor,
        selection: TextSelection.collapsed(offset: valor.length),
      );
    });
  }

  void _cerrar() {
    _guardarPosicionActual();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return AlertDialog(
      title: Text('Acorde para "${widget.palabras[_indice].palabra}"'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Palabra anterior',
            onPressed: _esPrimera ? null : () => _irA(_indice - 1),
          ),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textInputAction: _esUltima ? TextInputAction.done : TextInputAction.next,
              style: _LineaEditor._estiloMono,
              decoration: const InputDecoration(
                labelText: 'Acorde',
                hintText: 'Ej. G, D/F#',
              ),
              onSubmitted: (_) => _esUltima ? _cerrar() : _irA(_indice + 1),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Palabra siguiente',
            onPressed: _esUltima ? null : () => _irA(_indice + 1),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              _controller.clear();
              setState(() {});
            },
            style: TextButton.styleFrom(
              foregroundColor: tema.colorScheme.error,
              alignment: Alignment.centerLeft,
            ),
            child: const Text('Quitar este acorde'),
          ),
        ),
        FilledButton(
          onPressed: _cerrar,
          child: const Text('Listo'),
        ),
      ],
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
  /// editarlo — ver `_LineaEditor._editarAcordes`.
  final Map<int, String> acordesPorPosicion;

  void dispose() {
    letraController.dispose();
  }
}

class _SeccionEditable {
  _SeccionEditable({required this.tipo})
      : lineas = [_LineaEditable()],
        tonoController = TextEditingController();

  _SeccionEditable._cargada(this.tipo, this.lineas, this.tonoController);

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
      lineas,
      TextEditingController(text: seccion.tonoBase ?? ''),
    );
  }

  /// Copia independiente de `original` — mismo tipo, tono, y cada línea
  /// con su propia letra y acordes (controllers nuevos, no compartidos).
  /// Usado por "Duplicar sección" para un coro/estribillo que se repite
  /// tal cual más adelante en la canción, sin tener que volver a
  /// escribirlo.
  factory _SeccionEditable.duplicadaDe(_SeccionEditable original) {
    final lineas = original.lineas
        .map((l) => _LineaEditable(
              letra: l.letraController.text,
              acordesPorPosicion: Map.of(l.acordesPorPosicion),
            ))
        .toList();
    return _SeccionEditable._cargada(
      original.tipo,
      lineas,
      TextEditingController(text: original.tonoController.text),
    );
  }

  TipoSeccion tipo;
  final List<_LineaEditable> lineas;

  /// Tono de esta sección, solo si cambia respecto al de la canción — ver
  /// `SeccionChordPro.tonoBase`. Vacío en el caso normal.
  final TextEditingController tonoController;

  void dispose() {
    for (final l in lineas) {
      l.dispose();
    }
    tonoController.dispose();
  }
}
