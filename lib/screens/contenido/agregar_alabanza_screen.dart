import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/models/artista.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/ritmo.dart';
import 'package:app_alabanzas/screens/contenido/detectar_tonalidad_screen.dart';
import 'package:app_alabanzas/screens/contenido/editor_chordpro_screen.dart';
import 'package:app_alabanzas/screens/contenido/editor_simple_screen.dart';
import 'package:app_alabanzas/widgets/encabezado_seccion.dart';

/// Géneros con los que arranca la colección `ritmos` la primera vez que se
/// abre este formulario y todavía está vacía — típicos de un repertorio de
/// alabanza latinoamericano. El líder no está atado a esta lista: son solo
/// los datos iniciales de una colección de Firestore común, así que sumar
/// un género nuevo es tan simple como escribirlo (ver `_agregarGenero`).
const _generosPorDefecto = [
  'Adoración',
  'Júbilo',
  'Cumbia',
  'Coritos',
  'Balada',
  'Salsa',
  'Merengue',
  'Rock cristiano',
  'Instrumental',
];

/// Pantalla 9: cargar una alabanza nueva. Sigue el flujo sugerido del
/// diseño (Agregar → Editor → Detectar tono → Guardar), pero como
/// pantalla única con secciones en vez de wizard de varios pasos — con
/// solo 5 campos + el editor no hace falta partirlo en pantallas propias.
class AgregarAlabanzaScreen extends StatefulWidget {
  const AgregarAlabanzaScreen({super.key});

  @override
  State<AgregarAlabanzaScreen> createState() => _AgregarAlabanzaScreenState();
}

