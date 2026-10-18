import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  /// Pasa por la Cloud Function callable `buscarEquipoPorCodigo` en vez
  /// de una query directa a Firestore — a propósito: una query directa
  /// necesita que `firestore.rules` deje hacer `list` sobre toda la
  /// colección `equipos`, lo que expondría el código de TODOS los
  /// equipos a cualquier cuenta autenticada, no solo el que se busca acá.
  /// Ver docs/SEGURIDAD.md, auditoría 2026-10-17.
  Future<Equipo?> buscarPorCodigo(String codigo) async {
    final codigoNormalizado = codigo.trim().toUpperCase();
    final resultado = await FirebaseFunctions.instance
        .httpsCallable('buscarEquipoPorCodigo')
        .call<Map<String, dynamic>>({'codigo': codigoNormalizado});
    final datos = resultado.data;
    if (datos['encontrado'] != true) return null;
    return Equipo(
      id: datos['equipoId'] as String,
      nombre: datos['nombre'] as String? ?? '',
      codigo: codigoNormalizado,
      creadoPorUid: datos['creadoPorUid'] as String? ?? '',
    );
  }
}
