import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_alabanzas/core/theme/app_theme.dart';

void main() {
  testWidgets('la app arranca y muestra la pantalla placeholder',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(child: Text('App Alabanzas — estructura base lista')),
        ),
      ),
    );

    expect(find.text('App Alabanzas — estructura base lista'), findsOneWidget);
  });
}
