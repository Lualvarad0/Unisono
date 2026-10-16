import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_alabanzas/core/firestore/firestore_repository.dart';
import 'package:app_alabanzas/models/equipo.dart';

/// Acceso a la colección raíz `equipos` — a diferencia del resto de los
/// repositorios (ritmos, canciones, etc.), este SÍ vive a nivel raíz, no
/// adentro de un equipo: es justamente el que define los equipos que
/// existen.
class EquipoRepository extends FirestoreRepository<Equipo> {
  EquipoRepository()
      : super(
          FirebaseFirestore.instance.collection('equipos').withConverter<Equipo>(
                fromFirestore: Equipo.converter.fromFirestore,
                toFirestore: Equipo.converter.toFirestore,
              ),
        );

  // Sin "O"/"0" ni "I"/"1"/"L" — letras y números que se confunden entre
  // sí al dictar el código por WhatsApp o de memoria.
  static const _caracteres = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  String _generarCodigo() {
    final azar = Random.secure();
    return List.generate(6, (_) => _caracteres[azar.nextInt(_caracteres.length)]).join();
  }

  /// Un código que ningún otro equipo esté usando ya — con 32^6
  /// combinaciones posibles, un choque es prácticamente imposible, pero
  /// se verifica igual antes de usarlo.
  Future<String> generarCodigoUnico() async {
    for (var intento = 0; intento < 5; intento++) {
      final codigo = _generarCodigo();
      if (await buscarPorCodigo(codigo) == null) return codigo;
    }
    throw StateError('No se pudo generar un código de equipo único.');
  }

  Future<Equipo?> buscarPorCodigo(String codigo) async {
    final resultado = await collection
        .where('codigo', isEqualTo: codigo.trim().toUpperCase())
        .limit(1)
        .get();
    if (resultado.docs.isEmpty) return null;
    return resultado.docs.first.data();
  }
}
