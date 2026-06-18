import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appbanco_sip_ventas/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SipVentasApp());

    // Aquí puedes verificar que algún texto de tu login aparezca
    expect(find.text('APP 2 — Fuerza de Ventas'), findsOneWidget);

    // Por ejemplo, si quieres probar la pantalla de login
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}