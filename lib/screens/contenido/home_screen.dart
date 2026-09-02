import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/screens/contenido/agregar_alabanza_screen.dart';
import 'package:app_alabanzas/screens/contenido/repertorio_screen.dart';

/// Pantalla 6 del prototipo. Punto de entrada después de Acceso — resumen
/// corto del repertorio y accesos directos a lo que se usa más seguido.
///
/// No incluye la tarjeta "Próximo servicio" del diseño original: esa
/// necesita Setlists/Actividades, que todavía no se construyó (queda para
/// esa ronda).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final uid = context.read<AutenticacionService>().usuarioActual?.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<Miembro?>(
            future: uid == null
                ? null
                : context.read<MiembroRepository>().buscarPorUid(uid),
            builder: (context, snapshot) {
              final nombre = snapshot.data?.nombre;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buenos días', style: tema.textTheme.bodyLarge),
                  Text(
                    nombre ?? '',
                    style: tema.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<Cancion>>(
            stream: context.read<Repositorio<Cancion>>().watchAll(),
            builder: (context, snapshot) {
              final canciones = snapshot.data ?? const <Cancion>[];
              return Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: tema.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    snapshot.connectionState == ConnectionState.waiting
                        ? 'Sincronizando repertorio...'
                        : '${canciones.length} alabanzas en el repertorio',
                    style: tema.textTheme.bodyMedium
                        ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RepertorioScreen()),
                  ),
                  icon: const Icon(Icons.library_music_outlined),
                  label: const Text('Repertorio'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AgregarAlabanzaScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Tu repertorio',
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Cancion>>(
            stream: context.read<Repositorio<Cancion>>().watchAll(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                );
              }
              final canciones = snapshot.data!;
              if (canciones.isEmpty) {
                return Text(
                  'Todavía no cargaste ninguna alabanza.',
                  style: tema.textTheme.bodyMedium
                      ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                );
              }
              final destacadas = canciones.take(3).toList();
              return Column(
                children: [
                  for (final cancion in destacadas)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(cancion.titulo),
                        subtitle: Text('Tono: ${cancion.tonoOriginal}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RepertorioScreen(),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
