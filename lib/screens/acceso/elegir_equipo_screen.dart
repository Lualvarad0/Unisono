import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/models/equipo.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/equipo_repository.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/repositories/usuario_equipo_repository.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/widgets/logo_unisono.dart';

/// Primera vez que esta cuenta entra y todavía no está vinculada a
/// ningún equipo (no existe `usuarioEquipo/{uid}`) — ver
/// `ResolverEquipoScreen`, que es quien decide mostrar esto. Acá se
/// elige entre armar un equipo nuevo (queda como líder) o sumarse a uno
/// que ya existe con el código de 6 caracteres que comparte cualquier
/// integrante desde "Mi equipo".
class ElegirEquipoScreen extends StatefulWidget {
  const ElegirEquipoScreen({super.key, required this.onListo});

  /// Se llama una vez que la cuenta ya quedó vinculada a un equipo —
  /// `ResolverEquipoScreen` vuelve a resolver y sigue para adelante.
  final VoidCallback onListo;

  @override
  State<ElegirEquipoScreen> createState() => _ElegirEquipoScreenState();
}

enum _Modo { elegir, crear, unirse }

class _ElegirEquipoScreenState extends State<ElegirEquipoScreen> {
  _Modo _modo = _Modo.elegir;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _modo == _Modo.elegir
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _modo = _Modo.elegir),
              ),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: switch (_modo) {
            _Modo.elegir => _Eleccion(
                onCrear: () => setState(() => _modo = _Modo.crear),
                onUnirse: () => setState(() => _modo = _Modo.unirse),
              ),
            _Modo.crear => _FormularioCrear(onListo: widget.onListo),
            _Modo.unirse => _FormularioUnirse(onListo: widget.onListo),
          },
        ),
      ),
    );
  }
}

class _Eleccion extends StatelessWidget {
  const _Eleccion({required this.onCrear, required this.onUnirse});

  final VoidCallback onCrear;
  final VoidCallback onUnirse;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LogoUnisono(tamano: 56),
        const SizedBox(height: 20),
        Text('¿Cómo arrancamos?', style: tema.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Si sos el primero de tu equipo en usar la app, armá un equipo '
          'nuevo. Si tus compañeros ya la están usando, pedíles el código '
          'y unite al de ellos.',
          textAlign: TextAlign.center,
          style: tema.textTheme.bodyMedium
              ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onCrear,
            child: const Text('Crear un equipo nuevo'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onUnirse,
            child: const Text('Unirme con un código'),
          ),
        ),
      ],
    );
  }
}

class _FormularioCrear extends StatefulWidget {
  const _FormularioCrear({required this.onListo});

  final VoidCallback onListo;

  @override
  State<_FormularioCrear> createState() => _FormularioCrearState();
}

class _FormularioCrearState extends State<_FormularioCrear> {
  final _nombreEquipoController = TextEditingController();
  final _tuNombreController = TextEditingController();
  bool _creando = false;

  @override
  void dispose() {
    _nombreEquipoController.dispose();
    _tuNombreController.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final nombreEquipo = _nombreEquipoController.text.trim();
    final tuNombre = _tuNombreController.text.trim();
    if (nombreEquipo.isEmpty || tuNombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá el nombre del equipo y el tuyo.')),
      );
      return;
    }
    setState(() => _creando = true);
    final uid = context.read<AutenticacionService>().usuarioActual!.uid;
    final equipoRepositorio = context.read<EquipoRepository>();
    final usuarioEquipoRepositorio = context.read<UsuarioEquipoRepository>();

