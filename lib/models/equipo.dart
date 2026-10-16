import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'package:app_alabanzas/core/firestore/model_converter.dart';

/// Un equipo de alabanza — el límite real de "quién ve qué" en la app.
/// Todo el contenido (repertorio, setlists, integrantes, notas,
/// ejercicios) vive adentro de `equipos/{id}/...` como subcolecciones, no
/// suelto a nivel raíz — antes de esto, cualquier cuenta nueva entraba a
/// la misma base compartida que todas las demás, sin importar si de
/// verdad eran del mismo grupo.
class Equipo extends Equatable {
  const Equipo({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.creadoPorUid,
  });

  final String id;
  final String nombre;

  /// Código corto (6 caracteres, sin O/0/I/1/L para que no se confundan
  /// al dictarlo) para que alguien nuevo se una sin tener que mandarle un
  /// link — ver `EquipoRepository.generarCodigoUnico`.
  final String codigo;

  final String creadoPorUid;

  factory Equipo.fromMap(String id, Map<String, dynamic> map) {
    return Equipo(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      codigo: map['codigo'] as String? ?? '',
      creadoPorUid: map['creadoPorUid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'codigo': codigo,
        'creadoPorUid': creadoPorUid,
        'creadoEn': FieldValue.serverTimestamp(),
      };

  static final converter = ModelConverter<Equipo>(
    fromMap: Equipo.fromMap,
    toMap: (e) => e.toMap(),
  );

  @override
  List<Object?> get props => [id, nombre, codigo, creadoPorUid];
}
