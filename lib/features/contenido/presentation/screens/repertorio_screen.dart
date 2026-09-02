import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/firestore/repositorio.dart';
import '../../data/models/artista.dart';
import '../../data/models/cancion.dart';
import 'agregar_alabanza_screen.dart';
import 'detalle_alabanza_screen.dart';

/// Pantalla 7 del prototipo: buscar y navegar el repertorio completo.
///
/// El diseño original tiene chips "Todas / Recientes / Favoritas /
/// Descargadas" — acá solo queda "Todas" con buscador. Favoritas y
/// Descargadas necesitan datos que el modelo todavía no trackea (favorito
/// por usuario, disponibilidad offline por canción) y "Recientes" no tiene
/// sentido sin una fecha de carga guardada — agregar esos chips sin la
/// data real de atrás sería una UI que miente.
class RepertorioScreen extends StatefulWidget {
  const RepertorioScreen({super.key});

  @override
  State<RepertorioScreen> createState() => _RepertorioScreenState();
}

class _RepertorioScreenState extends State<RepertorioScreen> {
  final _busquedaController = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repertorio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar alabanza',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AgregarAlabanzaScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: TextField(
              controller: _busquedaController,
              onChanged: (valor) => setState(() => _busqueda = valor.trim()),
              decoration: const InputDecoration(
                hintText: 'Buscar alabanza...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Cancion>>(
              stream: context.read<Repositorio<Cancion>>().watchAll(),
              builder: (context, snapshotCanciones) {
                if (!snapshotCanciones.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var canciones = snapshotCanciones.data!;
                if (_busqueda.isNotEmpty) {
                  final termino = _busqueda.toLowerCase();
                  canciones = canciones
                      .where((c) => c.titulo.toLowerCase().contains(termino))
                      .toList();
                }
                if (canciones.isEmpty) {
                  return Center(
                    child: Text(
                      _busqueda.isEmpty
                          ? 'Todavía no hay alabanzas cargadas.'
                          : 'Ninguna alabanza coincide con "$_busqueda".',
                      style: tema.textTheme.bodyMedium,
                    ),
                  );
                }
                return StreamBuilder<List<Artista>>(
                  stream: context.read<Repositorio<Artista>>().watchAll(),
                  builder: (context, snapshotArtistas) {
                    final artistasPorId = {
                      for (final a in snapshotArtistas.data ?? const <Artista>[])
                        a.id: a.nombre,
                    };
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      itemCount: canciones.length,
                      itemBuilder: (context, index) {
                        final cancion = canciones[index];
                        final artista = cancion.artistaId == null
                            ? 'Varios'
                            : (artistasPorId[cancion.artistaId] ?? 'Varios');
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(cancion.titulo),
                            subtitle: Text(
                              '$artista · Tono: ${cancion.tonoOriginal}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetalleAlabanzaScreen(cancionId: cancion.id),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
