import 'package:flutter/material.dart';

import 'package:app_alabanzas/models/ritmo.dart';

/// Paleta fija para los géneros — un color por posición en la lista
/// ordenada alfabéticamente, no por nombre, así no hace falta
/// mantenerla sincronizada a mano con qué géneros existen. Un solo
/// lugar para esto: los cuadros de "Explorar por género" en Repertorio
/// y los chips de género en Nueva alabanza usan la misma paleta, para
/// que un género se vea siempre del mismo color en toda la app.
const coloresGenero = [
  Color(0xFFE91429),
  Color(0xFF1E3264),
  Color(0xFF8D67AB),
  Color(0xFF148A08),
  Color(0xFFE8115B),
  Color(0xFFBA5D07),
  Color(0xFF477D95),
  Color(0xFF509BF5),
];

/// `generosOrdenados` tiene que ser la misma lista (mismo orden) en
/// todos los lugares que llaman a esto — hoy es siempre
/// `[...géneros]..sort((a, b) => a.nombre.compareTo(b.nombre))`.
Color colorDeGenero(List<Ritmo> generosOrdenados, String generoId) {
  final indice = generosOrdenados.indexWhere((g) => g.id == generoId);
  return coloresGenero[(indice < 0 ? 0 : indice) % coloresGenero.length];
}
