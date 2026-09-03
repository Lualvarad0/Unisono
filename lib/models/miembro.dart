import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'package:app_alabanzas/core/firestore/model_converter.dart';

/// Roles que puede tener un integrante del grupo. Una persona puede tener
/// varios a la vez (ej. alguien que toca guitarra y también canta).
enum RolMiembro { lider, musico, cantante }

/// Nombre para mostrar de cada rol — un solo lugar para esto en vez de
/// repetir el mapeo en cada pantalla que lista o edita roles (Mi equipo,
/// Mi perfil).
extension RolMiembroNombre on RolMiembro {
  String get nombreVisible => switch (this) {
        RolMiembro.lider => 'Líder',
        RolMiembro.musico => 'Músico',
        RolMiembro.cantante => 'Cantante',
      };
}

/// Qué tan cómodo está alguien con su instrumento — informativo nada más
/// (no cambia permisos ni funcionalidad), pensado para que el líder sepa
/// a quién pedirle qué a la hora de armar un setlist.
enum NivelInstrumento { principiante, intermedio, avanzado }

extension NivelInstrumentoNombre on NivelInstrumento {
  String get nombreVisible => switch (this) {
        NivelInstrumento.principiante => 'Principiante',
        NivelInstrumento.intermedio => 'Intermedio',
        NivelInstrumento.avanzado => 'Avanzado',
      };
}

/// Un integrante del grupo de alabanza.
class Miembro extends Equatable {
  const Miembro({
    required this.id,
    required this.nombre,
    this.apellido = '',
    required this.roles,
    this.uid,
    this.cumpleanos,
    this.instrumento,
    this.nivelInstrumento,
  });

  final String id;
  final String nombre;
  final String apellido;
  final List<RolMiembro> roles;

  /// UID de Firebase Auth de la cuenta vinculada a este integrante. `null`
  /// hasta que alguien "reclama" este perfil en la pantalla de Selección
  /// de rol (Paso Acceso) — antes de eso el perfil existe en Firestore
  /// pero todavía no hay ninguna cuenta logueada detrás.
  final String? uid;

  final DateTime? cumpleanos;

  /// Ej. "Guitarra", "Batería", "Voz". Texto libre a propósito: cubre
  /// cualquier instrumento sin tener que mantener una lista cerrada.
  final String? instrumento;

  final NivelInstrumento? nivelInstrumento;

  String get nombreCompleto =>
      apellido.isEmpty ? nombre : '$nombre $apellido';

  /// Edad calculada a partir de `cumpleanos` en vez de guardarse aparte —
  /// así nunca queda desincronizada (la edad cambia sola con el tiempo,
  /// el cumpleaños no).
  int? get edad {
    final fecha = cumpleanos;
    if (fecha == null) return null;
    final ahora = DateTime.now();
    var edad = ahora.year - fecha.year;
    final todaviaNoCumple = ahora.month < fecha.month ||
        (ahora.month == fecha.month && ahora.day < fecha.day);
    if (todaviaNoCumple) edad--;
    return edad;
  }

  /// Fracción (0.0–1.0) de los campos opcionales del perfil que ya están
  /// completos — para la barra de progreso en Mi perfil. `nombre` y
  /// `roles` quedan afuera de la cuenta: ya son obligatorios desde
  /// Selección de rol, no algo que falte "completar".
  double get progresoPerfil {
    final campos = [
      apellido.isNotEmpty,
      cumpleanos != null,
      instrumento != null && instrumento!.isNotEmpty,
      nivelInstrumento != null,
    ];
    return campos.where((completo) => completo).length / campos.length;
  }

  factory Miembro.fromMap(String id, Map<String, dynamic> map) {
    final rolesRaw = map['roles'] as List<dynamic>? ?? const [];
    final nivelRaw = map['nivelInstrumento'] as String?;
    return Miembro(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      apellido: map['apellido'] as String? ?? '',
      roles: rolesRaw
          .map(
            (r) => RolMiembro.values.firstWhere(
              (rol) => rol.name == r,
              orElse: () => RolMiembro.musico,
            ),
          )
          .toList(),
      uid: map['uid'] as String?,
      cumpleanos: (map['cumpleanos'] as Timestamp?)?.toDate(),
      instrumento: map['instrumento'] as String?,
      nivelInstrumento: nivelRaw == null
          ? null
          : NivelInstrumento.values.firstWhere(
              (n) => n.name == nivelRaw,
              orElse: () => NivelInstrumento.principiante,
            ),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'apellido': apellido,
        'roles': roles.map((r) => r.name).toList(),
        'uid': uid,
        'cumpleanos':
            cumpleanos == null ? null : Timestamp.fromDate(cumpleanos!),
        'instrumento': instrumento,
        'nivelInstrumento': nivelInstrumento?.name,
      };

  Miembro copyWith({
    String? nombre,
    List<RolMiembro>? roles,
    String? uid,
    bool limpiarUid = false,
  }) {
    return Miembro(
      id: id,
      nombre: nombre ?? this.nombre,
      apellido: apellido,
      roles: roles ?? this.roles,
      uid: limpiarUid ? null : (uid ?? this.uid),
      cumpleanos: cumpleanos,
      instrumento: instrumento,
      nivelInstrumento: nivelInstrumento,
    );
  }

  static final converter = ModelConverter<Miembro>(
    fromMap: Miembro.fromMap,
    toMap: (m) => m.toMap(),
  );

  @override
  List<Object?> get props => [
        id,
        nombre,
        apellido,
        roles,
        uid,
        cumpleanos,
        instrumento,
        nivelInstrumento,
      ];
}
