class SolicitudCreditoModel {
  final String? id;
  final String clienteId;
  final String oficialId;
  final double montoSolicitado;
  final int plazoMeses;
  final String destinoCredito;
  final String estado;
  final String syncStatus;
  final DateTime? createdAt;

  SolicitudCreditoModel({
    this.id,
    required this.clienteId,
    required this.oficialId,
    required this.montoSolicitado,
    required this.plazoMeses,
    required this.destinoCredito,
    this.estado = 'REGISTRADA',
    this.syncStatus = 'PENDIENTE',
    this.createdAt,
  });

  factory SolicitudCreditoModel.fromJson(Map<String, dynamic> json) {
    return SolicitudCreditoModel(
      id: json['id']?.toString(),
      clienteId: json['cliente_id'].toString(),
      oficialId: json['oficial_id'].toString(),
      montoSolicitado: _toDouble(json['monto_solicitado']) ?? 0,
      plazoMeses: int.tryParse(json['plazo_meses']?.toString() ?? '0') ?? 0,
      destinoCredito: json['destino_credito']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'REGISTRADA',
      syncStatus: json['sync_status']?.toString() ?? 'SINCRONIZADO',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'cliente_id': clienteId,
      'oficial_id': oficialId,
      'monto_solicitado': montoSolicitado,
      'plazo_meses': plazoMeses,
      'destino_credito': destinoCredito,
      'estado': estado,
      'sync_status': syncStatus,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}