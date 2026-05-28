import 'package:flutter/material.dart';

import '../model/oficial_model.dart';
import '../services/auth_service.dart';

class AuthOficialViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  OficialModel? _oficial;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OficialModel? get oficial => _oficial;

  Future<bool> login({
    required String codigoEmpleado,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _oficial = await _authService.loginConCodigo(
        codigoEmpleado: codigoEmpleado.trim(),
        password: password.trim(),
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> cargarSesionActual() async {
    _oficial = await _authService.obtenerOficialActual();
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.cerrarSesion();
    _oficial = null;
    notifyListeners();
  }

  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}