    try {
      final codigo = await equipoRepositorio.generarCodigoUnico();
      final equipoId = await equipoRepositorio.crear(
        Equipo(id: '', nombre: nombreEquipo, codigo: codigo, creadoPorUid: uid),
      );
      final miembroId = await MiembroRepository(equipoId: equipoId).crear(
        Miembro(id: '', nombre: tuNombre, roles: const [RolMiembro.lider], uid: uid),
      );
      await usuarioEquipoRepositorio.vincular(
        uid: uid,
        equipoId: equipoId,
        miembroId: miembroId,
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _creando = false);
      final mensaje = e.code == 'resource-exhausted'
          ? 'Demasiados intentos — esperá un momento y probá de nuevo.'
          : 'No se pudo crear el equipo — revisá tu conexión y probá de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      return;
    }
    if (!mounted) return;
    widget.onListo();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Text('Crear equipo', style: tema.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Vas a quedar como líder — después podés invitar al resto '
            'compartiéndoles el código que se genera acá.',
            style: tema.textTheme.bodyMedium
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nombreEquipoController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre del equipo',
              hintText: 'Ej. Alabanza Iglesia Central',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tuNombreController,
            decoration: const InputDecoration(labelText: 'Tu nombre'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _creando ? null : _crear,
              child: _creando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Text('Crear equipo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormularioUnirse extends StatefulWidget {
  const _FormularioUnirse({required this.onListo});

  final VoidCallback onListo;

  @override
  State<_FormularioUnirse> createState() => _FormularioUnirseState();
}

class _FormularioUnirseState extends State<_FormularioUnirse> {
  final _codigoController = TextEditingController();
  final _tuNombreController = TextEditingController();
  bool _verificando = false;
  bool _confirmando = false;
  bool _soyNuevo = false;
  Equipo? _equipo;
  List<Miembro> _sinReclamar = const [];

  @override
  void dispose() {
    _codigoController.dispose();
    _tuNombreController.dispose();
    super.dispose();
  }

  Future<void> _verificarCodigo() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) return;
    setState(() => _verificando = true);
    Equipo? equipo;
    try {
      equipo = await context.read<EquipoRepository>().buscarPorCodigo(codigo);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _verificando = false);
      final mensaje = e.code == 'resource-exhausted'
          ? 'Demasiados intentos — esperá un momento y probá de nuevo.'
          : 'No se pudo verificar el código — revisá tu conexión y probá de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      return;
    }
    if (!mounted) return;
    if (equipo == null) {
      setState(() => _verificando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese código no corresponde a ningún equipo.')),
      );
      return;
    }
    final sinReclamar = await MiembroRepository(equipoId: equipo.id).fetchSinReclamar();
    if (!mounted) return;
    setState(() {
      _equipo = equipo;
      _sinReclamar = sinReclamar;
      _verificando = false;
    });
  }

  Future<void> _elegir(Miembro miembro) async {
    setState(() => _confirmando = true);
    final uid = context.read<AutenticacionService>().usuarioActual!.uid;
    final usuarioEquipoRepositorio = context.read<UsuarioEquipoRepository>();
    await MiembroRepository(equipoId: _equipo!.id)
        .actualizar(miembro.id, miembro.copyWith(uid: uid));
    await usuarioEquipoRepositorio.vincular(
      uid: uid,
      equipoId: _equipo!.id,
      miembroId: miembro.id,
    );
    if (!mounted) return;
    widget.onListo();
  }

  Future<void> _confirmarNuevo() async {
    final nombre = _tuNombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta tu nombre.')),
      );
      return;
    }
    setState(() => _confirmando = true);
    final uid = context.read<AutenticacionService>().usuarioActual!.uid;
    final usuarioEquipoRepositorio = context.read<UsuarioEquipoRepository>();
    final miembroId = await MiembroRepository(equipoId: _equipo!.id).crear(
      Miembro(id: '', nombre: nombre, roles: const [RolMiembro.musico], uid: uid),
    );
    await usuarioEquipoRepositorio.vincular(
      uid: uid,
      equipoId: _equipo!.id,
      miembroId: miembroId,
    );
    if (!mounted) return;
    widget.onListo();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final equipo = _equipo;

    if (equipo == null) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text('Unirme a un equipo', style: tema.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Pedile a alguien del equipo el código de 6 caracteres — lo '
              'encuentra en "Mi equipo".',
              style: tema.textTheme.bodyMedium
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codigoController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código del equipo',
                hintText: 'Ej. TR8K2P',
              ),
              onSubmitted: (_) => _verificarCodigo(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _verificando ? null : _verificarCodigo,
                child: _verificando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('Continuar'),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(equipo.nombre, style: tema.textTheme.headlineSmall),
          const SizedBox(height: 20),
          if (!_soyNuevo) ...[
            Text('Elegí tu nombre en la lista.', style: tema.textTheme.bodyLarge),
            const SizedBox(height: 12),
            for (final miembro in _sinReclamar)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(miembro.nombre),
                  subtitle: Text(miembro.roles.map((r) => r.nombreVisible).join(' · ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _confirmando ? null : () => _elegir(miembro),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => setState(() => _soyNuevo = true),
              child: const Text('No me encuentro en la lista'),
            ),
          ] else ...[
            Text('¿Cómo te llamás?', style: tema.textTheme.bodyLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _tuNombreController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Tu nombre'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _confirmando ? null : _confirmarNuevo,
                child: _confirmando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('Sumarme al equipo'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _soyNuevo = false),
              child: const Text('Volver a la lista'),
            ),
          ],
        ],
      ),
    );
  }
}
