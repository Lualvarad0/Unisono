import 'package:flutter/material.dart';

import '../../domain/chordpro/chordpro_modelo.dart';

/// Una línea de canción ya parseada, con cada acorde flotando arriba de
/// la sílaba donde va — la misma pieza de UI la usan la Vista de
/// detalle (Paso 5) y la vista previa del editor simple, para que lo que
/// se ve mientras se carga una canción sea exactamente lo que después se
/// ve al leerla.
class LineaChordProWidget extends StatelessWidget {
  const LineaChordProWidget({super.key, required this.linea});

  final LineaChordPro linea;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    if (linea.soloLetra.trim().isEmpty &&
        linea.segmentos.every((s) => s.acorde == null)) {
      return const SizedBox(height: 12);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        children: [
          for (final segmento in linea.segmentos)
            if (segmento.acorde != null || segmento.letra.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (segmento.acorde != null)
                      Text(
                        segmento.acorde.toString(),
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: tema.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(segmento.letra, style: tema.textTheme.bodyLarge),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
