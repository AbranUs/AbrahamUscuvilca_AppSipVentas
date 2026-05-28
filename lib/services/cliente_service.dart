import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/cliente_model.dart';

class ClienteService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<ClienteModel?> obtenerClientePorId(String clienteId) async {
    final data = await _client
        .from('clientes')
        .select()
        .eq('id', clienteId)
        .maybeSingle();

    if (data == null) return null;

    return ClienteModel.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialCrediticio(
    String clienteId,
  ) async {
    final data = await _client
        .from('historial_crediticio')
        .select()
        .eq('cliente_id', clienteId)
        .order('fecha_desembolso', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> obtenerProductosActivos(
    String clienteId,
  ) async {
    final data = await _client
        .from('productos_activos')
        .select()
        .eq('cliente_id', clienteId)
        .eq('estado', 'ACTIVO');

    return List<Map<String, dynamic>>.from(data);
  }
}