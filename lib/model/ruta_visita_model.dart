class RutaVisitaModel {
  final String id;
  final String carteraId;
  final String clienteId;
  final String oficialId;
  final double latitud;
  final double longitud;
  final String direccion;
  final String estadoVisita;
  final DateTime fechaVisita;
  final String clienteNombre;

  RutaVisitaModel({
    required this.id,
    required this.carteraId,
    required this.clienteId,
    required this.oficialId,
    required this.latitud,
    required this.longitud,
    required this.direccion,
    required this.estadoVisita,
    required this.fechaVisita,
    required this.clienteNombre,
  });

  factory RutaVisitaModel.fromJson(Map<String, dynamic> json) {
    final cliente = json['clientes'];
    final nombres = cliente is Map<String, dynamic>
        ? cliente['nombres']?.toString() ?? ''
        : '';
    final apellidos = cliente is Map<String, dynamic>
        ? cliente['apellidos']?.toString() ?? ''
        : '';

    return RutaVisitaModel(
      id: json['id'].toString(),
      carteraId: json['cartera_id'].toString(),
      clienteId: json['cliente_id'].toString(),
      oficialId: json['oficial_id'].toString(),
      latitud: _toDouble(json['latitud']) ?? 0,
      longitud: _toDouble(json['longitud']) ?? 0,
      direccion: json['direccion']?.toString() ?? '',
      estadoVisita: json['estado_visita']?.toString() ?? 'PENDIENTE',
      fechaVisita:
          DateTime.tryParse(json['fecha_visita']?.toString() ?? '') ??
              DateTime.now(),
      clienteNombre: '$nombres $apellidos'.trim(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}