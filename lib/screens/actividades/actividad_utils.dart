const _diasSemana = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo', //
];

const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', //
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

const escalaCromatica = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', //
];

/// "Domingo 10 de noviembre" — para tarjetas y encabezados de Actividad.
/// No usa `intl` a propósito: mantiene el arranque de la app sin un paso
/// async extra de inicialización de locale (ver `AppAlabanzas` en
/// `app.dart`, que ya maneja su propio estado de arranque).
String formatearFechaActividad(DateTime fecha) {
  final dia = _diasSemana[fecha.weekday - 1];
  final mes = _meses[fecha.month - 1];
  return '${dia[0].toUpperCase()}${dia.substring(1)} ${fecha.day} de $mes';
}

/// Nota resultante de aplicar `semitonos` de offset a `tonoOriginal` —
/// misma matemática que el selector de tonalidad en vivo de
/// `DetalleAlabanzaScreen`, acá para el tono asignado a una entrada de
/// setlist en vez de un transporte temporal en pantalla.
String transponerTono(String tonoOriginal, int semitonos) {
  final origen = escalaCromatica.indexOf(tonoOriginal);
  if (origen == -1) return tonoOriginal;
  final destino = ((origen + semitonos) % 12 + 12) % 12;
  return escalaCromatica[destino];
}
