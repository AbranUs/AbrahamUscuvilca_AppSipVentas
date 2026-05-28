import 'package:flutter/material.dart';

import '../../model/cartera_model.dart';
import '../../navigation/app_routes.dart';
import '../../services/auth_service.dart';
import '../../viewmodel/cartera_viewmodel.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cartera diaria'),
            actions: [
              IconButton(
                onPressed: _viewModel.refrescar,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _viewModel.refrescar,
            child: _buildBody(),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_viewModel.errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 90),
          const Icon(
            Icons.error_outline,
            size: 54,
            color: Colors.redAccent,
          ),
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

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _buildResumen(),
        const SizedBox(height: 18),
        if (_viewModel.cartera.isEmpty)
          _buildEmptyState()
        else
          ..._viewModel.cartera.map(_buildClienteCard),
      ],
    );
  }

  Widget _buildResumen() {
    final oficial = _viewModel.oficialActual;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (oficial != null) ...[
            Text(
              'Bienvenido, ${oficial.nombreCompleto}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Código: ${oficial.codigoEmpleado}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
              ),
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
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
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

  Widget _buildClienteCard(CarteraModel item) {
    final cliente = item.cliente;
    final estadoUpper = item.estado.toUpperCase();
    final visitado = estadoUpper == 'VISITADO';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
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
                  color: visitado ? Colors.greenAccent : const Color(0xFF60A5FA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cliente?.nombreCompleto ?? 'Cliente sin nombre',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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
            cliente?.dni ?? '-',
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
          _buildInfoLine(
            Icons.assignment_outlined,
            'Gestión',
            item.tipoGestion,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Ficha del cliente se conectará en la pantalla cliente.',
                        ),
                      ),
                    );
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

  Widget _buildInfoLine(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.white.withOpacity(0.45),
        ),
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
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                  ),
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
          const Icon(
            Icons.inbox_outlined,
            size: 52,
            color: Color(0xFF60A5FA),
          ),
          const SizedBox(height: 12),
          const Text(
            'No hay clientes asignados para hoy.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cuando Supabase tenga registros en cartera_diaria, aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}