import 'package:equatable/equatable.dart';

/// Una entrada del setlist de una Actividad. No es un documento propio de
/// Firestore: vive embebida en el arreglo `setlist` del documento
/// `Actividad`, porque siempre se lee y se escribe como una unidad (armar
/// o reordenar un setlist completo), así que no gana nada estar en su
/// propia subcolección — y una subcolección no se lee de un tirón offline.
class SetlistEntry extends Equatable {
  const SetlistEntry({
    required this.cancionId,
    required this.orden,
    required this.cantanteId,
    this.tonoAsignado = 0,
  });

  final String cancionId;
  final int orden;

  /// Referencia a `Miembro.id`.
  final String cantanteId;

  /// Offset en semitonos respecto al tono original de la canción, para
  /// ese día puntual.
  final int tonoAsignado;

  factory SetlistEntry.fromMap(Map<String, dynamic> map) {
    return SetlistEntry(
      cancionId: map['cancionId'] as String? ?? '',
      orden: (map['orden'] as num?)?.toInt() ?? 0,
      cantanteId: map['cantanteId'] as String? ?? '',
      tonoAsignado: (map['tonoAsignado'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'cancionId': cancionId,
        'orden': orden,
        'cantanteId': cantanteId,
        'tonoAsignado': tonoAsignado,
      };

  SetlistEntry copyWith({
    String? cancionId,
    int? orden,
    String? cantanteId,
    int? tonoAsignado,
  }) {
    return SetlistEntry(
      cancionId: cancionId ?? this.cancionId,
      orden: orden ?? this.orden,
      cantanteId: cantanteId ?? this.cantanteId,
      tonoAsignado: tonoAsignado ?? this.tonoAsignado,
    );
  }

  @override
  List<Object?> get props => [cancionId, orden, cantanteId, tonoAsignado];
}
