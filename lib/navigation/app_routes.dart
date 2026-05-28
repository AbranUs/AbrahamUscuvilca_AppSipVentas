import 'package:flutter/material.dart';

import '../view/auth/login_oficial_screen.dart';
import '../view/home/cartera_diaria_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String cartera = '/cartera';

  // Se mantienen solo las pantallas que ya existen en tu avance.
  // Cuando crees ruta/cliente/solicitud/documentos/buro, agrega aquí sus rutas.
  static Map<String, WidgetBuilder> routes = {
    AppRoutes.login: (context) => const LoginOficialScreen(),
    AppRoutes.cartera: (context) => const CarteraDiariaScreen(),
  };
}