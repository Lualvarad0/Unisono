import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_alabanzas/core/firestore/repositorio.dart';
import 'package:app_alabanzas/models/actividad.dart';
import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/chordpro/chordpro_modelo.dart';
import 'package:app_alabanzas/models/miembro.dart';
import 'package:app_alabanzas/repositories/miembro_repository.dart';
import 'package:app_alabanzas/screens/actividades/actividad_utils.dart';
import 'package:app_alabanzas/services/autenticacion_service.dart';
import 'package:app_alabanzas/services/chordpro/chordpro_parser.dart';

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Vista de escenario: una canción a pantalla completa, una sección a la
/// vez, con tipografía grande para leer de lejos — 26–40px la letra,
/// 15–17px el acorde (ver doc de `AppTheme`, "Vista de Músico y
/// Cantante").
///
/// Quien tiene rol Músico o Líder ve letra + acordes; quien es solo
/// Cantante ve nomás la letra, sin ruido visual.
///
/// El líder controla el avance (desliza/toca las flechas) y eso
/// actualiza `Actividad.seccionActivaIndice` en Firestore en tiempo
/// real; todo el que esté mirando esta misma canción activa sigue esa
/// posición automáticamente, sin poder desviarse — es "transmitir" con
/// lo que ya hay (Firestore), no la Capa 2 P2P que todavía no está
/// conectada (ver `PrincipalShellScreen`). Si alguien abre una canción
/// que no es la activa, la navega libre por su cuenta — no hay nada que
/// seguir ahí.
class VistaEnVivoScreen extends StatefulWidget {
  const VistaEnVivoScreen({
    super.key,
    required this.actividadId,
    required this.cancionId,
    required this.esLider,
  });

  final String actividadId;
  final String cancionId;
  final bool esLider;

  @override
  State<VistaEnVivoScreen> createState() => _VistaEnVivoScreenState();
}

class _VistaEnVivoScreenState extends State<VistaEnVivoScreen> {
  final _paginaController = PageController();

  @override
  void dispose() {
    _paginaController.dispose();
    super.dispose();
  }

