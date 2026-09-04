import 'package:equatable/equatable.dart';

import 'package:app_alabanzas/core/firestore/model_converter.dart';

/// Una canción del repertorio.
///
/// `contenidoChordPro` guarda la letra y los acordes completos en formato
/// ChordPro (https://www.chordpro.org/chordpro/chordpro-file-format-specification/),
/// usando las directivas de sección estándar del spec, por ejemplo:
///
/// ```
/// {start_of_verse: Verso 1}
/// Cuán [G]grande es tu [D]amor
/// {end_of_verse}
/// {start_of_chorus: Coro}
/// [Em]Grande, [C]grande es tu [G]amor
/// {end_of_chorus}
/// ```
///
/// El parser/renderer (Paso 3) lee esas directivas para dividir la canción
/// en secciones navegables — las mismas secciones que la Capa 2 resalta y
/// avanza automáticamente cuando el líder cambia de parte.
class Cancion extends Equatable {
  const Cancion({
    required this.id,
    required this.titulo,
    this.ritmoId,
    this.artistaId,
    required this.tonoOriginal,
    required this.contenidoChordPro,
    this.bpm,
    this.compas,
    this.etiquetas = const [],
  });

  final String id;
  final String titulo;

  /// Género musical (Adoración, Cumbia, Coritos, ...) — referencia a un
  /// `Ritmo`. Opcional: una canción puede quedar sin clasificar. Distinto
  /// de `etiquetas`, que es texto libre para lo que no encaja en un
  /// género fijo (tema, ocasión, etc.).
  final String? ritmoId;

  /// null = "Varios" / sin artista específico.
  final String? artistaId;

  final String tonoOriginal;
  final String contenidoChordPro;

  /// Tempo en golpes por minuto. Opcional — no todas las iglesias lo cargan.
  final int? bpm;

  /// Ej. "4/4", "6/8". Texto libre a propósito: cubre compases compuestos
  /// sin tener que armar un enum para algo que casi nunca cambia.
  final String? compas;

  final List<String> etiquetas;

  factory Cancion.fromMap(String id, Map<String, dynamic> map) {
    final etiquetasRaw = map['etiquetas'] as List<dynamic>? ?? const [];
    return Cancion(
      id: id,
      titulo: map['titulo'] as String? ?? '',
      ritmoId: map['ritmoId'] as String?,
      artistaId: map['artistaId'] as String?,
      tonoOriginal: map['tonoOriginal'] as String? ?? 'C',
      contenidoChordPro: map['contenidoChordPro'] as String? ?? '',
      bpm: (map['bpm'] as num?)?.toInt(),
      compas: map['compas'] as String?,
      etiquetas: etiquetasRaw.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'ritmoId': ritmoId,
        'artistaId': artistaId,
        'tonoOriginal': tonoOriginal,
        'contenidoChordPro': contenidoChordPro,
        'bpm': bpm,
        'compas': compas,
        'etiquetas': etiquetas,
      };

  Cancion copyWith({
    String? titulo,
    String? ritmoId,
    String? artistaId,
    bool limpiarArtista = false,
    String? tonoOriginal,
    String? contenidoChordPro,
    int? bpm,
    String? compas,
    List<String>? etiquetas,
  }) {
    return Cancion(
      id: id,
      titulo: titulo ?? this.titulo,
      ritmoId: ritmoId ?? this.ritmoId,
      artistaId: limpiarArtista ? null : (artistaId ?? this.artistaId),
      tonoOriginal: tonoOriginal ?? this.tonoOriginal,
      contenidoChordPro: contenidoChordPro ?? this.contenidoChordPro,
      bpm: bpm ?? this.bpm,
      compas: compas ?? this.compas,
      etiquetas: etiquetas ?? this.etiquetas,
    );
  }

  static final converter = ModelConverter<Cancion>(
    fromMap: Cancion.fromMap,
    toMap: (c) => c.toMap(),
  );

  @override
  List<Object?> get props => [
        id,
        titulo,
        ritmoId,
        artistaId,
        tonoOriginal,
        contenidoChordPro,
        bpm,
        compas,
        etiquetas,
      ];
}
