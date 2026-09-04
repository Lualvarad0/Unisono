import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/formato_fecha.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/widgets/encabezado_seccion.dart';

/// Pantalla completa para editar el perfil propio — no un diálogo
/// flotante: entra con la flecha de volver como cualquier otra pantalla
/// de la app (Nueva actividad, Nueva alabanza), y las ventanas flotantes
/// quedan reservadas para avisos puntuales, como el de cambios sin
/// guardar al querer salir (`PopScope` de acá abajo).
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key, required this.miembro});

  final Miembro miembro;

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late final _nombreController =
      TextEditingController(text: widget.miembro.nombre);
  late final _apellidoController =
      TextEditingController(text: widget.miembro.apellido);
  late final _instrumentoController =
      TextEditingController(text: widget.miembro.instrumento ?? '');
  late final _telefonoController =
      TextEditingController(text: widget.miembro.telefono ?? '');
  late DateTime? _fechaNacimiento = widget.miembro.fechaNacimiento;
  late NivelInstrumento? _nivel = widget.miembro.nivelInstrumento;
  late final Set<RolMiembro> _roles = {...widget.miembro.roles};
  bool _guardando = false;

  bool get _sucio =>
      _nombreController.text.trim() != widget.miembro.nombre ||
      _apellidoController.text.trim() != widget.miembro.apellido ||
      _instrumentoController.text.trim() != (widget.miembro.instrumento ?? '') ||
      _telefonoController.text.trim() != (widget.miembro.telefono ?? '') ||
      _fechaNacimiento != widget.miembro.fechaNacimiento ||
      _nivel != widget.miembro.nivelInstrumento ||
      !setEquals(_roles, widget.miembro.roles.toSet());

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _instrumentoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _elegirFechaNacimiento() async {
    final elegido = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(DateTime.now().year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (elegido != null) setState(() => _fechaNacimiento = elegido);
  }

  /// La única ventana flotante de esta pantalla: un aviso puntual, no un
  /// formulario — justo la distinción que separa "diálogo" de "pantalla".
  Future<bool> _confirmarDescartar() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text('Todavía no guardaste lo que editaste acá.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return descartar ?? false;
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _guardando = true);
    final repositorio = context.read<MiembroRepository>();
    final instrumento = _instrumentoController.text.trim();
    final telefono = _telefonoController.text.trim();
    final actualizado = Miembro(
      id: widget.miembro.id,
      nombre: nombre,
      apellido: _apellidoController.text.trim(),
      roles: _roles.toList(),
      uid: widget.miembro.uid,
      fechaNacimiento: _fechaNacimiento,
      telefono: telefono.isEmpty ? null : telefono,
      instrumento: instrumento.isEmpty ? null : instrumento,
      nivelInstrumento: _nivel,
    );
    await repositorio.actualizar(widget.miembro.id, actualizado);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _manejarPop(bool didPop, void result) async {
    if (didPop) return;
    final descartar = await _confirmarDescartar();
    if (!descartar || !mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return PopScope<void>(
      canPop: !_sucio,
      onPopInvokedWithResult: _manejarPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar perfil')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const EncabezadoSeccion('DATOS PERSONALES'),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apellidoController,
              decoration: const InputDecoration(labelText: 'Apellido'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _elegirFechaNacimiento,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration:
                    const InputDecoration(labelText: 'Fecha de nacimiento'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fechaNacimiento == null
                          ? 'Sin definir'
                          : formatearFechaLarga(_fechaNacimiento!),
                    ),
                    Icon(Icons.cake_outlined,
                        size: 20, color: tema.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 28),
            const EncabezadoSeccion('MÚSICA'),
            const SizedBox(height: 12),
            TextField(
              controller: _instrumentoController,
              decoration: const InputDecoration(
                labelText: 'Instrumento',
                hintText: 'Ej. Guitarra, Batería, Voz',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text('Nivel', style: tema.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final nivel in NivelInstrumento.values)
                  ChoiceChip(
                    label: Text(nivel.nombreVisible),
                    selected: _nivel == nivel,
                    // Tocar el nivel ya seleccionado lo destilda — "nivel"
                    // es de a uno, pero no tiene por qué ser obligatorio.
                    onSelected: (marcado) =>
                        setState(() => _nivel = marcado ? nivel : null),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            const EncabezadoSeccion('ROLES'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rol in RolMiembro.values)
                  FilterChip(
                    label: Text(rol.nombreVisible),
                    selected: _roles.contains(rol),
                    onSelected: (marcado) => setState(() {
                      if (marcado) {
                        _roles.add(rol);
                      } else {
                        _roles.remove(rol);
                      }
                    }),
                  ),
              ],
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
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
