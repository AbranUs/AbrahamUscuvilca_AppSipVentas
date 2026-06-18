class ClienteModel {
  final String id;
  final String dni;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String direccion;
  final double? latitud;
  final double? longitud;
  final String estado;
  final DateTime? fechaRegistro;

  ClienteModel({
    required this.id,
    required this.dni,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.direccion,
    this.latitud,
    this.longitud,
    required this.estado,
    this.fechaRegistro,
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id: json['id'].toString(),
      dni: json['dni']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      direccion: json['direccion']?.toString() ?? '',
      latitud: _toDouble(json['latitud']),
      longitud: _toDouble(json['longitud']),
      estado: json['estado']?.toString() ?? 'ACTIVO',
      fechaRegistro: _toDate(json['fecha_registro']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}