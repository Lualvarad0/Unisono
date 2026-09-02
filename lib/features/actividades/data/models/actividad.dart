import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/firestore/model_converter.dart';
import 'setlist_entry.dart';

/// Un servicio/ensayo con su setlist ordenado. Es el documento que la
/// Vista Líder transmite por la Capa 2 (`actividadId` + índice de canción
/// activa) para que los demás celulares sepan qué mostrar.
class Actividad extends Equatable {
  const Actividad({
    required this.id,
    required this.nombre,
    required this.fecha,
    this.setlist = const [],
  });

  final String id;
  final String nombre;
  final DateTime fecha;
  final List<SetlistEntry> setlist;

  factory Actividad.fromMap(String id, Map<String, dynamic> map) {
    final setlistRaw = map['setlist'] as List<dynamic>? ?? const [];
    final entradas = setlistRaw
        .map((e) => SetlistEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
    return Actividad(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      setlist: entradas,
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'fecha': Timestamp.fromDate(fecha),
        'setlist': setlist.map((e) => e.toMap()).toList(),
      };

  Actividad copyWith({
    String? nombre,
    DateTime? fecha,
    List<SetlistEntry>? setlist,
  }) {
    return Actividad(
      id: id,
      nombre: nombre ?? this.nombre,
      fecha: fecha ?? this.fecha,
      setlist: setlist ?? this.setlist,
    );
  }

  static final converter = ModelConverter<Actividad>(
    fromMap: Actividad.fromMap,
    toMap: (a) => a.toMap(),
  );

  @override
  List<Object?> get props => [id, nombre, fecha, setlist];
}
