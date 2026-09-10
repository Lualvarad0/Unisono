import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/core/theme/app_theme.dart';
import 'package:app_alabanzas/models/artista.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/ritmo.dart';
import 'package:app_alabanzas/screens/contenido/agregar_alabanza_screen.dart';
import 'package:app_alabanzas/screens/contenido/detalle_alabanza_screen.dart';

/// Pantalla 7 del prototipo: buscar y navegar el repertorio completo.
///
/// Sin buscar nada todavía, se explora por género con cuadros de colores
/// (a la Spotify) en vez de una lista larga de entrada — cada cuadro dice
/// cuántas alabanzas tiene y marca "NUEVO" si alguna se cargó hace poco.
/// Al tocar un género, o al escribir en el buscador, aparece la lista de
/// alabanzas de ese recorte — agrupada por artista si hay más de uno, o
/// plana (para buscar por nombre) si no. "Favoritas" y "Descargadas" del
/// diseño original quedan afuera: necesitan datos que el modelo todavía no
/// trackea (favorito por usuario, disponibilidad offline por canción) —
/// agregar esos chips sin la data real de atrás sería una UI que miente.
class RepertorioScreen extends StatefulWidget {
  const RepertorioScreen({super.key});

  @override
  State<RepertorioScreen> createState() => _RepertorioScreenState();
}

class _RepertorioScreenState extends State<RepertorioScreen> {
  final _busquedaController = TextEditingController();
  String _busqueda = '';
  String? _generoFiltro;
  bool _explorando = true;

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _elegirGenero(String id) {
    setState(() {
      _generoFiltro = id;
      _explorando = false;
    });
  }

  void _verTodas() {
    setState(() {
      _generoFiltro = null;
      _explorando = false;
    });
  }

  void _volverAExplorar() {
    setState(() {
      _generoFiltro = null;
      _explorando = true;
    });
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
              if (_busqueda.isEmpty && _generoFiltro != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 20, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Volver a géneros',
                        onPressed: _volverAExplorar,
                      ),
                      Text(
                        generosPorId[_generoFiltro] ?? '',
                        style: tema.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: StreamBuilder<List<Cancion>>(
                  stream: context.read<Repositorio<Cancion>>().watchAll(),
                  builder: (context, snapshotCanciones) {
                    if (!snapshotCanciones.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final todas = snapshotCanciones.data!;

                    if (_busqueda.isEmpty && _generoFiltro == null && _explorando) {
                      return _ExplorarGeneros(
                        generos: generos,
                        canciones: todas,
                        onElegirGenero: _elegirGenero,
                        onVerTodas: _verTodas,
                      );
                    }

                    var canciones = todas;
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
                          'Ninguna alabanza coincide con el filtro.',
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

                        final porArtista = <String, List<Cancion>>{};
                        for (final cancion in canciones) {
                          porArtista
                              .putIfAbsent(nombreArtista(cancion), () => [])
                              .add(cancion);
                        }
                        // Con un solo grupo (todo "Varios", o un solo
                        // artista) la agrupación no suma nada — queda
                        // como lista plana, buscable por nombre.
                        if (porArtista.length <= 1) {
                          final ordenadas = [...canciones]
                            ..sort((a, b) => a.titulo.compareTo(b.titulo));
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                            itemCount: ordenadas.length,
                            itemBuilder: (context, index) => _TarjetaCancion(
                              cancion: ordenadas[index],
                              artista: nombreArtista(ordenadas[index]),
                              genero: generosPorId[ordenadas[index].ritmoId],
                            ),
                          );
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

/// Cuadrícula de géneros de dos columnas, un cuadro de color por género —
/// la pantalla de entrada al repertorio en vez de una lista plana larga.
class _ExplorarGeneros extends StatelessWidget {
  const _ExplorarGeneros({
    required this.generos,
    required this.canciones,
    required this.onElegirGenero,
    required this.onVerTodas,
  });

  final List<Ritmo> generos;
  final List<Cancion> canciones;
  final ValueChanged<String> onElegirGenero;
  final VoidCallback onVerTodas;

  /// Paleta fija, un color por posición en la grilla — no depende del
  /// nombre del género así que no hace falta mantenerla sincronizada con
  /// qué géneros existen.
  static const _colores = [
    Color(0xFFE91429),
    Color(0xFF1E3264),
    Color(0xFF8D67AB),
    Color(0xFF148A08),
    Color(0xFFE8115B),
    Color(0xFFBA5D07),
    Color(0xFF477D95),
    Color(0xFF509BF5),
  ];

  static bool _esNueva(Cancion c) =>
      c.creadaEn != null &&
      DateTime.now().difference(c.creadaEn!) <= const Duration(days: 7);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final conCanciones = [
      for (final genero in generos)
        if (canciones.any((c) => c.ritmoId == genero.id)) genero,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Explorar por género',
              style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton(onPressed: onVerTodas, child: const Text('Ver todas')),
          ],
        ),
        const SizedBox(height: 8),
        if (conCanciones.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Todavía no hay alabanzas cargadas.',
              style: tema.textTheme.bodyMedium
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: conCanciones.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
            ),
            itemBuilder: (context, i) {
              final genero = conCanciones[i];
              final delGenero =
                  canciones.where((c) => c.ritmoId == genero.id).toList();
              return _TarjetaGenero(
                nombre: genero.nombre,
                cantidad: delGenero.length,
                color: _colores[i % _colores.length],
                nuevo: delGenero.any(_esNueva),
                onTap: () => onElegirGenero(genero.id),
              );
            },
          ),
      ],
    );
  }
}

class _TarjetaGenero extends StatelessWidget {
  const _TarjetaGenero({
    required this.nombre,
    required this.cantidad,
    required this.color,
    required this.nuevo,
    required this.onTap,
  });

  final String nombre;
  final int cantidad;
  final Color color;
  final bool nuevo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -14,
              bottom: -18,
              child: Icon(
                Icons.music_note_rounded,
                size: 84,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    cantidad == 1 ? '1 alabanza' : '$cantidad alabanzas',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (nuevo)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'NUEVO',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
    final tema = Theme.of(context);
    final subtitulo = [
      artista,
      'Tono: ${cancion.tonoOriginal}',
      if (genero != null) genero!,
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        title: Text(cancion.titulo),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(subtitulo),
            const SizedBox(height: 2),
            // El caché de Firestore es ilimitado (ver
            // configurarFirestore) — si esta canción está en esta
            // lista, ya la sincronizó al menos una vez y queda
            // guardada en el celular para siempre, sin importar si
            // hay internet ahora mismo.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 13, color: AppTheme.exito),
                const SizedBox(width: 4),
                Text(
                  'Disponible offline',
                  style: tema.textTheme.bodySmall?.copyWith(color: AppTheme.exito),
                ),
              ],
            ),
          ],
        ),
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
