import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/models/actividad.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/models/setlist_entry.dart';
import 'package:app_alabanzas/repositories/actividad_repository.dart';
import 'package:app_alabanzas/screens/actividades/actividad_utils.dart';
import 'package:app_alabanzas/widgets/acciones_dialogo.dart';
import 'package:app_alabanzas/widgets/encabezado_seccion.dart';

/// Crear o editar una Actividad: nombre, fecha/hora, y el setlist —
/// canciones en orden, cada una con cantante y tono asignados para ese
/// día puntual (no toca `Cancion.tonoOriginal`). `actividadExistente`
/// nulo = crear; no nulo = editar esa misma, mismo patrón que
/// `EditorSimpleScreen` con `contenidoInicial`.
class AgregarActividadScreen extends StatefulWidget {
  const AgregarActividadScreen({super.key, this.actividadExistente});

  final Actividad? actividadExistente;

  @override
  State<AgregarActividadScreen> createState() => _AgregarActividadScreenState();
}

typedef _DatosFormulario = ({List<Cancion> canciones, List<Miembro> miembros});

class _AgregarActividadScreenState extends State<AgregarActividadScreen> {
  final _nombreController = TextEditingController();
  late DateTime _fecha;
  late List<SetlistEntry> _entradas;
  bool _guardando = false;
  late final Future<_DatosFormulario> _datosFuturo;

  @override
  void initState() {
    super.initState();
    final existente = widget.actividadExistente;
    _nombreController.text = existente?.nombre ?? '';
    _fecha = existente?.fecha ?? DateTime.now().add(const Duration(days: 1));
    _entradas = [...?existente?.setlist];
    _datosFuturo = _cargarDatos();
  }

