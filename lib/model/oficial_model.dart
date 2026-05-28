class OficialModel {
  final String id;
  final String authUserId;
  final String codigoEmpleado;
  final String nombres;
  final String apellidos;
  final String email;
  final String estado;

  OficialModel({
    required this.id,
    required this.authUserId,
    required this.codigoEmpleado,
    required this.nombres,
    required this.apellidos,
    required this.email,
    required this.estado,
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();

  factory OficialModel.fromJson(Map<String, dynamic> json) {
    return OficialModel(
      id: json['id'].toString(),
      authUserId: json['auth_user_id'].toString(),
      codigoEmpleado: json['codigo_empleado']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'ACTIVO',
    );
  }
}