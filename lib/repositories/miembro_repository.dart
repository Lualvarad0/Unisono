import 'package:app_alabanzas/core/firestore/equipo_collections.dart';
import 'package:app_alabanzas/core/firestore/firestore_repository.dart';
import 'package:app_alabanzas/models/miembro.dart';

/// Acceso a la subcolección `equipos/{equipoId}/miembros`.
class MiembroRepository extends FirestoreRepository<Miembro> {
  MiembroRepository({required String equipoId})
      : super(
          coleccionDeEquipo(equipoId, 'miembros').withConverter<Miembro>(
            fromFirestore: Miembro.converter.fromFirestore,
            toFirestore: Miembro.converter.toFirestore,
          ),
        );

  /// El perfil de integrante ya vinculado a esta cuenta de Firebase Auth,
  /// si existe, DENTRO de este equipo. Para saber en qué equipo buscar en
  /// primer lugar, ver `UsuarioEquipoRepository`.
  Future<Miembro?> buscarPorUid(String uid) async {
    final resultado =
        await collection.where('uid', isEqualTo: uid).limit(1).get();
    if (resultado.docs.isEmpty) return null;
    return resultado.docs.first.data();
  }
}
