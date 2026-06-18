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

  /// Registra un nuevo cliente en Supabase
  Future<ClienteModel> crearCliente(ClienteModel cliente) async {
    try {
      final data = await _client.from('clientes').insert({
        'dni': cliente.dni,
        'nombres': cliente.nombres,
        'apellidos': cliente.apellidos,
        'telefono': cliente.telefono,
        'direccion': cliente.direccion,
        if (cliente.latitud != null) 'latitud': cliente.latitud,
        if (cliente.longitud != null) 'longitud': cliente.longitud,
        'estado': cliente.estado,
      }).select().single();

      return ClienteModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('No se pudo registrar el cliente.');
    }
  }

  Future<List<ClienteModel>> obtenerClientes() async {
    final data = await _client.from('clientes').select().order('apellidos', ascending: true);
    return data.map<ClienteModel>((item) => ClienteModel.fromJson(item)).toList();
  }
}