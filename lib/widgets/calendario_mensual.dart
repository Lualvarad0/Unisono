import 'package:flutter/material.dart';

import 'package:app_alabanzas/core/theme/app_theme.dart';

const _nombresMes = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', //
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const _inicialesDia = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// Calendario mensual compacto para el dashboard: resalta hoy, marca con
/// un punto los días que tienen al menos una Actividad y deja moverse
/// entre meses. No usa ningún paquete de calendario — la grilla es chica
/// (máximo 6 semanas, sin swipe ni rangos de selección) y no amerita una
/// dependencia nueva para esto.
class CalendarioMensual extends StatefulWidget {
  const CalendarioMensual({
    super.key,
    required this.diasConActividad,
    required this.onDiaSeleccionado,
  });

  /// Fechas con al menos una Actividad ese día — la hora se ignora, solo
  /// importa año/mes/día.
  final Set<DateTime> diasConActividad;

  /// Se llama al tocar un día que tiene actividad.
  final ValueChanged<DateTime> onDiaSeleccionado;

  @override
  State<CalendarioMensual> createState() => _CalendarioMensualState();
}

class _CalendarioMensualState extends State<CalendarioMensual> {
  late DateTime _mesMostrado;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _mesMostrado = DateTime(hoy.year, hoy.month);
  }

  void _cambiarMes(int delta) {
    setState(() {
      _mesMostrado = DateTime(_mesMostrado.year, _mesMostrado.month + delta);
    });
  }

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final hoy = DateTime.now();
    final primerDiaDelMes = DateTime(_mesMostrado.year, _mesMostrado.month, 1);
    // DateTime.weekday: lunes = 1 ... domingo = 7 — se resta 1 para que la
    // grilla arranque en lunes, no en domingo.
    final offsetInicial = primerDiaDelMes.weekday - 1;
    final diasEnElMes =
        DateTime(_mesMostrado.year, _mesMostrado.month + 1, 0).day;
    final totalCeldas = ((offsetInicial + diasEnElMes) / 7).ceil() * 7;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Mes anterior',
                  onPressed: () => _cambiarMes(-1),
                ),
                Text(
                  '${_nombresMes[_mesMostrado.month - 1]} ${_mesMostrado.year}',
                  style: tema.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Mes siguiente',
                  onPressed: () => _cambiarMes(1),
                ),
              ],
            ),
            Row(
              children: [
                for (final inicial in _inicialesDia)
                  Expanded(
                    child: Center(
                      child: Text(
                        inicial,
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCeldas,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 40,
              ),
              itemBuilder: (context, indice) {
                final numeroDia = indice - offsetInicial + 1;
                if (numeroDia < 1 || numeroDia > diasEnElMes) {
                  return const SizedBox.shrink();
                }
                final dia = DateTime(
                  _mesMostrado.year,
                  _mesMostrado.month,
                  numeroDia,
                );
                final esHoy = _mismoDia(dia, hoy);
                final tieneActividad = widget.diasConActividad
                    .any((d) => _mismoDia(d, dia));

                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: tieneActividad
                      ? () => widget.onDiaSeleccionado(dia)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: esHoy
                          ? tema.colorScheme.primary.withValues(alpha: 0.16)
                          : null,
                      border: esHoy
                          ? Border.all(color: tema.colorScheme.primary, width: 1.2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$numeroDia',
                          style: tema.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: esHoy ? FontWeight.w700 : FontWeight.w400,
                            color: esHoy ? tema.colorScheme.primary : null,
                          ),
                        ),
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tieneActividad
                                ? AppTheme.acento
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
