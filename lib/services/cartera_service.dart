import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/cartera_model.dart';

class CarteraService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<CarteraModel>> obtenerCarteraDiaria({
    required String oficialId,
    DateTime? fecha,
  }) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      final fechaIso =
          '${fechaConsulta.year.toString().padLeft(4, '0')}-'
          '${fechaConsulta.month.toString().padLeft(2, '0')}-'
          '${fechaConsulta.day.toString().padLeft(2, '0')}';

      final response = await _client
          .from('cartera_diaria')
          .select('''
            id,
            oficial_id,
            cliente_id,
            fecha,
            tipo_gestion,
            estado,
            prioridad,
            observacion,
            clientes (
              id,
              dni,
              nombres,
              apellidos,
              telefono,
              direccion,
              latitud,
              longitud,
              estado,
              fecha_registro
            )
          ''')
          .eq('oficial_id', oficialId)
          .eq('fecha', fechaIso)
          .order('prioridad', ascending: false);

      return response
          .map<CarteraModel>(
            (item) => CarteraModel.fromJson(item),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('No se pudo cargar la cartera diaria.');
    }
  }

  Future<void> actualizarEstadoGestion({
    required String carteraId,
    required String estado,
    String? observacion,
  }) async {
    try {
      await _client.from('cartera_diaria').update({
        'estado': estado,
        if (observacion != null) 'observacion': observacion,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', carteraId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}