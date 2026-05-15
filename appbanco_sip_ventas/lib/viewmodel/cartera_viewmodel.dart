import 'package:flutter/material.dart';
import '../model/cliente_cartera_model.dart';

class CarteraViewModel extends ChangeNotifier {
  final String nombreOficial = 'Lucía Fernández';

  final List<ClienteCarteraModel> clientes = [
    ClienteCarteraModel(
      nombre: 'María Quispe',
      tipoGestion: 'Renovación',
      estado: 'Pendiente',
    ),
    ClienteCarteraModel(
      nombre: 'Luis Huamán',
      tipoGestion: 'Nuevo crédito',
      estado: 'Pendiente',
    ),
    ClienteCarteraModel(
      nombre: 'Rosa Ramos',
      tipoGestion: 'Cobranza',
      estado: 'Visitado',
    ),
    ClienteCarteraModel(
      nombre: 'Jorge Salazar',
      tipoGestion: 'Renovación',
      estado: 'Pendiente',
    ),
    ClienteCarteraModel(
      nombre: 'Ana Torres',
      tipoGestion: 'Nuevo crédito',
      estado: 'Visitado',
    ),
  ];

  int get totalVisitas => clientes.length;

  int get pendientes =>
      clientes.where((cliente) => cliente.estado == 'Pendiente').length;

  int get visitados =>
      clientes.where((cliente) => cliente.estado == 'Visitado').length;
}