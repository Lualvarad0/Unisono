import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/models/equipo.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/screens/equipo/invitar_miembro_screen.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/widgets/acciones_dialogo.dart';
import 'package:app_alabanzas/widgets/visor_foto.dart';

/// "Mi equipo": la lista de integrantes con sus roles. Cualquiera la puede
/// ver; solo quien tiene el rol Líder puede tocar a alguien para cambiarle
/// los roles — el resto la ve de solo lectura.
class EquipoScreen extends StatelessWidget {
  const EquipoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AutenticacionService>().usuarioActual?.uid;

    return FutureBuilder<Miembro?>(
      future: uid == null
          ? null
          : context.read<MiembroRepository>().buscarPorUid(uid),
      builder: (context, snapshotYo) {
        final esLider =
            snapshotYo.data?.roles.contains(RolMiembro.lider) ?? false;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi equipo'),
            actions: [
              if (esLider)
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const InvitarMiembroScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_outlined),
                  tooltip: 'Invitar integrante',
                ),
            ],
          ),
          body: StreamBuilder<List<Miembro>>(
            stream: context.read<Repositorio<Miembro>>().watchAll(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final integrantes = [...snapshot.data!]
                ..sort((a, b) => a.nombre.compareTo(b.nombre));
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _TarjetaCodigo(),
                  const SizedBox(height: 16),
                  if (integrantes.isEmpty)
                    const Center(child: Text('Todavía no hay integrantes.'))
                  else
                    for (final miembro in integrantes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TarjetaMiembro(
                          miembro: miembro,
                          esVos: miembro.uid == uid,
                          editable: esLider,
                        ),
                      ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// El código de 6 caracteres para que alguien nuevo se una a este mismo
/// equipo (ver `ElegirEquipoScreen`, "Unirme con un código") — visible
/// para cualquiera, no solo el líder: cualquiera del equipo puede
/// invitar, no hace falta pedirle el código justo a quien lo armó.
class _TarjetaCodigo extends StatelessWidget {
  const _TarjetaCodigo();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final codigo = context.watch<Equipo>().codigo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CÓDIGO DEL EQUIPO',
                    style: tema.textTheme.labelSmall
                        ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    codigo,
                    style: tema.textTheme.headlineSmall?.copyWith(letterSpacing: 4),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Copiar código',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: codigo));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaMiembro extends StatelessWidget {
  const _TarjetaMiembro({
    required this.miembro,
    required this.esVos,
    required this.editable,
  });

  final Miembro miembro;
  final bool esVos;
  final bool editable;

  Future<void> _editarRoles(BuildContext context) async {
    final repositorio = context.read<MiembroRepository>();
    final nuevosRoles = await showDialog<List<RolMiembro>>(
      context: context,
      builder: (_) => _DialogoRoles(rolesIniciales: miembro.roles),
    );
    if (nuevosRoles == null) return;
    await repositorio.actualizar(miembro.id, miembro.copyWith(roles: nuevosRoles));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final iniciales = miembro.nombre.trim().isEmpty
        ? '?'
        : miembro.nombre.trim()[0].toUpperCase();

    final foto = miembro.fotoUrl;
    return Card(
      child: ListTile(
        onTap: editable ? () => _editarRoles(context) : null,
        leading: GestureDetector(
          onTap: foto == null ? null : () => mostrarFotoCompleta(context, foto),
          child: CircleAvatar(
            backgroundImage: foto == null ? null : NetworkImage(foto),
            child: foto == null ? Text(iniciales) : null,
          ),
        ),
        title: Text(esVos ? '${miembro.nombre} (vos)' : miembro.nombre),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (miembro.roles.isEmpty)
              Text(
                'Sin rol asignado',
                style: tema.textTheme.bodySmall
                    ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              )
            else
              for (final rol in miembro.roles)
                Chip(
                  label: Text(rol.nombreVisible),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
          ],
        ),
        trailing: editable ? const Icon(Icons.edit_outlined, size: 20) : null,
      ),
    );
  }
}

class _DialogoRoles extends StatefulWidget {
  const _DialogoRoles({required this.rolesIniciales});

  final List<RolMiembro> rolesIniciales;

  @override
  State<_DialogoRoles> createState() => _DialogoRolesState();
}

class _DialogoRolesState extends State<_DialogoRoles> {
  late final Set<RolMiembro> _seleccionados = {...widget.rolesIniciales};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Roles'),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final rol in RolMiembro.values)
            FilterChip(
              label: Text(rol.nombreVisible),
              selected: _seleccionados.contains(rol),
              onSelected: (marcado) => setState(() {
                if (marcado) {
                  _seleccionados.add(rol);
                } else {
                  _seleccionados.remove(rol);
                }
              }),
            ),
        ],
      ),
      actions: [
        AccionesDialogo(
          textoSecundario: 'Cancelar',
          onSecundario: () => Navigator.of(context).pop(),
          textoPrimario: 'Guardar',
          onPrimario: () => Navigator.of(context).pop(_seleccionados.toList()),
        ),
      ],
    );
  }
}
