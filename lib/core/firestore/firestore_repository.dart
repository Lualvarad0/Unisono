import 'package:cloud_firestore/cloud_firestore.dart';

import 'repositorio.dart';

/// Implementación con Firestore de [Repositorio]. Ritmo, Artista, Canción,
/// Miembro y Actividad exponen exactamente las mismas cinco operaciones —
/// en vez de repetirlas cinco veces, cada repositorio de feature extiende
/// esta clase y solo aporta su `CollectionReference<T>` (ver
/// `ritmo_repository.dart`).
///
/// El resto de la app (pantallas, providers, tests) programa contra
/// `Repositorio<T>`, no contra esta clase — ver el doc de `Repositorio`
/// para la razón.
///
/// `watchAll` es la forma "normal" de leer para pantallas reactivas: como
/// Firestore ya tiene caché offline persistente (ver
/// `sync_remoto/data/services/firestore_service.dart`), ese stream emite
/// primero desde el disco del celular si no hay red, sin que el código de
/// la UI tenga que distinguir "online" de "offline".
class FirestoreRepository<T> implements Repositorio<T> {
  FirestoreRepository(this.collection);

  /// Expuesto (no privado) para que las subclases puedan agregar queries
  /// propias, ej. `CancionRepository.watchByRitmo`. No usar fuera de una
  /// subclase de repositorio.
  final CollectionReference<T> collection;

  @override
  Stream<List<T>> watchAll() {
    return collection.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  @override
  Future<List<T>> fetchAll() async {
    final snapshot = await collection.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<T?> fetchById(String id) async {
    final doc = await collection.doc(id).get();
    return doc.data();
  }

  /// Crea un documento nuevo. Si `id` es null, Firestore genera uno.
  @override
  Future<String> crear(T item, {String? id}) async {
    if (id != null) {
      await collection.doc(id).set(item);
      return id;
    }
    final ref = await collection.add(item);
    return ref.id;
  }

  @override
  Future<void> actualizar(String id, T item) => collection.doc(id).set(item);

  @override
  Future<void> eliminar(String id) => collection.doc(id).delete();
}
