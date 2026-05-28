import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/buro_credito_model.dart';

class BuroCreditoService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<BuroCreditoModel> registrarConsultaPendiente({
    required String clienteId,
    required String oficialId,
  }) async {
    try {
      // Estructura preparada para conectar luego una API externa real.
      final data = await _client
          .from('buro_credito')
          .insert({
            'cliente_id': clienteId,
            'oficial_id': oficialId,
            'score': null,
            'resultado': 'PENDIENTE DE CONSULTA EXTERNA',
            'proveedor': 'API_EXTERNA_PENDIENTE',
            'estado_consulta': 'REGISTRADA',
            'payload_respuesta': {},
          })
          .select()
          .single();

      return BuroCreditoModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('No se pudo registrar la consulta de buró.');
    }
  }

  Future<List<BuroCreditoModel>> obtenerConsultasPorCliente(
    String clienteId,
  ) async {
    final data = await _client
        .from('buro_credito')
        .select()
        .eq('cliente_id', clienteId)
        .order('created_at', ascending: false);

    return data
        .map<BuroCreditoModel>(
          (item) => BuroCreditoModel.fromJson(item),
        )
        .toList();
  }
}