  void _irASeccion(int indice) {
    if (!_paginaController.hasClients) return;
    _paginaController.animateToPage(
      indice,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _transmitirSeccion(Actividad actividad, int indice) async {
    if (!widget.esLider) return;
    final repositorio = context.read<Repositorio<Actividad>>();
    await repositorio.actualizar(
      actividad.id,
      actividad.copyWith(cancionActivaId: widget.cancionId, seccionActivaIndice: indice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AutenticacionService>().usuarioActual?.uid;
    return Scaffold(
      body: FutureBuilder<Miembro?>(
        future: uid == null
            ? null
            : context.read<MiembroRepository>().buscarPorUid(uid),
        builder: (context, snapshotYo) {
          final roles = snapshotYo.data?.roles ?? const <RolMiembro>[];
          final mostrarAcordes =
              roles.contains(RolMiembro.musico) || roles.contains(RolMiembro.lider);
          return StreamBuilder<Cancion?>(
            stream: context
                .read<Repositorio<Cancion>>()
                .watchAll()
                .map((l) => l.where((c) => c.id == widget.cancionId).firstOrNull),
            builder: (context, snapshotCancion) {
              final cancion = snapshotCancion.data;
              if (cancion == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return StreamBuilder<Actividad?>(
                stream: context
                    .read<Repositorio<Actividad>>()
                    .watchAll()
                    .map((l) => l.where((a) => a.id == widget.actividadId).firstOrNull),
                builder: (context, snapshotActividad) {
                  final actividad = snapshotActividad.data;
                  final entrada = actividad?.setlist
                      .where((e) => e.cancionId == widget.cancionId)
                      .firstOrNull;
                  final cancionChordPro = ChordProParser.parse(cancion.contenidoChordPro)
                      .transponer(entrada?.tonoAsignado ?? 0);
                  final esCancionActiva =
                      actividad != null && actividad.cancionActivaId == widget.cancionId;
                  final siguiendoLider = !widget.esLider && esCancionActiva;

                  if (siguiendoLider) {
                    final indiceRemoto = actividad.seccionActivaIndice;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_paginaController.hasClients) return;
                      final actual = _paginaController.page?.round();
                      if (actual != indiceRemoto) _irASeccion(indiceRemoto);
                    });
                  }

                  return _Lector(
                    tituloCancion: cancion.titulo,
                    tonoResultante: entrada == null
                        ? cancion.tonoOriginal
                        : transponerTono(cancion.tonoOriginal, entrada.tonoAsignado),
                    secciones: cancionChordPro.secciones,
                    mostrarAcordes: mostrarAcordes,
                    paginaController: _paginaController,
                    siguiendoLider: siguiendoLider,
                    esLider: widget.esLider,
                    transmitiendoEstaCancion: widget.esLider && esCancionActiva,
                    onCambiarPagina: actividad == null
                        ? null
                        : (indice) => _transmitirSeccion(actividad, indice),
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

class _Lector extends StatefulWidget {
  const _Lector({
    required this.tituloCancion,
    required this.tonoResultante,
    required this.secciones,
    required this.mostrarAcordes,
    required this.paginaController,
    required this.siguiendoLider,
    required this.esLider,
    required this.transmitiendoEstaCancion,
    required this.onCambiarPagina,
  });

  final String tituloCancion;
  final String tonoResultante;
  final List<SeccionChordPro> secciones;
  final bool mostrarAcordes;
  final PageController paginaController;
  final bool siguiendoLider;
  final bool esLider;
  final bool transmitiendoEstaCancion;
  final ValueChanged<int>? onCambiarPagina;

  @override
  State<_Lector> createState() => _LectorState();
}

class _LectorState extends State<_Lector> {
  int _paginaActual = 0;

  void _onPageChanged(int indice) {
    setState(() => _paginaActual = indice);
    widget.onCambiarPagina?.call(indice);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    if (widget.secciones.isEmpty) {
      return SafeArea(
        child: Column(
          children: [
            _Encabezado(
              titulo: widget.tituloCancion,
              tono: widget.tonoResultante,
              transmitiendo: widget.transmitiendoEstaCancion,
              siguiendoLider: widget.siguiendoLider,
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Esta alabanza todavía no tiene letra cargada.',
                  style: tema.textTheme.bodyLarge
                      ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return SafeArea(
      child: Column(
        children: [
          _Encabezado(
            titulo: widget.tituloCancion,
            tono: widget.tonoResultante,
            transmitiendo: widget.transmitiendoEstaCancion,
            siguiendoLider: widget.siguiendoLider,
          ),
          Expanded(
            child: PageView.builder(
              controller: widget.paginaController,
              physics: widget.siguiendoLider
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemCount: widget.secciones.length,
              itemBuilder: (context, i) => _SeccionEnVivo(
                seccion: widget.secciones[i],
                mostrarAcordes: widget.mostrarAcordes,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 32,
                  onPressed: _paginaActual == 0
                      ? null
                      : () => widget.paginaController.previousPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                          ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${_paginaActual + 1} / ${widget.secciones.length}',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium
                        ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  iconSize: 32,
                  onPressed: _paginaActual >= widget.secciones.length - 1
                      ? null
                      : () => widget.paginaController.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.titulo,
    required this.tono,
    required this.transmitiendo,
    required this.siguiendoLider,
  });

  final String titulo;
  final String tono;
  final bool transmitiendo;
  final bool siguiendoLider;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text('Tono $tono',
                    style: tema.textTheme.bodySmall
                        ?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (transmitiendo)
            Chip(
              avatar: Icon(Icons.sensors, size: 16, color: tema.colorScheme.primary),
              label: const Text('Transmitiendo'),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else if (siguiendoLider)
            Icon(Icons.sync, size: 20, color: tema.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Una sección completa (Verso 1, Coro, ...) a pantalla — letra grande
/// (26–40px según cuánto entre) con el acorde chico arriba de cada
/// palabra si `mostrarAcordes`, o solo la letra si no.
class _SeccionEnVivo extends StatelessWidget {
  const _SeccionEnVivo({required this.seccion, required this.mostrarAcordes});

  final SeccionChordPro seccion;
  final bool mostrarAcordes;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tamanoLetra = seccion.lineas.length > 6 ? 26.0 : 34.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            seccion.etiqueta.toUpperCase(),
            style: tema.textTheme.labelLarge?.copyWith(
              color: tema.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          for (final linea in seccion.lineas)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: mostrarAcordes
                  ? Wrap(
                      children: [
                        for (final segmento in linea.segmentos)
                          if (segmento.acorde != null || segmento.letra.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    child: segmento.acorde != null
                                        ? Text(
                                            segmento.acorde.toString(),
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: tema.colorScheme.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Text(
                                    segmento.letra,
                                    style: TextStyle(fontSize: tamanoLetra, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    )
                  : Text(
                      linea.soloLetra,
                      style: TextStyle(fontSize: tamanoLetra, height: 1.3),
                    ),
            ),
        ],
      ),
    );
  }
}
