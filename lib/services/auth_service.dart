import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/oficial_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  /// Login usando código de empleado y contraseña
  Future<OficialModel> loginConCodigo({
    required String codigoEmpleado,
    required String password,
  }) async {
    try {
      // Busca el oficial en la tabla oficiales por su código
      final oficialData = await _client
          .from('oficiales')
          .select(
            'id, auth_user_id, codigo_empleado, nombres, apellidos, email, estado',
          )
          .eq('codigo_empleado', codigoEmpleado)
          .maybeSingle();

      if (oficialData == null) {
        throw Exception('No existe un oficial con ese código.');
      }

      final oficial = OficialModel.fromJson(oficialData);

      if (oficial.estado != 'ACTIVO') {
        throw Exception('El oficial no se encuentra activo.');
      }

      // Inicia sesión con Supabase Auth usando el email registrado
      final authResponse = await _client.auth.signInWithPassword(
        email: oficial.email,
        password: password,
      );

      final user = authResponse.user;

      if (user == null) {
        throw Exception('No se pudo iniciar sesión.');
      }

      final normalizedAuthUserId = oficial.authUserId.trim().toLowerCase();
      if (normalizedAuthUserId.isEmpty || normalizedAuthUserId == 'null' || normalizedAuthUserId != user.id.toLowerCase()) {
        // Enlazar o corregir automáticamente el auth_user_id en la base de datos
        await _client
            .from('oficiales')
            .update({'auth_user_id': user.id})
            .eq('id', oficial.id);
        
        return OficialModel(
          id: oficial.id,
          authUserId: user.id,
          codigoEmpleado: oficial.codigoEmpleado,
          nombres: oficial.nombres,
          apellidos: oficial.apellidos,
          email: oficial.email,
          estado: oficial.estado,
        );
      }

      return oficial;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Obtiene el oficial actualmente logueado
  Future<OficialModel?> obtenerOficialActual() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('oficiales')
        .select(
          'id, auth_user_id, codigo_empleado, nombres, apellidos, email, estado',
        )
        .eq('auth_user_id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return OficialModel.fromJson(data);
  }

  /// Cierra sesión del oficial
  Future<void> cerrarSesion() async {
    await _client.auth.signOut();
  }
}