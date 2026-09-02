import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../acceso/data/services/autenticacion_service.dart';
import '../data/models/nota.dart';
import '../data/repositories/nota_repository.dart';

/// Pantalla 12: agregar una nota corta atada a una canción (y, si se abrió
/// desde una sección puntual, a esa sección). `cancionId`/`seccionEtiqueta`
/// nulos = nota general, sin canción asociada.
class AgregarNotaScreen extends StatefulWidget {
  const AgregarNotaScreen({
    super.key,
    this.cancionId,
    this.cancionTitulo,
    this.seccionEtiqueta,
  });

  final String? cancionId;
  final String? cancionTitulo;
  final String? seccionEtiqueta;

  @override
  State<AgregarNotaScreen> createState() => _AgregarNotaScreenState();
}

class _AgregarNotaScreenState extends State<AgregarNotaScreen> {
  final _textoController = TextEditingController();
  bool _compartida = false;
  bool _guardando = false;

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final texto = _textoController.text.trim();
    if (texto.isEmpty) return;
    setState(() => _guardando = true);
    final uid = context.read<AutenticacionService>().usuarioActual!.uid;
    await context.read<NotaRepository>().crear(
          Nota(
            id: '',
            texto: texto,
            compartida: _compartida,
            autorUid: uid,
            cancionId: widget.cancionId,
            seccionEtiqueta: widget.seccionEtiqueta,
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final contexto = [
      if (widget.cancionTitulo != null && widget.cancionTitulo!.isNotEmpty)
        widget.cancionTitulo!,
      if (widget.seccionEtiqueta != null) widget.seccionEtiqueta!,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar nota')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contexto.isNotEmpty) ...[
              Text(
                contexto,
                style: tema.textTheme.labelLarge
                    ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _textoController,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ej. Entrar suave. Segunda vuelta con guitarra eléctrica.',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Compartir con el equipo'),
              subtitle: Text(
                _compartida
                    ? 'Todo el equipo la va a ver.'
                    : 'Solo vos la vas a ver. No modifica la letra original.',
              ),
              value: _compartida,
              onChanged: (valor) => setState(() => _compartida = valor),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Text('Guardar nota'),
            ),
          ],
        ),
      ),
    );
  }
}
