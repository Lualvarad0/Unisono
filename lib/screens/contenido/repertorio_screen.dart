import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/models/artista.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/ritmo.dart';
import 'package:app_alabanzas/screens/contenido/agregar_alabanza_screen.dart';
import 'package:app_alabanzas/screens/contenido/detalle_alabanza_screen.dart';

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
  String? _generoFiltro;

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
      body: StreamBuilder<List<Ritmo>>(
        stream: context.read<Repositorio<Ritmo>>().watchAll(),
        builder: (context, snapshotGeneros) {
          final generos = [...snapshotGeneros.data ?? const <Ritmo>[]]
            ..sort((a, b) => a.nombre.compareTo(b.nombre));
          final generosPorId = {for (final g in generos) g.id: g.nombre};
          return Column(
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
              if (generos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: generos.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return ChoiceChip(
                            label: const Text('Todas'),
                            selected: _generoFiltro == null,
                            onSelected: (_) =>
                                setState(() => _generoFiltro = null),
                          );
                        }
                        final genero = generos[i - 1];
                        return ChoiceChip(
                          label: Text(genero.nombre),
                          selected: _generoFiltro == genero.id,
                          onSelected: (_) =>
                              setState(() => _generoFiltro = genero.id),
                        );
                      },
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
                    if (_generoFiltro != null) {
                      canciones = canciones
                          .where((c) => c.ritmoId == _generoFiltro)
                          .toList();
                    }
                    if (canciones.isEmpty) {
                      return Center(
                        child: Text(
                          _busqueda.isEmpty && _generoFiltro == null
                              ? 'Todavía no hay alabanzas cargadas.'
                              : 'Ninguna alabanza coincide con el filtro.',
                          style: tema.textTheme.bodyMedium,
                        ),
                      );
                    }
                    return StreamBuilder<List<Artista>>(
                      stream: context.read<Repositorio<Artista>>().watchAll(),
                      builder: (context, snapshotArtistas) {
                        final artistasPorId = {
                          for (final a
                              in snapshotArtistas.data ?? const <Artista>[])
                            a.id: a.nombre,
                        };
                        String nombreArtista(Cancion c) => c.artistaId == null
                            ? 'Varios'
                            : (artistasPorId[c.artistaId] ?? 'Varios');

                        // Con un género elegido, "Ritmo -> Artista ->
                        // Canción" (ver doc de Ritmo) deja de ser solo un
                        // filtro: agrupa la lista por artista, así el
                        // repertorio de ese género se navega en dos
                        // niveles en vez de una lista plana larga.
                        if (_generoFiltro == null) {
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                            itemCount: canciones.length,
                            itemBuilder: (context, index) => _TarjetaCancion(
                              cancion: canciones[index],
                              artista: nombreArtista(canciones[index]),
                              genero: generosPorId[canciones[index].ritmoId],
                            ),
                          );
                        }

                        final porArtista = <String, List<Cancion>>{};
                        for (final cancion in canciones) {
                          porArtista
                              .putIfAbsent(nombreArtista(cancion), () => [])
                              .add(cancion);
                        }
                        final artistasOrdenados = porArtista.keys.toList()
                          ..sort();

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                          children: [
                            for (final artista in artistasOrdenados) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 16, 8, 4),
                                child: Text(
                                  artista.toUpperCase(),
                                  style: tema.textTheme.labelLarge?.copyWith(
                                    color: tema.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              for (final cancion in porArtista[artista]!
                                ..sort((a, b) => a.titulo.compareTo(b.titulo)))
                                _TarjetaCancion(
                                  cancion: cancion,
                                  artista: artista,
                                  genero: generosPorId[cancion.ritmoId],
                                ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaCancion extends StatelessWidget {
  const _TarjetaCancion({
    required this.cancion,
    required this.artista,
    required this.genero,
  });

  final Cancion cancion;
  final String artista;
  final String? genero;

  @override
  Widget build(BuildContext context) {
    final subtitulo = [
      artista,
      'Tono: ${cancion.tonoOriginal}',
      if (genero != null) genero!,
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        title: Text(cancion.titulo),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetalleAlabanzaScreen(cancionId: cancion.id),
          ),
        ),
      ),
    );
  }
}
