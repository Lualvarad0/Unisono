import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/ejercicio.dart';
import 'package:app_alabanzas/repositories/ejercicio_repository.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';

/// El líder deja acá una consigna de práctica para el equipo — opcionalmente
/// atada a una canción (y, dentro de esa canción, a una sección puntual).
class AgregarEjercicioScreen extends StatefulWidget {
  const AgregarEjercicioScreen({super.key});

  @override
  State<AgregarEjercicioScreen> createState() => _AgregarEjercicioScreenState();
}

class _AgregarEjercicioScreenState extends State<AgregarEjercicioScreen> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _seccionController = TextEditingController();
  String? _cancionId;
  bool _guardando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _seccionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) return;
    setState(() => _guardando = true);
    final uid = context.read<AutenticacionService>().usuarioActual!.uid;
    final seccion = _seccionController.text.trim();
    await context.read<EjercicioRepository>().crear(
          Ejercicio(
            id: '',
            titulo: titulo,
            descripcion: _descripcionController.text.trim(),
            autorUid: uid,
            cancionId: _cancionId,
            seccionEtiqueta:
                (_cancionId != null && seccion.isNotEmpty) ? seccion : null,
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo ejercicio')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: _tituloController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ej. Practicar el puente de Way Maker',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Detalle (opcional)',
                hintText: 'Ej. Entrar suave, sin batería los primeros 4 compases.',
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Cancion>>(
              stream: context.read<Repositorio<Cancion>>().watchAll(),
              builder: (context, snapshot) {
                final canciones = snapshot.data ?? const <Cancion>[];
                return DropdownButtonFormField<String?>(
                  initialValue: _cancionId,
                  decoration: const InputDecoration(
                    labelText: 'Canción relacionada (opcional)',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Ninguna — ejercicio general'),
                    ),
                    for (final cancion in canciones)
                      DropdownMenuItem<String?>(
                        value: cancion.id,
                        child: Text(cancion.titulo),
                      ),
                  ],
                  onChanged: (valor) => setState(() => _cancionId = valor),
                );
              },
            ),
            if (_cancionId != null) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _seccionController,
                decoration: const InputDecoration(
                  labelText: 'Sección (opcional)',
                  hintText: 'Ej. Puente, Coro',
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Text('Guardar ejercicio'),
            ),
          ],
        ),
      ),
    );
  }
}
