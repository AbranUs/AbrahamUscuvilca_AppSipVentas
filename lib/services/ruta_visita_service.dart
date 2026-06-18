import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/ruta_visita_model.dart';

class RutaVisitaService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<RutaVisitaModel>> obtenerRutaDelDia({
    required String oficialId,
    DateTime? fecha,
  }) async {
    final fechaConsulta = fecha ?? DateTime.now();

    final fechaIso =
        '${fechaConsulta.year.toString().padLeft(4, '0')}-'
        '${fechaConsulta.month.toString().padLeft(2, '0')}-'
        '${fechaConsulta.day.toString().padLeft(2, '0')}';

    final data = await _client
        .from('ruta_visitas')
        .select('''
          id,
          cartera_id,
          cliente_id,
          oficial_id,
          latitud,
          longitud,
          direccion,
          estado_visita,
          fecha_visita,
          clientes (
            nombres,
            apellidos
          )
        ''')
        .eq('oficial_id', oficialId)
        .eq('fecha_visita', fechaIso);

    return data
        .map<RutaVisitaModel>(
          (item) => RutaVisitaModel.fromJson(item),
        )
        .toList();
  }
}