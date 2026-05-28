class BuroCreditoModel {
  final String? id;
  final String clienteId;
  final String oficialId;
  final int? score;
  final String resultado;
  final String proveedor;
  final String estadoConsulta;
  final Map<String, dynamic>? payloadRespuesta;
  final DateTime? createdAt;

  BuroCreditoModel({
    this.id,
    required this.clienteId,
    required this.oficialId,
    this.score,
    required this.resultado,
    this.proveedor = 'API_EXTERNA_PENDIENTE',
    this.estadoConsulta = 'REGISTRADA',
    this.payloadRespuesta,
    this.createdAt,
  });

  factory BuroCreditoModel.fromJson(Map<String, dynamic> json) {
    return BuroCreditoModel(
      id: json['id']?.toString(),
      clienteId: json['cliente_id'].toString(),
      oficialId: json['oficial_id'].toString(),
      score: int.tryParse(json['score']?.toString() ?? ''),
      resultado: json['resultado']?.toString() ?? '',
      proveedor: json['proveedor']?.toString() ?? 'API_EXTERNA_PENDIENTE',
      estadoConsulta: json['estado_consulta']?.toString() ?? 'REGISTRADA',
      payloadRespuesta: json['payload_respuesta'] is Map<String, dynamic>
          ? json['payload_respuesta'] as Map<String, dynamic>
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}