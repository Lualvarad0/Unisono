import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'package:app_alabanzas/core/firestore/model_converter.dart';
import 'package:app_alabanzas/models/setlist_entry.dart';

/// Un servicio/ensayo con su setlist ordenado. Es el documento que la
/// Vista Líder transmite por la Capa 2 (`actividadId` + índice de canción
/// activa) para que los demás celulares sepan qué mostrar.
class Actividad extends Equatable {
  const Actividad({
    required this.id,
    required this.nombre,
    required this.fecha,
    this.setlist = const [],
    this.cancionActivaId,
    this.seccionActivaIndice = 0,
  });

  final String id;
  final String nombre;
  final DateTime fecha;
  final List<SetlistEntry> setlist;

  /// Qué canción del setlist está mostrando el líder en Vista en vivo
  /// ahora mismo — `null` significa que nadie está transmitiendo. Es la
  /// versión con Firestore (en vez de la Capa 2 P2P que todavía no está
  /// conectada acá, ver `PrincipalShellScreen`) de lo mismo que ya
  /// describía este modelo: "actividadId + índice de canción activa" que
  /// el líder transmite para que los demás celulares sepan qué mostrar.
  /// Solo funciona con conexión — el repertorio en sí sigue disponible
  /// offline como siempre.
  final String? cancionActivaId;

  /// Qué sección de esa canción (índice sobre `CancionChordPro.secciones`)
  /// está mostrando el líder — `VistaEnVivoScreen` avanza esto de a una a
  /// medida que el líder pasa de sección.
  final int seccionActivaIndice;

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
      cancionActivaId: map['cancionActivaId'] as String?,
      seccionActivaIndice: (map['seccionActivaIndice'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'fecha': Timestamp.fromDate(fecha),
        'setlist': setlist.map((e) => e.toMap()).toList(),
        'cancionActivaId': cancionActivaId,
        'seccionActivaIndice': seccionActivaIndice,
      };

  Actividad copyWith({
    String? nombre,
    DateTime? fecha,
    List<SetlistEntry>? setlist,
    String? cancionActivaId,
    bool limpiarCancionActiva = false,
    int? seccionActivaIndice,
  }) {
    return Actividad(
      id: id,
      nombre: nombre ?? this.nombre,
      fecha: fecha ?? this.fecha,
      setlist: setlist ?? this.setlist,
      cancionActivaId: limpiarCancionActiva
          ? null
          : (cancionActivaId ?? this.cancionActivaId),
      seccionActivaIndice: seccionActivaIndice ?? this.seccionActivaIndice,
    );
  }

  static final converter = ModelConverter<Actividad>(
    fromMap: Actividad.fromMap,
    toMap: (a) => a.toMap(),
  );

  @override
  List<Object?> get props =>
      [id, nombre, fecha, setlist, cancionActivaId, seccionActivaIndice];
}
