import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/documento_model.dart';

class DocumentoService {
  final SupabaseClient _client = Supabase.instance.client;

  static const String bucketDocumentos = 'documentos-clientes';

  Future<DocumentoModel> subirDocumento({
    required File archivo,
    required String solicitudId,
    required String clienteId,
    required String oficialId,
    required String tipoDocumento,
  }) async {
    try {
      final extension = archivo.path.split('.').last;
      final nombreArchivo =
          '${DateTime.now().millisecondsSinceEpoch}.$extension';

      final storagePath =
          '$oficialId/$clienteId/$solicitudId/$tipoDocumento/$nombreArchivo';

      // Subida real a Supabase Storage.
      await _client.storage.from(bucketDocumentos).upload(
            storagePath,
            archivo,
            fileOptions: const FileOptions(
              upsert: true,
            ),
          );

      // Luego registramos la metadata del documento en la base de datos.
      final data = await _client
          .from('documentos')
          .insert({
            'solicitud_id': solicitudId,
            'cliente_id': clienteId,
            'oficial_id': oficialId,
            'tipo_documento': tipoDocumento,
            'nombre_archivo': nombreArchivo,
            'storage_path': storagePath,
            'estado_subida': 'SUBIDO',
            'sync_status': 'SINCRONIZADO',
          })
          .select()
          .single();

      return DocumentoModel.fromJson(data);
    } on StorageException catch (e) {
      throw Exception(e.message);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('No se pudo subir el documento.');
    }
  }
}