class _AgregarAlabanzaScreenState extends State<AgregarAlabanzaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _artistaController = TextEditingController();
  final _bpmController = TextEditingController();
  final _compasController = TextEditingController();
  final _etiquetaController = TextEditingController();

  String _tono = 'C';
  String _contenidoChordPro = '';
  final List<String> _etiquetas = [];
  String? _ritmoId;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _sembrarGenerosPorDefecto();
  }

  Future<void> _sembrarGenerosPorDefecto() async {
    final repositorio = context.read<Repositorio<Ritmo>>();
    final existentes = await repositorio.fetchAll();
    if (existentes.isNotEmpty) return;
    for (final nombre in _generosPorDefecto) {
      await repositorio.crear(Ritmo(id: '', nombre: nombre));
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _artistaController.dispose();
    _bpmController.dispose();
    _compasController.dispose();
    _etiquetaController.dispose();
    super.dispose();
  }

  void _agregarEtiqueta() {
    final valor = _etiquetaController.text.trim();
    if (valor.isEmpty || _etiquetas.contains(valor)) return;
    setState(() {
      _etiquetas.add(valor);
      _etiquetaController.clear();
    });
  }

  Future<void> _elegirTono() async {
    final elegido = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => DetectarTonalidadScreen(tonoSugerido: _tono),
      ),
    );
    if (elegido != null) setState(() => _tono = elegido);
  }

  /// Camino principal: acordes arriba, letra abajo, sin sintaxis que
  /// aprender. Es lo que ve cualquiera que toque "Letra y acordes".
  Future<void> _abrirEditorSimple() async {
    final resultado = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EditorSimpleScreen(contenidoInicial: _contenidoChordPro),
      ),
    );
    if (resultado != null) setState(() => _contenidoChordPro = resultado);
  }

  /// Camino secundario, para quien ya tiene el archivo ChordPro de otra
  /// app/iglesia y lo quiere pegar tal cual — ver README, "Cargar tu
  /// propio repertorio".
  Future<void> _abrirEditorChordPro() async {
    final resultado = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EditorChordProScreen(contenidoInicial: _contenidoChordPro),
      ),
    );
    if (resultado != null) setState(() => _contenidoChordPro = resultado);
  }

  /// Reutiliza un `Artista` existente por nombre (sin distinguir
  /// mayúsculas) o crea uno nuevo — el formulario pide el nombre en texto
  /// libre, no un picker, así que resolvemos la referencia acá.
  Future<String?> _resolverArtista(Repositorio<Artista> repositorio) async {
    final nombre = _artistaController.text.trim();
    if (nombre.isEmpty) return null;
    final existentes = await repositorio.fetchAll();
    for (final artista in existentes) {
      if (artista.nombre.toLowerCase() == nombre.toLowerCase()) {
        return artista.id;
      }
    }
    return repositorio.crear(Artista(id: '', nombre: nombre));
  }

  /// Alta rápida de un género que no está en la lista — un diálogo chico
  /// para una sola decisión puntual, no un formulario propio (a diferencia
  /// de Editar perfil, que si es un dato central de cuenta).
  Future<void> _agregarGenero(Repositorio<Ritmo> repositorio) async {
    final controller = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo género'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nombre == null || nombre.isEmpty || !mounted) return;
    final id = await repositorio.crear(Ritmo(id: '', nombre: nombre));
    if (!mounted) return;
    setState(() => _ritmoId = id);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_contenidoChordPro.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta cargar la letra y los acordes.')),
      );
      return;
    }
    setState(() => _guardando = true);

    final artistaRepositorio = context.read<Repositorio<Artista>>();
    final cancionRepositorio = context.read<Repositorio<Cancion>>();

    final artistaId = await _resolverArtista(artistaRepositorio);
    await cancionRepositorio.crear(
          Cancion(
            id: '',
            titulo: _tituloController.text.trim(),
            ritmoId: _ritmoId,
            artistaId: artistaId,
            tonoOriginal: _tono,
            contenidoChordPro: _contenidoChordPro,
            bpm: int.tryParse(_bpmController.text.trim()),
            compas: _compasController.text.trim().isEmpty
                ? null
                : _compasController.text.trim(),
            etiquetas: _etiquetas,
          ),
        );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva alabanza')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const EncabezadoSeccion('DATOS BÁSICOS'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título *'),
              validator: (valor) =>
                  (valor == null || valor.trim().isEmpty) ? 'Falta el título' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _artistaController,
              decoration:
                  const InputDecoration(labelText: 'Artista / Ministerio'),
            ),
            const SizedBox(height: 28),
            const EncabezadoSeccion('DETALLES MUSICALES'),
            const SizedBox(height: 12),
            InkWell(
              onTap: _elegirTono,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tono original'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_tono, style: tema.textTheme.bodyLarge),
                    // chevron_right (no expand_more) a propósito: este
                    // campo no despliega un menú acá mismo, navega a
                    // DetectarTonalidadScreen — el ícono tiene que avisar
                    // eso, no parecer un dropdown que no es.
                    Icon(
                      Icons.chevron_right,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bpmController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'BPM'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _compasController,
                    decoration: const InputDecoration(
                      labelText: 'Compás',
                      hintText: '4/4',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Género', style: tema.textTheme.labelLarge),
            const SizedBox(height: 8),
            StreamBuilder<List<Ritmo>>(
              stream: context.read<Repositorio<Ritmo>>().watchAll(),
              builder: (context, snapshot) {
                final generos = [...snapshot.data ?? const <Ritmo>[]]
                  ..sort((a, b) => a.nombre.compareTo(b.nombre));
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final genero in generos)
                      ChoiceChip(
                        label: Text(genero.nombre),
                        selected: _ritmoId == genero.id,
                        onSelected: (marcado) => setState(
                          () => _ritmoId = marcado ? genero.id : null,
                        ),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Nuevo'),
                      onPressed: () => _agregarGenero(
                        context.read<Repositorio<Ritmo>>(),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            const EncabezadoSeccion('ETIQUETAS'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final etiqueta in _etiquetas)
                  Chip(
                    label: Text(etiqueta),
                    onDeleted: () => setState(() => _etiquetas.remove(etiqueta)),
                  ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _etiquetaController,
                    decoration: const InputDecoration(hintText: '+ etiqueta'),
                    onSubmitted: (_) => _agregarEtiqueta(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const EncabezadoSeccion('LETRA Y ACORDES *'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _abrirEditorSimple,
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                _contenidoChordPro.trim().isEmpty
                    ? 'Escribir letra y acordes'
                    : 'Editar letra y acordes (cargado)',
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _abrirEditorChordPro,
                child: const Text('¿Ya tenés el archivo ChordPro? Pegarlo'),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Text('Guardar alabanza'),
            ),
            const SizedBox(height: 4),
            Text(
              '* obligatorio',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              'Se descarga una copia local automáticamente.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodySmall
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
