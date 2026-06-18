import 'package:supabase_flutter/supabase_flutter.dart';

class TransmisionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> transmitirSolicitud(String solicitudId) async {
    try {
      // Representa la transmisión electrónica hacia el backend real.
      // Más adelante aquí puedes llamar una API bancaria externa.
      await _client.from('solicitudes_credito').update({
        'estado': 'ENVIADA',
        'sync_status': 'SINCRONIZADO',
        'fecha_envio': DateTime.now().toIso8601String(),
      }).eq('id', solicitudId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> marcarErrorTransmision({
    required String solicitudId,
    required String motivo,
  }) async {
    await _client.from('solicitudes_credito').update({
      'estado': 'ERROR_ENVIO',
      'sync_status': 'ERROR',
      'observacion_envio': motivo,
    }).eq('id', solicitudId);
  }
}