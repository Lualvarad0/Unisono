import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/firestore/repositorio.dart';
import '../../../notas/data/models/nota.dart';
import '../../../notas/data/repositories/nota_repository.dart';
import '../../../notas/presentation/agregar_nota_screen.dart';
import '../../data/models/cancion.dart';
import '../../domain/chordpro/chordpro_modelo.dart';
import '../../domain/chordpro/chordpro_parser.dart';
import '../widgets/linea_chordpro_widget.dart';

/// Notas cromáticas en orden, para el selector de tonalidad — un mapeo
/// chico y local a esta pantalla, no una regla de negocio del parser.
const _escalaCromatica = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', //
];

/// Pantalla 8: letra + acordes de una canción, ya parseados por secciones,
/// con las notas del equipo intercaladas donde corresponden y un selector
/// de tonalidad que transporta en vivo (sin guardar nada hasta que se
/// confirme — ver `_semitonos`).
class DetalleAlabanzaScreen extends StatefulWidget {
  const DetalleAlabanzaScreen({super.key, required this.cancionId});

  final String cancionId;

  @override
  State<DetalleAlabanzaScreen> createState() => _DetalleAlabanzaScreenState();
}

class _DetalleAlabanzaScreenState extends State<DetalleAlabanzaScreen> {
  int _semitonos = 0;

  void _cambiarTono(Cancion cancion, String nuevaNota) {
    final origen = _escalaCromatica.indexOf(cancion.tonoOriginal);
    final destino = _escalaCromatica.indexOf(nuevaNota);
    if (origen == -1 || destino == -1) return;
    setState(() => _semitonos = (destino - origen) % 12);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Cancion?>(
        stream: context
            .read<Repositorio<Cancion>>()
            .watchAll()
            .map((lista) => lista.where((c) => c.id == widget.cancionId).firstOrNull),
        builder: (context, snapshot) {
          final cancion = snapshot.data;
          if (cancion == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _Contenido(
            cancion: cancion,
            semitonos: _semitonos,
            onCambiarTono: (nota) => _cambiarTono(cancion, nota),
          );
        },
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.cancion,
    required this.semitonos,
    required this.onCambiarTono,
  });

  final Cancion cancion;
  final int semitonos;
  final ValueChanged<String> onCambiarTono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final origenIndice = _escalaCromatica.indexOf(cancion.tonoOriginal);
    final tonoActual = origenIndice == -1
        ? cancion.tonoOriginal
        : _escalaCromatica[(origenIndice + semitonos) % 12];

    final cancionChordPro =
        ChordProParser.parse(cancion.contenidoChordPro).transponer(semitonos);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(cancion.titulo),
          floating: true,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text('Original ${cancion.tonoOriginal}',
                        style: tema.textTheme.bodyMedium),
                    Text('Actual $tonoActual',
                        style: tema.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (cancion.bpm != null)
                      Text('${cancion.bpm} BPM', style: tema.textTheme.bodyMedium),
                    if (cancion.compas != null)
                      Text(cancion.compas!, style: tema.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Tonalidad',
                    style: tema.textTheme.labelLarge
                        ?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _escalaCromatica.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final nota = _escalaCromatica[i];
                      final seleccionada = nota == tonoActual;
                      return ChoiceChip(
                        label: Text(nota),
                        selected: seleccionada,
                        onSelected: (_) => onCambiarTono(nota),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          sliver: SliverList.list(
            children: [
              for (final seccion in cancionChordPro.secciones)
                _SeccionWidget(
                  seccion: seccion,
                  cancionId: cancion.id,
                  cancionTitulo: cancion.titulo,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeccionWidget extends StatelessWidget {
  const _SeccionWidget({
    required this.seccion,
    required this.cancionId,
    required this.cancionTitulo,
  });

  final SeccionChordPro seccion;
  final String cancionId;
  final String cancionTitulo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                seccion.etiqueta.toUpperCase(),
                style: tema.textTheme.labelLarge?.copyWith(
                  color: tema.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.note_add_outlined, size: 20),
                tooltip: 'Agregar nota en esta sección',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AgregarNotaScreen(
                      cancionId: cancionId,
                      cancionTitulo: cancionTitulo,
                      seccionEtiqueta: seccion.etiqueta,
                    ),
                  ),
                ),
              ),
            ],
          ),
          for (final linea in seccion.lineas) LineaChordProWidget(linea: linea),
          _NotasDeSeccion(cancionId: cancionId, seccionEtiqueta: seccion.etiqueta),
        ],
      ),
    );
  }
}

class _NotasDeSeccion extends StatelessWidget {
  const _NotasDeSeccion({required this.cancionId, required this.seccionEtiqueta});

  final String cancionId;
  final String seccionEtiqueta;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Nota>>(
      stream: context.read<NotaRepository>().watchAll(),
      builder: (context, snapshot) {
        final notas = (snapshot.data ?? const <Nota>[]).where(
          (n) => n.cancionId == cancionId && n.seccionEtiqueta == seccionEtiqueta,
        );
        if (notas.isEmpty) return const SizedBox.shrink();
        final tema = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final nota in notas)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    nota.texto,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
