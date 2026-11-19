import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_alabanzas/core/theme/app_theme.dart';
import 'package:app_alabanzas/widgets/calendario_mensual.dart';

void main() {
  testWidgets('marca el día de hoy y avisa al tocar un día con actividad',
      (tester) async {
    final hoy = DateTime.now();
    final diaConActividad = DateTime(hoy.year, hoy.month, hoy.day);
    DateTime? diaTocado;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: CalendarioMensual(
            diasConActividad: {diaConActividad},
            onDiaSeleccionado: (dia) => diaTocado = dia,
          ),
        ),
      ),
    );

    expect(find.text('${hoy.day}'), findsOneWidget);

    await tester.tap(find.text('${hoy.day}'));
    await tester.pump();

    expect(diaTocado, diaConActividad);
  });

  testWidgets('tocar un día sin actividad no hace nada', (tester) async {
    final hoy = DateTime.now();
    var tocado = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: CalendarioMensual(
            diasConActividad: const {},
            onDiaSeleccionado: (_) => tocado = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('${hoy.day}'));
    await tester.pump();

    expect(tocado, isFalse);
  });

  testWidgets('cambiar de mes muestra el nombre del mes siguiente',
      (tester) async {
    final hoy = DateTime.now();
    final mesSiguiente = DateTime(hoy.year, hoy.month + 1);
    const nombresMes = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', //
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: CalendarioMensual(
            diasConActividad: const {},
            onDiaSeleccionado: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pump();

    expect(
      find.text(
        '${nombresMes[mesSiguiente.month - 1]} ${mesSiguiente.year}',
      ),
      findsOneWidget,
    );
  });
}