  Future<_DatosFormulario> _cargarDatos() async {
    final cancionRepositorio = context.read<Repositorio<Cancion>>();
    final miembroRepositorio = context.read<Repositorio<Miembro>>();
    final canciones = await cancionRepositorio.fetchAll();
    final miembros = await miembroRepositorio.fetchAll();
    return (canciones: canciones, miembros: miembros);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fecha),
    );
    if (hora == null || !mounted) return;
    setState(() {
      _fecha =
          DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
    });
  }

  Future<void> _agregarCancion(_DatosFormulario datos) async {
    final entrada = await showDialog<SetlistEntry>(
      context: context,
      builder: (_) => _DialogoEntradaSetlist(
        canciones: datos.canciones,
        miembros: datos.miembros,
      ),
    );
    if (entrada == null) return;
    setState(() => _entradas.add(entrada));
  }

  void _quitarEntrada(int indice) {
    setState(() => _entradas.removeAt(indice));
  }

  void _reordenar(int viejo, int nuevo) {
    // `onReorderItem` (a diferencia de `onReorder`, deprecado) ya entrega
    // `nuevo` ajustado por el hueco que deja sacar el elemento de `viejo`
    // — no hace falta restarle 1 a mano cuando se mueve hacia abajo.
    setState(() {
      final entrada = _entradas.removeAt(viejo);
      _entradas.insert(nuevo, entrada);
    });
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _guardando = true);
    final repositorio = context.read<ActividadRepository>();
    final setlistOrdenado = [
      for (var i = 0; i < _entradas.length; i++) _entradas[i].copyWith(orden: i),
    ];
    final existente = widget.actividadExistente;
    if (existente == null) {
      await repositorio.crear(
        Actividad(id: '', nombre: nombre, fecha: _fecha, setlist: setlistOrdenado),
      );
    } else {
      await repositorio.actualizar(
        existente.id,
        existente.copyWith(nombre: nombre, fecha: _fecha, setlist: setlistOrdenado),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final editando = widget.actividadExistente != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar actividad' : 'Nueva actividad'),
      ),
      body: FutureBuilder<_DatosFormulario>(
        future: _datosFuturo,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final datos = snapshot.data!;
          final cancionPorId = {for (final c in datos.canciones) c.id: c};
          final nombrePorMiembroId = {
            for (final m in datos.miembros) m.id: m.nombre,
          };

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const EncabezadoSeccion('DATOS DE LA ACTIVIDAD'),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej. Servicio dominical',
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _elegirFecha,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Fecha y hora *'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${formatearFechaActividad(_fecha)} · '
                        '${TimeOfDay.fromDateTime(_fecha).format(context)}',
                      ),
                      const Icon(Icons.calendar_today_outlined, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const EncabezadoSeccion('SETLIST'),
                  TextButton.icon(
                    onPressed: datos.canciones.isEmpty
                        ? null
                        : () => _agregarCancion(datos),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar canción'),
                  ),
                ],
              ),
              if (_entradas.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    datos.canciones.isEmpty
                        ? 'Todavía no hay canciones en el repertorio para agregar.'
                        : 'Todavía no agregaste ninguna canción.',
                    style: tema.textTheme.bodyMedium
                        ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _entradas.length,
                  onReorderItem: _reordenar,
                  itemBuilder: (context, i) {
                    final entrada = _entradas[i];
                    final cancion = cancionPorId[entrada.cancionId];
                    final tonoResultante = cancion == null
                        ? null
                        : transponerTono(
                            cancion.tonoOriginal, entrada.tonoAsignado);
                    final cantante = nombrePorMiembroId[entrada.cantanteId];
                    final tieneCantante = cantante != null && cantante.isNotEmpty;
                    return Card(
                      key: ValueKey(i),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(cancion?.titulo ?? 'Canción eliminada'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (tonoResultante != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.music_note_outlined,
                                        size: 14,
                                        color: tema.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text('Tono: $tonoResultante'),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.mic_outlined,
                                      size: 14,
                                      color: tema.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    tieneCantante
                                        ? cantante
                                        : 'Sin cantante asignado',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: tonoResultante != null,
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Quitar',
                          onPressed: () => _quitarEntrada(i),
                        ),
                      ),
                    );
                  },
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
                    : Text(editando ? 'Guardar cambios' : 'Crear actividad'),
              ),
              const SizedBox(height: 4),
              Text(
                '* obligatorio',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodySmall
                    ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DialogoEntradaSetlist extends StatefulWidget {
  const _DialogoEntradaSetlist({required this.canciones, required this.miembros});

  final List<Cancion> canciones;
  final List<Miembro> miembros;

  @override
  State<_DialogoEntradaSetlist> createState() => _DialogoEntradaSetlistState();
}

class _DialogoEntradaSetlistState extends State<_DialogoEntradaSetlist> {
  late Cancion _cancion = widget.canciones.first;
  String _cantanteId = '';
  int _tonoAsignado = 0;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tonoResultante = transponerTono(_cancion.tonoOriginal, _tonoAsignado);

    return AlertDialog(
      title: const Text('Agregar canción'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Cancion>(
              initialValue: _cancion,
              decoration: const InputDecoration(labelText: 'Canción'),
              items: [
                for (final c in widget.canciones)
                  DropdownMenuItem(value: c, child: Text(c.titulo)),
              ],
              onChanged: (valor) => setState(() {
                if (valor != null) {
                  _cancion = valor;
                  _tonoAsignado = 0;
                }
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _cantanteId,
              decoration: const InputDecoration(labelText: 'Cantante (opcional)'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Sin asignar')),
                for (final m in widget.miembros)
                  DropdownMenuItem(value: m.id, child: Text(m.nombre)),
              ],
              onChanged: (valor) => setState(() => _cantanteId = valor ?? ''),
            ),
            const SizedBox(height: 16),
            Text('Tono para este día', style: tema.textTheme.labelLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() => _tonoAsignado--),
                ),
                Column(
                  children: [
                    Text(tonoResultante, style: tema.textTheme.headlineSmall),
                    if (_tonoAsignado != 0)
                      Text(
                        'Original ${_cancion.tonoOriginal}',
                        style: tema.textTheme.bodySmall,
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _tonoAsignado++),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        AccionesDialogo(
          textoSecundario: 'Cancelar',
          onSecundario: () => Navigator.of(context).pop(),
          textoPrimario: 'Agregar',
          onPrimario: () => Navigator.of(context).pop(
            SetlistEntry(
              cancionId: _cancion.id,
              orden: 0,
              cantanteId: _cantanteId,
              tonoAsignado: _tonoAsignado,
            ),
          ),
        ),
      ],
    );
  }
}
