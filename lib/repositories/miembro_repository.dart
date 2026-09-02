import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_alabanzas/core/firestore/firestore_repository.dart';
import 'package:app_alabanzas/models/miembro.dart';

/// Acceso a la colección `miembros`.
class MiembroRepository extends FirestoreRepository<Miembro> {
  MiembroRepository()
      : super(
          FirebaseFirestore.instance
              .collection('miembros')
              .withConverter<Miembro>(
                fromFirestore: Miembro.converter.fromFirestore,
                toFirestore: Miembro.converter.toFirestore,
              ),
        );

  /// El perfil de integrante ya vinculado a esta cuenta de Firebase Auth,
  /// si existe. Lo usa la pantalla de Selección de rol para decidir si
  /// hay que mostrar el paso de "elegí quién sos" o saltarlo directo.
  Future<Miembro?> buscarPorUid(String uid) async {
    final resultado =
        await collection.where('uid', isEqualTo: uid).limit(1).get();
    if (resultado.docs.isEmpty) return null;
    return resultado.docs.first.data();
  }
}
