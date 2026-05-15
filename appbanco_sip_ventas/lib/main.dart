import 'package:flutter/material.dart';
import 'navigation/app_routes.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(const SipVentasApp());
}

class SipVentasApp extends StatelessWidget {
  const SipVentasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sip Fuerza de Ventas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}