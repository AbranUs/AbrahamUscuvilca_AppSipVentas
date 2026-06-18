import 'cliente_model.dart';

class CarteraModel {
  final String id;
  final String oficialId;
  final String clienteId;
  final DateTime fecha;
  final String tipoGestion;
  final String estado;
  final int prioridad;
  final String? observacion;
  final ClienteModel? cliente;

  CarteraModel({
    required this.id,
    required this.oficialId,
    required this.clienteId,
    required this.fecha,
    required this.tipoGestion,
    required this.estado,
    required this.prioridad,
    this.observacion,
    this.cliente,
  });

  factory CarteraModel.fromJson(Map<String, dynamic> json) {
    final clienteJson = json['clientes'];

    return CarteraModel(
      id: json['id'].toString(),
      oficialId: json['oficial_id'].toString(),
      clienteId: json['cliente_id'].toString(),
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? '') ?? DateTime.now(),
      tipoGestion: json['tipo_gestion']?.toString() ?? 'Nuevo crédito',
      estado: json['estado']?.toString() ?? 'Pendiente',
      prioridad: int.tryParse(json['prioridad']?.toString() ?? '0') ?? 0,
      observacion: json['observacion']?.toString(),
      cliente: clienteJson is Map<String, dynamic>
          ? ClienteModel.fromJson(clienteJson)
          : null,
    );
  }
}