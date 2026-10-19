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

  /// Perfiles invitados todavía sin reclamar — es lo que ve quien se
  /// está uniendo con un código para elegir su nombre de la lista, ANTES
  /// de pertenecer al equipo (ver `ElegirEquipoScreen`).
  ///
  /// A propósito una query con `.where('uid', isNull: true)` y no
  /// `fetchAll()` filtrado del lado del cliente: `firestore.rules` deja
  /// leer un `Miembro` sin reclamar a cualquier autenticado (todavía no
  /// hay forma de pertenecer al equipo en este punto), pero NO deja leer
  /// los que ya tienen dueño — y Firestore solo puede validar esa regla
  /// si la propia query ya viene filtrada así: una query sin filtro que
  /// pudiera devolver un documento ajeno se rechaza entera, no se
  /// recorta sola.
  Future<List<Miembro>> fetchSinReclamar() async {
    final resultado = await collection.where('uid', isNull: true).get();
    return resultado.docs.map((doc) => doc.data()).toList();
  }
}
