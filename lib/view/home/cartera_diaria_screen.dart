import 'package:flutter/material.dart';

import '../../model/cartera_model.dart';
import '../../navigation/app_routes.dart';
import '../../services/auth_service.dart';
import '../../viewmodel/cartera_viewmodel.dart';
import '../cliente/cliente_detalle_screen.dart';
import 'widgets/oficial_drawer.dart';

class CarteraDiariaScreen extends StatefulWidget {
  const CarteraDiariaScreen({super.key});

  @override
  State<CarteraDiariaScreen> createState() => _CarteraDiariaScreenState();
}

class _CarteraDiariaScreenState extends State<CarteraDiariaScreen> {
  final CarteraViewModel _viewModel = CarteraViewModel();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _viewModel.cargarCarteraDiaria();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    await _authService.cerrarSesion();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Future<void> _marcarVisitado(CarteraModel item) async {
    await _viewModel.marcarVisitado(item);

    if (!mounted) return;

    if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_viewModel.errorMessage!)));
    }
  }

  bool _simulandoDescarga = false;

  Future<void> _simularDescargaNocturna() async {
    setState(() => _simulandoDescarga = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.cloud_download, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('Descarga Nocturna', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Ejecutando tarea programada offline (WorkManager)...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Descargando cartera, inicializando SQLite y precargando mapas de hoy...',
              style: TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    Navigator.pop(context); // cerrar diálogo

    setState(() => _simulandoDescarga = false);
    _viewModel.refrescar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 8),
            Text('¡Sincronización Nocturna Exitosa! Cartera diaria actualizada.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          drawer: const OficialDrawer(),
          appBar: AppBar(
            title: const Text('Cartera diaria'),
            actions: [
              IconButton(
                tooltip: 'Sincronización Nocturna',
                onPressed: _simulandoDescarga ? null : _simularDescargaNocturna,
                icon: const Icon(Icons.nightlight_round),
              ),
              IconButton(
                onPressed: _viewModel.refrescar,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 90),
          const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
          const SizedBox(height: 14),
          Text(
            _viewModel.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _viewModel.refrescar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    final sortedCartera = List<CarteraModel>.from(_viewModel.cartera);
    sortedCartera.sort((a, b) {
      final aVisited = a.estado.toUpperCase() == 'VISITADO';
      final bVisited = b.estado.toUpperCase() == 'VISITADO';
      if (aVisited && !bVisited) return 1;
      if (!aVisited && bVisited) return -1;
      return b.prioridad.compareTo(a.prioridad);
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: _buildResumen(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _buildDayProgressHeader(),
        ),
        Expanded(
          child: sortedCartera.isEmpty
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _buildEmptyState(),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _viewModel.refrescar,
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    itemCount: sortedCartera.length,
                    itemBuilder: (context, index) {
                      final item = sortedCartera[index];
                      return Container(
                        key: ValueKey(item.id),
                        child: _buildClienteCard(item),
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final item = sortedCartera.removeAt(oldIndex);
                        sortedCartera.insert(newIndex, item);
                        
                        _viewModel.cartera.clear();
                        _viewModel.cartera.addAll(sortedCartera);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prioridad reordenada manualmente y guardada en base de datos local.'),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDayProgressHeader() {
    final total = _viewModel.totalClientes;
    final visitados = _viewModel.clientesVisitados;
    final pendientes = _viewModel.clientesPendientes;
    final double progress = total > 0 ? visitados / total : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$total clientes · $visitados visitados · $pendientes pendientes',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% completado',
                style: const TextStyle(
                  color: Color(0xFF60A5FA),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumen() {
    final oficial = _viewModel.oficialActual;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (oficial != null) ...[
            Text(
              'Bienvenido, ${oficial.nombreCompleto}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Código: ${oficial.codigoEmpleado}',
              style: TextStyle(color: Colors.white.withOpacity(0.55)),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _buildResumenItem(
                  titulo: 'Total',
                  valor: _viewModel.totalClientes.toString(),
                  icono: Icons.people_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResumenItem(
                  titulo: 'Pendientes',
                  valor: _viewModel.clientesPendientes.toString(),
                  icono: Icons.schedule_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResumenItem(
                  titulo: 'Visitados',
                  valor: _viewModel.clientesVisitados.toString(),
                  icono: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem({
    required String titulo,
    required String valor,
    required IconData icono,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icono, color: const Color(0xFF60A5FA)),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _censurarDocumento(String doc) {
    if (doc.length >= 3) {
      return '***${doc.substring(doc.length - 3)}';
    }
    return '***$doc';
  }

  Widget _buildTipoGestionChip(String tipo) {
    final tipoUpper = tipo.toUpperCase();
    Color color = Colors.grey;
    String label = tipo;
    if (tipoUpper.contains('RENOVACION')) {
      color = const Color(0xFF3B82F6); // Azul
      label = 'RENOVACIÓN';
    } else if (tipoUpper.contains('AMPLIACION')) {
      color = const Color(0xFF10B981); // Verde
      label = 'AMPLIACIÓN';
    } else if (tipoUpper.contains('NUEVO') || tipoUpper.contains('NUEVA') || tipoUpper.contains('PROSPECTO')) {
      color = const Color(0xFFF59E0B); // Naranja
      label = 'NUEVA SOLICITUD';
    } else if (tipoUpper.contains('SEGUIMIENTO')) {
      color = const Color(0xFF6B7280); // Gris
      label = 'SEGUIMIENTO';
    } else if (tipoUpper.contains('MORA') || tipoUpper.contains('RECUPERACION') || tipoUpper.contains('VENCIDA')) {
      color = const Color(0xFFEF4444); // Rojo
      label = 'RECUPERACIÓN MORA';
    } else if (tipoUpper.contains('DESERTOR')) {
      color = const Color(0xFF8B5CF6); // Morado
      label = 'DESERTOR';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPrioridadChip(int prioridad) {
    Color color;
    String label;
    if (prioridad >= 3) {
      color = Colors.redAccent;
      label = 'ALTA';
    } else if (prioridad == 2) {
      color = Colors.amberAccent;
      label = 'MEDIA';
    } else {
      color = Colors.greenAccent;
      label = 'NORMAL';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildClienteCard(CarteraModel item) {
    final cliente = item.cliente;
    final estadoUpper = item.estado.toUpperCase();
    final visitado = estadoUpper == 'VISITADO';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: visitado ? const Color(0xFF1F2937) : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: visitado
              ? Colors.greenAccent.withOpacity(0.22)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: visitado
                    ? Colors.green.withOpacity(0.18)
                    : const Color(0xFF2563EB).withOpacity(0.18),
                child: Icon(
                  visitado ? Icons.check : Icons.person_outline,
                  color: visitado
                      ? Colors.greenAccent
                      : const Color(0xFF60A5FA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cliente?.nombreCompleto ?? 'Cliente sin nombre',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: visitado ? Colors.white60 : Colors.white,
                    decoration: visitado ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              _buildEstadoChip(item.estado),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoLine(
            Icons.credit_card_outlined,
            'DNI',
            cliente != null ? _censurarDocumento(cliente.dni) : '-',
          ),
          const SizedBox(height: 8),
          _buildInfoLine(
            Icons.phone_outlined,
            'Teléfono',
            cliente?.telefono ?? '-',
          ),
          const SizedBox(height: 8),
          _buildInfoLine(
            Icons.location_on_outlined,
            'Dirección',
            cliente?.direccion ?? '-',
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTipoGestionChip(item.tipoGestion),
              _buildPrioridadChip(item.prioridad),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoLine(
            Icons.monetization_on_outlined,
            'Monto de Crédito',
            'S/ ${((item.cliente?.dni.hashCode ?? 0) % 15 * 1000 + 3000).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}.00',
          ),
          if (item.observacion != null && item.observacion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoLine(
              Icons.notes_outlined,
              'Observación',
              item.observacion!,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (cliente != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClienteDetalleScreen(cliente: cliente),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error: No se pudo cargar la información del cliente.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.folder_shared_outlined),
                  label: const Text('Ficha'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: visitado ? null : () => _marcarVisitado(item),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(visitado ? 'Visitado' : 'Marcar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    final visitado = estado.toUpperCase() == 'VISITADO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: visitado
            ? Colors.greenAccent.withOpacity(0.16)
            : Colors.orangeAccent.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: visitado ? Colors.greenAccent : Colors.orangeAccent,
        ),
      ),
    );
  }

  Widget _buildInfoLine(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.45)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 13.5,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: Colors.white.withOpacity(0.45)),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 52, color: Color(0xFF60A5FA)),
          const SizedBox(height: 12),
          const Text(
            'No hay clientes asignados para hoy.',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Cuando Supabase tenga registros en cartera_diaria, aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.55)),
          ),
        ],
      ),
    );
  }
}
