class DocumentoModel {
  final String? id;
  final String solicitudId;
  final String clienteId;
  final String oficialId;
  final String tipoDocumento;
  final String nombreArchivo;
  final String storagePath;
  final String estadoSubida;
  final String syncStatus;
  final DateTime? createdAt;

  DocumentoModel({
    this.id,
    required this.solicitudId,
    required this.clienteId,
    required this.oficialId,
    required this.tipoDocumento,
    required this.nombreArchivo,
    required this.storagePath,
    this.estadoSubida = 'SUBIDO',
    this.syncStatus = 'SINCRONIZADO',
    this.createdAt,
  });

  factory DocumentoModel.fromJson(Map<String, dynamic> json) {
    return DocumentoModel(
      id: json['id']?.toString(),
      solicitudId: json['solicitud_id'].toString(),
      clienteId: json['cliente_id'].toString(),
      oficialId: json['oficial_id'].toString(),
      tipoDocumento: json['tipo_documento']?.toString() ?? '',
      nombreArchivo: json['nombre_archivo']?.toString() ?? '',
      storagePath: json['storage_path']?.toString() ?? '',
      estadoSubida: json['estado_subida']?.toString() ?? 'SUBIDO',
      syncStatus: json['sync_status']?.toString() ?? 'SINCRONIZADO',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}