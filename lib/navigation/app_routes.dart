import 'package:flutter/material.dart';

import '../view/auth/login_oficial_screen.dart';
import '../view/home/cartera_diaria_screen.dart';
import '../view/home/main_navigation_shell.dart';
import '../view/pre_evaluacion/pre_evaluacion_campanas_screen.dart';
import '../view/solicitud/solicitud_wizard_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String cartera = '/cartera';
  static const String homeShell = '/home_shell';
  static const String preEvaluacion = '/pre_evaluacion';
  static const String solicitudWizard = '/solicitud_wizard';

  static Map<String, WidgetBuilder> routes = {
    AppRoutes.login: (context) => const LoginOficialScreen(),
    AppRoutes.cartera: (context) => const CarteraDiariaScreen(),
    AppRoutes.homeShell: (context) => const MainNavigationShell(),
    AppRoutes.preEvaluacion: (context) => const PreEvaluacionCampanasScreen(),
    AppRoutes.solicitudWizard: (context) => const SolicitudWizardScreen(),
  };
}