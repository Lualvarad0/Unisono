import 'package:app_alabanzas/models/cancion.dart';
import 'package:app_alabanzas/models/setlist_entry.dart';

/// Entradas del setlist cuya canción no está disponible en este celular
/// ahora mismo — ni cargada en el caché offline de Firestore ni en los
/// documentos ya vistos en esta sesión (`cancionPorId`, armado desde
/// `Repositorio<Cancion>.watchAll()`). Sirve para avisar antes de
/// depender de ellas sin internet (épica #10, sub-tarea #13) — no
/// distingue "nunca se descargó" de "se borró", porque de este lado no
/// hay forma de saberlo, y en ambos casos la acción es la misma: conectarse
/// a internet y volver a intentar.
List<SetlistEntry> entradasSinCancionDisponible(
  List<SetlistEntry> setlist,
  Map<String, Cancion> cancionPorId,
) {
  return setlist
      .where((entrada) => !cancionPorId.containsKey(entrada.cancionId))
      .toList();
}
