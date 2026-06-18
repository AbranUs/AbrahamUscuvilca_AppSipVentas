import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'navigation/app_routes.dart';
import 'services/supabase_config.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase antes de construir cualquier pantalla.
  // Las credenciales se pasan con --dart-define para no quemarlas en el código.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const SipVentasApp());
}

class SipVentasApp extends StatelessWidget {
  const SipVentasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSession = Supabase.instance.client.auth.currentSession != null;

    return MaterialApp(
      title: 'Sip Fuerza de Ventas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: hasSession ? AppRoutes.cartera : AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}