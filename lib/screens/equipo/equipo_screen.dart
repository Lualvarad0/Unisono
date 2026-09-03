import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';

/// "Mi equipo": la lista de integrantes con sus roles. Cualquiera la puede
/// ver; solo quien tiene el rol Líder puede tocar a alguien para cambiarle
/// los roles — el resto la ve de solo lectura.
class EquipoScreen extends StatelessWidget {
  const EquipoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AutenticacionService>().usuarioActual?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi equipo')),
      body: FutureBuilder<Miembro?>(
        future: uid == null
            ? null
            : context.read<MiembroRepository>().buscarPorUid(uid),
        builder: (context, snapshotYo) {
          final esLider =
              snapshotYo.data?.roles.contains(RolMiembro.lider) ?? false;
          return StreamBuilder<List<Miembro>>(
            stream: context.read<Repositorio<Miembro>>().watchAll(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final integrantes = [...snapshot.data!]
                ..sort((a, b) => a.nombre.compareTo(b.nombre));
              if (integrantes.isEmpty) {
                return const Center(child: Text('Todavía no hay integrantes.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: integrantes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final miembro = integrantes[i];
                  return _TarjetaMiembro(
                    miembro: miembro,
                    esVos: miembro.uid == uid,
                    editable: esLider,
                  );
                },
              );
            },
          );
        },
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

    return Card(
      child: ListTile(
        onTap: editable ? () => _editarRoles(context) : null,
        leading: CircleAvatar(child: Text(iniciales)),
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_seleccionados.toList()),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
