import 'package:equatable/equatable.dart';

import '../../../../core/firestore/model_converter.dart';

/// Un género/ritmo musical (Cumbia, Júbilo, Balada, ...). Es el nivel más
/// alto de clasificación del repertorio: Ritmo -> Artista -> Canción.
class Ritmo extends Equatable {
  const Ritmo({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory Ritmo.fromMap(String id, Map<String, dynamic> map) {
    return Ritmo(id: id, nombre: map['nombre'] as String? ?? '');
  }

  Map<String, dynamic> toMap() => {'nombre': nombre};

  Ritmo copyWith({String? nombre}) {
    return Ritmo(id: id, nombre: nombre ?? this.nombre);
  }

  static final converter = ModelConverter<Ritmo>(
    fromMap: Ritmo.fromMap,
    toMap: (r) => r.toMap(),
  );

  @override
  List<Object?> get props => [id, nombre];
}
