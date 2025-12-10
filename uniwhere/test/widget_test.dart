// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:uniwhere/main.dart';

void main() {
  testWidgets('Carga pantalla de inicio con botones principales', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('AR Home Navigator Demo'), findsOneWidget);
    expect(find.text('Modo Calibración'), findsOneWidget);
    expect(find.text('Modo Navegación'), findsOneWidget);
    expect(find.text('Ver Mapa 2D'), findsOneWidget);
  });
}
