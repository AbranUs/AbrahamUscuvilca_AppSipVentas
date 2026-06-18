import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../model/oficial_model.dart';
import '../../../services/auth_service.dart';
import '../../../navigation/app_routes.dart';

class OficialDrawer extends StatefulWidget {
  const OficialDrawer({super.key});

  @override
  State<OficialDrawer> createState() => _OficialDrawerState();
}

class _OficialDrawerState extends State<OficialDrawer> {
  final AuthService _authService = AuthService();
  OficialModel? _oficial;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarOficial();
  }

  Future<void> _cargarOficial() async {
    try {
      final oficial = await _authService.obtenerOficialActual();
      if (mounted) {
        setState(() {
          _oficial = oficial;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cerrarSesion() async {
    if (_oficial == null) {
      await _authService.cerrarSesion();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      return;
    }

    int pendingCount = 0;
    try {
      final res = await Supabase.instance.client
          .from('solicitudes_credito')
          .select('id')
          .eq('sync_status', 'PENDIENTE')
          .eq('oficial_id', _oficial!.id);
      
      pendingCount = res.length;
    } catch (_) {
      // Si falla o no hay conexión, asumimos 0
    }

    if (!mounted) return;

    if (pendingCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Advertencia de Datos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            'Tienes $pendingCount solicitud(es) pendiente(s) de sincronizar. '
            'Si cierras sesión, podrías perder esta información guardada localmente.\n\n'
            '¿Deseas cerrar sesión de todos modos?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(context);
                await _realizarLogout();
              },
              child: const Text('Forzar Cierre'),
            ),
          ],
        ),
      );
    } else {
      await _realizarLogout();
    }
  }

  Future<void> _realizarLogout() async {
    await _authService.cerrarSesion();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    children: [
                      _buildSectionTitle('Estadísticas del Mes'),
                      const SizedBox(height: 10),
                      _buildProgressCard(
                        title: 'Meta de Colocación',
                        value: 'S/ 28,000 / S/ 50,000',
                        percent: 0.56,
                        color: Colors.greenAccent,
                      ),
                      const SizedBox(height: 12),
                      _buildProgressCard(
                        title: 'Visitas Completadas',
                        value: '12 / 20 visitas',
                        percent: 0.60,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Acciones de Campo'),
                      const SizedBox(height: 10),
                      ListTile(
                        leading: const Icon(Icons.analytics_outlined, color: Colors.blueAccent),
                        title: const Text('Pre-evaluar y Campañas', style: TextStyle(color: Colors.white, fontSize: 13.5)),
                        dense: true,
                        onTap: () {
                          Navigator.pop(context); // Cierra el Drawer
                          Navigator.pushNamed(context, AppRoutes.preEvaluacion);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.post_add_outlined, color: Colors.greenAccent),
                        title: const Text('Simulador y Nueva Solicitud', style: TextStyle(color: Colors.white, fontSize: 13.5)),
                        dense: true,
                        onTap: () {
                          Navigator.pop(context); // Cierra el Drawer
                          Navigator.pushNamed(context, AppRoutes.solicitudWizard);
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Resumen de Hoy'),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.check_circle_outline, 'Visitas completadas', '1'),
                      _buildInfoRow(Icons.schedule_outlined, 'Visitas pendientes', '4'),
                      _buildInfoRow(Icons.attach_money_outlined, 'Solicitudes enviadas', '2'),
                    ],
                  ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.15),
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF2563EB),
            child: Icon(Icons.person, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            _isLoading
                ? 'Cargando...'
                : (_oficial?.nombreCompleto ?? 'Oficial de Crédito'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isLoading
                ? ''
                : 'Código: ${_oficial?.codigoEmpleado ?? 'Sin Código'}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withOpacity(0.4),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String value,
    required double percent,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
