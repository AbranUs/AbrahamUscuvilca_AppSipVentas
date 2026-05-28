import 'package:flutter/material.dart';

import '../model/cartera_model.dart';
import '../model/oficial_model.dart';
import '../services/auth_service.dart';
import '../services/cartera_service.dart';

class CarteraViewModel extends ChangeNotifier {
  final CarteraService _carteraService = CarteraService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  List<CarteraModel> _cartera = [];
  OficialModel? _oficialActual;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CarteraModel> get cartera => _cartera;
  OficialModel? get oficialActual => _oficialActual;

  int get totalClientes => _cartera.length;

  int get clientesPendientes => _cartera
      .where((item) => item.estado.toUpperCase() == 'PENDIENTE')
      .length;

  int get clientesVisitados => _cartera
      .where((item) => item.estado.toUpperCase() == 'VISITADO')
      .length;

  Future<void> cargarCarteraDiaria() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _oficialActual = await _authService.obtenerOficialActual();

      if (_oficialActual == null) {
        throw Exception('No se encontró la sesión del oficial.');
      }

      _cartera = await _carteraService.obtenerCarteraDiaria(
        oficialId: _oficialActual!.id,
      );

      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
    }
  }

  Future<void> marcarVisitado(CarteraModel item) async {
    try {
      await _carteraService.actualizarEstadoGestion(
        carteraId: item.id,
        estado: 'VISITADO',
      );

      await cargarCarteraDiaria();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> refrescar() async {
    await cargarCarteraDiaria();
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