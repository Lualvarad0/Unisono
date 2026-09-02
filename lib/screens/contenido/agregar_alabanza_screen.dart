import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/models/artista.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/screens/contenido/detectar_tonalidad_screen.dart';
import 'package:app_alabanzas/screens/contenido/editor_chordpro_screen.dart';
import 'package:app_alabanzas/screens/contenido/editor_simple_screen.dart';

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
  bool _guardando = false;

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
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (valor) =>
                  (valor == null || valor.trim().isEmpty) ? 'Falta el título' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _artistaController,
              decoration:
                  const InputDecoration(labelText: 'Artista / Ministerio'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _elegirTono,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tono original'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_tono, style: tema.textTheme.bodyLarge),
                    const Icon(Icons.expand_more),
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
                    decoration:
                        const InputDecoration(labelText: 'BPM opcional'),
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
            Text('Etiquetas', style: tema.textTheme.labelLarge),
            const SizedBox(height: 8),
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
            const SizedBox(height: 24),
            Text('Letra y acordes', style: tema.textTheme.labelLarge),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
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
