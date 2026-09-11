import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/core/genero_colores.dart';
import 'package:app_alabanzas/core/theme/app_theme.dart';
import 'package:app_alabanzas/models/artista.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/ritmo.dart';
import 'package:app_alabanzas/screens/contenido/agregar_alabanza_screen.dart';
import 'package:app_alabanzas/screens/contenido/detalle_alabanza_screen.dart';
import 'package:app_alabanzas/widgets/dialogo_nuevo_genero.dart';

/// Color neutro para los cuadros que no son "un género de verdad" —
/// "Sin género" y "+ Nuevo género" — para que no compitan por un lugar
/// en la paleta de colores real.
const _colorNeutro = Color(0xFF4A4A52);

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
  // "Sin género" también filtra (a canciones con ritmoId nulo) pero no
  // tiene un id de Ritmo real — no puede representarse con
  // `_generoFiltro`, así que es un flag aparte.
  bool _soloSinGenero = false;
  bool _explorando = true;

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _elegirGenero(String id) {
    setState(() {
      _generoFiltro = id;
      _soloSinGenero = false;
      _explorando = false;
    });
  }

  void _elegirSinGenero() {
    setState(() {
      _generoFiltro = null;
      _soloSinGenero = true;
      _explorando = false;
    });
  }

  void _verTodas() {
    setState(() {
      _generoFiltro = null;
      _soloSinGenero = false;
      _explorando = false;
    });
  }

  void _volverAExplorar() {
    setState(() {
      _generoFiltro = null;
      _soloSinGenero = false;
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
              if (_busqueda.isEmpty && !_explorando)
                _EncabezadoFiltro(
                  color: _generoFiltro != null
                      ? colorDeGenero(generos, _generoFiltro!)
                      : null,
                  titulo: _soloSinGenero
                      ? 'Sin género'
                      : (_generoFiltro != null
                          ? (generosPorId[_generoFiltro] ?? '')
                          : 'Todas las alabanzas'),
                  onVolver: _volverAExplorar,
                ),
              Expanded(
                child: StreamBuilder<List<Cancion>>(
                  stream: context.read<Repositorio<Cancion>>().watchAll(),
                  builder: (context, snapshotCanciones) {
                    if (!snapshotCanciones.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final todas = snapshotCanciones.data!;

                    if (_busqueda.isEmpty && _explorando) {
                      return _ExplorarGeneros(
                        generos: generos,
                        canciones: todas,
                        onElegirGenero: _elegirGenero,
                        onElegirSinGenero: _elegirSinGenero,
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
                    if (_soloSinGenero) {
                      canciones = canciones.where((c) => c.ritmoId == null).toList();
                    } else if (_generoFiltro != null) {
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
/// Siempre hay dos cuadros extra al final: "Sin género" (si hay alguna
/// canción sin clasificar — si no, ninguna forma de encontrarla sin
/// pasar por "Ver todas") y "+ Nuevo género".
class _ExplorarGeneros extends StatelessWidget {
  const _ExplorarGeneros({
    required this.generos,
    required this.canciones,
    required this.onElegirGenero,
    required this.onElegirSinGenero,
    required this.onVerTodas,
  });

  final List<Ritmo> generos;
  final List<Cancion> canciones;
  final ValueChanged<String> onElegirGenero;
  final VoidCallback onElegirSinGenero;
  final VoidCallback onVerTodas;

  static bool _esNueva(Cancion c) =>
      c.creadaEn != null &&
      DateTime.now().difference(c.creadaEn!) <= const Duration(days: 7);

  Future<void> _agregarGenero(BuildContext context) async {
    final repositorio = context.read<Repositorio<Ritmo>>();
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => const DialogoNuevoGenero(),
    );
    if (nombre == null || nombre.isEmpty) return;
    // Sin distinguir mayúsculas, para no terminar con "Adoración" y
    // "adoración" como dos géneros separados — mismo criterio que al
    // agregar un género desde Nueva alabanza.
    for (final ritmo in generos) {
      if (ritmo.nombre.toLowerCase() == nombre.toLowerCase()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ya existía el género "${ritmo.nombre}".')),
          );
        }
        return;
      }
    }
    await repositorio.crear(Ritmo(id: '', nombre: nombre));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final conCanciones = [
      for (final genero in generos)
        if (canciones.any((c) => c.ritmoId == genero.id)) genero,
    ];
    final sinGenero = canciones.where((c) => c.ritmoId == null).toList();
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
        if (conCanciones.isEmpty && sinGenero.isEmpty)
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
            itemCount: conCanciones.length + (sinGenero.isNotEmpty ? 1 : 0) + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
            ),
            itemBuilder: (context, i) {
              if (i < conCanciones.length) {
                final genero = conCanciones[i];
                final delGenero =
                    canciones.where((c) => c.ritmoId == genero.id).toList();
                return _TarjetaGenero(
                  nombre: genero.nombre,
                  cantidad: delGenero.length,
                  color: colorDeGenero(generos, genero.id),
                  nuevo: delGenero.any(_esNueva),
                  onTap: () => onElegirGenero(genero.id),
                );
              }
              final indiceExtra = i - conCanciones.length;
              if (sinGenero.isNotEmpty && indiceExtra == 0) {
                return _TarjetaGenero(
                  nombre: 'Sin género',
                  cantidad: sinGenero.length,
                  color: _colorNeutro,
                  nuevo: false,
                  onTap: onElegirSinGenero,
                );
              }
              return _TarjetaAgregarGenero(onTap: () => _agregarGenero(context));
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

/// Cuadro con borde punteado en vez de relleno sólido — visualmente
/// "vacío" a propósito, para que se lea como "agregar algo acá" y no
/// como un género más de la lista.
class _TarjetaAgregarGenero extends StatelessWidget {
  const _TarjetaAgregarGenero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: tema.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: tema.colorScheme.onSurfaceVariant),
                const SizedBox(height: 4),
                Text(
                  'Nuevo género',
                  style: tema.textTheme.labelMedium
                      ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Franja de color arriba de la lista filtrada, con el mismo color del
/// cuadro que se tocó — la lista no queda "desconectada" visualmente del
/// cuadro que llevó hasta ahí. `color` nulo (para "Todas las alabanzas")
/// usa una superficie neutra en vez de forzar un color.
class _EncabezadoFiltro extends StatelessWidget {
  const _EncabezadoFiltro({
    required this.color,
    required this.titulo,
    required this.onVolver,
  });

  final Color? color;
  final String titulo;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final conColor = color != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: color ?? tema.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: conColor ? Colors.white : tema.colorScheme.onSurface,
            ),
            tooltip: 'Volver a géneros',
            onPressed: onVolver,
          ),
          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: conColor ? Colors.white : tema.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
