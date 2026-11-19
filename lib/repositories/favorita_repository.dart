import 'package:app_alabanzas/core/firestore/equipo_collections.dart';
import 'package:app_alabanzas/core/firestore/firestore_repository.dart';
import 'package:app_alabanzas/models/favorita.dart';

/// Acceso a `equipos/{equipoId}/favoritas/{uid}/canciones` — las
/// favoritas de un Miembro puntual (`uid`), nunca las de todo el equipo.
/// Un repositorio por `uid` (no uno solo por equipo filtrado del lado
/// del cliente, como `NotaRepository.watchVisiblesPara`) porque acá sí
/// hace falta que Firestore mismo niegue la lectura a cualquier otra
/// cuenta — ver `firestore.rules`.
class FavoritaRepository extends FirestoreRepository<Favorita> {
  FavoritaRepository({required String equipoId, required String uid})
      : super(
          coleccionDeEquipo(equipoId, 'favoritas')
              .doc(uid)
              .collection('canciones')
              .withConverter<Favorita>(
                fromFirestore: Favorita.converter.fromFirestore,
                toFirestore: Favorita.converter.toFirestore,
              ),
        );

  /// Los ids de Cancion marcados como favoritos — lo que de verdad
  /// necesita la UI (RepertorioScreen, DetalleAlabanzaScreen) en vez del
  /// modelo `Favorita` completo.
  Stream<Set<String>> watchIds() {
    return watchAll().map((favoritas) => favoritas.map((f) => f.id).toSet());
  }

  Future<void> marcar(String cancionId) {
    return crear(Favorita(id: cancionId, agregadaEn: DateTime.now()),
        id: cancionId);
  }

  Future<void> desmarcar(String cancionId) => eliminar(cancionId);
}
