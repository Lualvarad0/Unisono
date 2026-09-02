import 'package:equatable/equatable.dart';

import '../../../../core/firestore/model_converter.dart';

/// Roles que puede tener un integrante del grupo. Una persona puede tener
/// varios a la vez (ej. alguien que toca guitarra y también canta).
enum RolMiembro { lider, musico, cantante }

/// Un integrante del grupo de alabanza.
class Miembro extends Equatable {
  const Miembro({
    required this.id,
    required this.nombre,
    required this.roles,
    this.uid,
  });

  final String id;
  final String nombre;
  final List<RolMiembro> roles;

  /// UID de Firebase Auth de la cuenta vinculada a este integrante. `null`
  /// hasta que alguien "reclama" este perfil en la pantalla de Selección
  /// de rol (Paso Acceso) — antes de eso el perfil existe en Firestore
  /// pero todavía no hay ninguna cuenta logueada detrás.
  final String? uid;

  factory Miembro.fromMap(String id, Map<String, dynamic> map) {
    final rolesRaw = map['roles'] as List<dynamic>? ?? const [];
    return Miembro(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      roles: rolesRaw
          .map(
            (r) => RolMiembro.values.firstWhere(
              (rol) => rol.name == r,
              orElse: () => RolMiembro.musico,
            ),
          )
          .toList(),
      uid: map['uid'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'roles': roles.map((r) => r.name).toList(),
        'uid': uid,
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
      roles: roles ?? this.roles,
      uid: limpiarUid ? null : (uid ?? this.uid),
    );
  }

  static final converter = ModelConverter<Miembro>(
    fromMap: Miembro.fromMap,
    toMap: (m) => m.toMap(),
  );

  @override
  List<Object?> get props => [id, nombre, roles, uid];
}
