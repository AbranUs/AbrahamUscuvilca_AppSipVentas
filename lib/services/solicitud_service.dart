import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/solicitud_credito_model.dart';

class SolicitudService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<SolicitudCreditoModel> crearSolicitud(
    SolicitudCreditoModel solicitud,
  ) async {
    try {
      final data = await _client
          .from('solicitudes_credito')
          .insert({
            ...solicitud.toInsertJson(),

            // Estado preparado para offline-first.
            // Si luego guardas localmente primero, puedes mandar PENDIENTE_SYNC.
            'sync_status': 'SINCRONIZADO',
          })
          .select()
          .single();

      return SolicitudCreditoModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('No se pudo registrar la solicitud.');
    }
  }

  Future<List<SolicitudCreditoModel>> obtenerSolicitudesPorOficial(
    String oficialId,
  ) async {
    final data = await _client
        .from('solicitudes_credito')
        .select()
        .eq('oficial_id', oficialId)
        .order('created_at', ascending: false);

    return data
        .map<SolicitudCreditoModel>(
          (item) => SolicitudCreditoModel.fromJson(item),
        )
        .toList();
  }
}