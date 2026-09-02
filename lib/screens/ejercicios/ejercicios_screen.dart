import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/models/ejercicio.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/ejercicio_repository.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/screens/ejercicios/agregar_ejercicio_screen.dart';

/// Consignas de práctica que el líder deja para el equipo. Cualquiera ve
/// la lista y marca las suyas como practicadas; solo el líder puede
/// agregar ejercicios nuevos, y es el único que ve el detalle de quién ya
/// practicó cada uno (el resto solo ve el conteo).
class EjerciciosScreen extends StatefulWidget {
  const EjerciciosScreen({super.key});

  @override
  State<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends State<EjerciciosScreen> {
  late final Future<Miembro?> _miembroYo;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AutenticacionService>().usuarioActual?.uid;
    _miembroYo = uid == null
        ? Future.value(null)
        : context.read<MiembroRepository>().buscarPorUid(uid);
  }

  @override
  Widget build(BuildContext context) {
    final miUid = context.read<AutenticacionService>().usuarioActual?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicios')),
      body: FutureBuilder<Miembro?>(
        future: _miembroYo,
        builder: (context, snapshotYo) {
          final esLider =
              snapshotYo.data?.roles.contains(RolMiembro.lider) ?? false;
          return StreamBuilder<List<Miembro>>(
            stream: context.read<Repositorio<Miembro>>().watchAll(),
            builder: (context, snapshotMiembros) {
              final miembros = snapshotMiembros.data ?? const <Miembro>[];
              final nombrePorUid = {
                for (final m in miembros)
                  if (m.uid != null) m.uid!: m.nombre,
              };
              return StreamBuilder<List<Ejercicio>>(
                stream: context.read<Repositorio<Ejercicio>>().watchAll(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final ejercicios = snapshot.data!;
                  if (ejercicios.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          esLider
                              ? 'Todavía no dejaste ningún ejercicio. '
                                  'Tocá "+ Ejercicio" para agregar uno.'
                              : 'Todavía no hay ejercicios para practicar.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: ejercicios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _TarjetaEjercicio(
                      ejercicio: ejercicios[i],
                      miUid: miUid,
                      totalIntegrantes: miembros.length,
                      esLider: esLider,
                      nombrePorUid: nombrePorUid,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<Miembro?>(
        future: _miembroYo,
        builder: (context, snapshot) {
          final esLider =
              snapshot.data?.roles.contains(RolMiembro.lider) ?? false;
          if (!esLider) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AgregarEjercicioScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Ejercicio'),
          );
        },
      ),
    );
  }
}

class _TarjetaEjercicio extends StatelessWidget {
  const _TarjetaEjercicio({
    required this.ejercicio,
    required this.miUid,
    required this.totalIntegrantes,
    required this.esLider,
    required this.nombrePorUid,
  });

  final Ejercicio ejercicio;
  final String? miUid;
  final int totalIntegrantes;
  final bool esLider;
  final Map<String, String> nombrePorUid;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final yaLoHice = miUid != null && ejercicio.completadoPor(miUid!);
    final completados = ejercicio.completadoPorUids.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: yaLoHice,
              onChanged: miUid == null
                  ? null
                  : (marcado) => context.read<EjercicioRepository>().marcarCompletado(
                        ejercicio.id,
                        miUid!,
                        completado: marcado ?? false,
                      ),
              title: Text(
                ejercicio.titulo,
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: yaLoHice ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ejercicio.descripcion.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(ejercicio.descripcion),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      totalIntegrantes == 0
                          ? '$completados practicaron'
                          : '$completados/$totalIntegrantes practicaron',
                      style: tema.textTheme.bodySmall
                          ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            if (esLider && ejercicio.completadoPorUids.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final uidCompleto in ejercicio.completadoPorUids)
                      Chip(
                        avatar: const Icon(Icons.check, size: 14),
                        label: Text(nombrePorUid[uidCompleto] ?? 'Alguien'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
