import 'package:equatable/equatable.dart';

import 'package:app_alabanzas/core/firestore/model_converter.dart';

/// Una consigna de práctica que el líder deja para el equipo — "practicar
/// el puente de Way Maker", "afinar la entrada del coro". Cada integrante
/// la marca como hecha por su cuenta; el líder ve quién ya practicó y
/// quién no todavía, sin tener que preguntar uno por uno.
class Ejercicio extends Equatable {
  const Ejercicio({
    required this.id,
    required this.titulo,
    required this.autorUid,
    this.descripcion = '',
    this.cancionId,
    this.seccionEtiqueta,
    this.completadoPorUids = const [],
  });

  final String id;
  final String titulo;

  /// Opcional: detalle de la consigna más allá del título.
  final String descripcion;

  /// UID de quien lo dejó — normalmente el líder, pero no se restringe
  /// acá: la pantalla de creación es la que solo se muestra a líderes.
  final String autorUid;

  /// null = ejercicio general, no atado a ninguna canción.
  final String? cancionId;

  /// Ej. "Puente", "Coro" — la sección de la canción a la que aplica.
  /// null si aplica a la canción entera (o si `cancionId` también es null).
  final String? seccionEtiqueta;

  /// UIDs de quienes ya marcaron este ejercicio como practicado.
  final List<String> completadoPorUids;

  bool completadoPor(String uid) => completadoPorUids.contains(uid);

  factory Ejercicio.fromMap(String id, Map<String, dynamic> map) {
    final completadoRaw =
        map['completadoPorUids'] as List<dynamic>? ?? const [];
    return Ejercicio(
      id: id,
      titulo: map['titulo'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      autorUid: map['autorUid'] as String? ?? '',
      cancionId: map['cancionId'] as String?,
      seccionEtiqueta: map['seccionEtiqueta'] as String?,
      completadoPorUids: completadoRaw.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'descripcion': descripcion,
        'autorUid': autorUid,
        'cancionId': cancionId,
        'seccionEtiqueta': seccionEtiqueta,
        'completadoPorUids': completadoPorUids,
      };

  static final converter = ModelConverter<Ejercicio>(
    fromMap: Ejercicio.fromMap,
    toMap: (e) => e.toMap(),
  );

  @override
  List<Object?> get props => [
        id,
        titulo,
        descripcion,
        autorUid,
        cancionId,
        seccionEtiqueta,
        completadoPorUids,
      ];
}
