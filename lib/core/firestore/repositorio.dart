/// Contrato de acceso a datos que usan todas las pantallas y providers de
/// la app — nunca el tipo concreto `FirestoreRepository<T>` directamente.
///
/// La razón de ser de esta interfaz: el día que haga falta una
/// implementación distinta de `Repositorio<Cancion>` (un repositorio en
/// memoria para tests de widgets, una capa de caché local antes de
/// escribir a Firestore, un mock para un ejemplo de la documentación), esa
/// implementación nueva se agrega al lado de `FirestoreRepository<T>` sin
/// tocar una sola pantalla ni un solo provider — todos ya programan contra
/// `Repositorio<T>`, no contra Firestore.
///
/// `FirestoreRepository<T>` (en `firestore_repository.dart`) es, por ahora,
/// la única implementación real.
abstract class Repositorio<T> {
  /// Lectura reactiva: como Firestore ya tiene caché offline persistente
  /// (ver `sync_remoto/data/services/firestore_service.dart`), este stream
  /// emite primero desde el disco del celular si no hay red.
  Stream<List<T>> watchAll();

  Future<List<T>> fetchAll();

  Future<T?> fetchById(String id);

  /// Crea un registro nuevo. Si `id` es null, la implementación genera uno.
  Future<String> crear(T item, {String? id});

  Future<void> actualizar(String id, T item);

  Future<void> eliminar(String id);
}
