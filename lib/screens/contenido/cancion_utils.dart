import 'package:app_alabanzas/models/cancion.dart';

/// Ordena por `creadaEn` descendente (más nueva primero) — para la
/// sección RECIENTES de Home. Las que no tienen `creadaEn` (contenido
/// viejo, de antes de que `Cancion` guardara esa fecha) van al final,
/// nunca antes que una con fecha. Usa el índice original como segundo
/// criterio en vez de confiar en que `List.sort` sea estable, para que
/// el orden entre empates (incluido "nadie tiene fecha") no cambie de
/// una pasada a otra.
List<Cancion> ordenarPorRecientes(List<Cancion> canciones) {
  final indexadas = canciones.indexed.toList()
    ..sort((a, b) {
      final fechaA = a.$2.creadaEn;
      final fechaB = b.$2.creadaEn;
      if (fechaA == null && fechaB == null) return a.$1.compareTo(b.$1);
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;
      final comparacion = fechaB.compareTo(fechaA);
      return comparacion != 0 ? comparacion : a.$1.compareTo(b.$1);
    });
  return [for (final (_, cancion) in indexadas) cancion];
}
