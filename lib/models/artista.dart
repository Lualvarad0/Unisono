import 'package:equatable/equatable.dart';

import 'package:app_alabanzas/core/firestore/model_converter.dart';

/// Un artista/interprete de referencia para una canción. Es opcional: una
/// canción sin `artistaId` se muestra como "Varios" en la UI.
class Artista extends Equatable {
  const Artista({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory Artista.fromMap(String id, Map<String, dynamic> map) {
    return Artista(id: id, nombre: map['nombre'] as String? ?? '');
  }

  Map<String, dynamic> toMap() => {'nombre': nombre};

  Artista copyWith({String? nombre}) {
    return Artista(id: id, nombre: nombre ?? this.nombre);
  }

  static final converter = ModelConverter<Artista>(
    fromMap: Artista.fromMap,
    toMap: (a) => a.toMap(),
  );

  @override
  List<Object?> get props => [id, nombre];
}
