import 'package:flutter/material.dart';

class AuthOficialViewModel extends ChangeNotifier {
  bool loading = false;
  bool success = false;
  String? error;

  final String codigoCorrecto = 'OFI001';
  final String passwordCorrecto = 'sipventas';

  Future<void> login(String codigoEmpleado, String password) async {
    loading = true;
    success = false;
    error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    if (codigoEmpleado == codigoCorrecto && password == passwordCorrecto) {
      success = true;
    } else {
      error = 'Credenciales institucionales incorrectas';
    }

    loading = false;
    notifyListeners();
  }
}