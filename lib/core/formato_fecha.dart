/// Nombres en español para formatear fechas a mano en toda la app — sin
/// `intl` a propósito, para no sumarle un paso async de inicialización de
/// locale al arranque (ver `AppAlabanzas` en `app.dart`).
const diasSemana = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo', //
];

const meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', //
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// "10 de noviembre de 1998" — fecha larga con año, para cumpleaños y
/// cualquier contexto donde el año importe (a diferencia de la fecha de
/// una Actividad, que es siempre cercana y no lo necesita).
String formatearFechaLarga(DateTime fecha) {
  return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
}
