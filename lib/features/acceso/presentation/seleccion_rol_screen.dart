import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../actividades/data/models/miembro.dart';
import '../../actividades/data/repositories/miembro_repository.dart';
import '../data/services/autenticacion_service.dart';
import 'home_placeholder_screen.dart';

/// Pantalla 5 del prototipo (Acceso). Aparece una sola vez por cuenta: la
/// primera vez que alguien inicia sesión, hay que vincular esa cuenta de
/// Firebase Auth con un perfil de `Miembro` — así "Mi equipo" (Paso
/// futuro) sabe distinguir "el líder edita a todos" de "el integrante
/// solo edita su propio perfil".
///
/// Si la cuenta ya está vinculada (`Miembro.uid` coincide), esta pantalla
/// no le pregunta nada a nadie — pasa directo al Home.
class SeleccionRolScreen extends StatefulWidget {
  const SeleccionRolScreen({super.key});

  @override
  State<SeleccionRolScreen> createState() => _SeleccionRolScreenState();
}

class _SeleccionRolScreenState extends State<SeleccionRolScreen> {
  late Future<_Estado> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<_Estado> _cargar() async {
    final uid = context.read<AutenticacionService>().usuarioActual!.uid;
    final repositorio = context.read<MiembroRepository>();

    final yaVinculado = await repositorio.buscarPorUid(uid);
    if (yaVinculado != null) return _Estado.vinculado(yaVinculado);

    final todos = await repositorio.fetchAll();
    final sinReclamar = todos.where((m) => m.uid == null).toList();
    return _Estado.porElegir(
      sinReclamar: sinReclamar,
      esPrimerUsuario: todos.isEmpty,
    );
  }

  Future<void> _reclamar(Miembro miembro) async {
    final uid = context.read<AutenticacionService>().usuarioActual!.uid;
    final repositorio = context.read<MiembroRepository>();
    await repositorio.actualizar(miembro.id, miembro.copyWith(uid: uid));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePlaceholderScreen()),
    );
  }

  Future<void> _crearNuevo({
    required String nombre,
    required List<RolMiembro> roles,
  }) async {
    final uid = context.read<AutenticacionService>().usuarioActual!.uid;
    final repositorio = context.read<MiembroRepository>();
    await repositorio.crear(
      Miembro(id: '', nombre: nombre, roles: roles, uid: uid),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePlaceholderScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Estado>(
      future: _futuro,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final estado = snapshot.data!;
        if (estado.miembroVinculado != null) {
          // Ya está vinculada -- no hay nada que preguntar, se pasa directo.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePlaceholderScreen()),
            );
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return estado.esPrimerUsuario
            ? _PrimerUsuario(onConfirmar: (nombre) => _crearNuevo(
                nombre: nombre,
                roles: const [RolMiembro.lider],
              ))
            : _ElegirQuienSos(
                sinReclamar: estado.sinReclamar,
                onElegir: _reclamar,
                onSoyNuevo: (nombre) => _crearNuevo(
                  nombre: nombre,
                  roles: const [RolMiembro.musico],
                ),
              );
      },
    );
  }
}

class _Estado {
  const _Estado.vinculado(Miembro this.miembroVinculado)
      : sinReclamar = const [],
        esPrimerUsuario = false;

  const _Estado.porElegir({
    required this.sinReclamar,
    required this.esPrimerUsuario,
  }) : miembroVinculado = null;

  final Miembro? miembroVinculado;
  final List<Miembro> sinReclamar;
  final bool esPrimerUsuario;
}

class _PrimerUsuario extends StatefulWidget {
  const _PrimerUsuario({required this.onConfirmar});

  final ValueChanged<String> onConfirmar;

  @override
  State<_PrimerUsuario> createState() => _PrimerUsuarioState();
}

class _PrimerUsuarioState extends State<_PrimerUsuario> {
  final _nombreController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sos el primer integrante',
                style: tema.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Todavía no hay nadie cargado en este equipo — te '
                'registramos como líder. Después podés sumar al resto '
                'desde "Mi equipo".',
                style: tema.textTheme.bodyMedium
                    ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Tu nombre'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _enviando
                    ? null
                    : () async {
                        final nombre = _nombreController.text.trim();
                        if (nombre.isEmpty) return;
                        setState(() => _enviando = true);
                        widget.onConfirmar(nombre);
                      },
                child: _enviando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('Empezar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElegirQuienSos extends StatefulWidget {
  const _ElegirQuienSos({
    required this.sinReclamar,
    required this.onElegir,
    required this.onSoyNuevo,
  });

  final List<Miembro> sinReclamar;
  final ValueChanged<Miembro> onElegir;
  final ValueChanged<String> onSoyNuevo;

  @override
  State<_ElegirQuienSos> createState() => _ElegirQuienSosState();
}

class _ElegirQuienSosState extends State<_ElegirQuienSos> {
  bool _soyNuevo = false;
  bool _enviando = false;
  final _nombreController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('¿Quién sos?')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: _soyNuevo ? _formularioNuevo(tema) : _listaExistentes(tema),
        ),
      ),
    );
  }

  Widget _listaExistentes(ThemeData tema) {
    return ListView(
      children: [
        Text(
          'Elegí tu nombre en la lista del equipo.',
          style: tema.textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        for (final miembro in widget.sinReclamar)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(miembro.nombre),
              subtitle: Text(miembro.roles.map((r) => r.name).join(' · ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => widget.onElegir(miembro),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => _soyNuevo = true),
          child: const Text('No me encuentro en la lista'),
        ),
      ],
    );
  }

  Widget _formularioNuevo(ThemeData tema) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Cómo te llamás?',
          style:
              tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Te sumamos al equipo como músico — el líder puede cambiar tu '
          'rol después desde "Mi equipo".',
          style: tema.textTheme.bodyMedium
              ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nombreController,
          decoration: const InputDecoration(labelText: 'Tu nombre'),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _enviando
              ? null
              : () {
                  final nombre = _nombreController.text.trim();
                  if (nombre.isEmpty) return;
                  setState(() => _enviando = true);
                  widget.onSoyNuevo(nombre);
                },
          child: _enviando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : const Text('Sumarme al equipo'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _soyNuevo = false),
          child: const Text('Volver a la lista'),
        ),
      ],
    );
  }
}
