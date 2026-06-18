import 'package:flutter/material.dart';
import '../../model/solicitud_credito_model.dart';
import '../../services/auth_service.dart';
import '../../services/solicitud_service.dart';
import '../../services/transmision_service.dart';
import '../home/widgets/oficial_drawer.dart';

class TransmisionScreen extends StatefulWidget {
  const TransmisionScreen({super.key});

  @override
  State<TransmisionScreen> createState() => _TransmisionScreenState();
}

class _TransmisionScreenState extends State<TransmisionScreen> {
  final SolicitudService _solicitudService = SolicitudService();
  final TransmisionService _transmisionService = TransmisionService();
  final AuthService _authService = AuthService();

  List<SolicitudCreditoModel> _solicitudes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final oficial = await _authService.obtenerOficialActual();
      if (oficial == null) {
        throw Exception('No se encontró la sesión del oficial.');
      }

      final solicitudes = await _solicitudService.obtenerSolicitudesPorOficial(oficial.id);
      if (mounted) {
        setState(() {
          _solicitudes = solicitudes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _transmitirSolicitud(SolicitudCreditoModel solicitud) async {
    if (solicitud.id == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Iniciando transmisión electrónica a sistemas centrales...')),
    );

    try {
      await _transmisionService.transmitirSolicitud(solicitud.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud transmitida y sincronizada con éxito.')),
        );
        _cargarSolicitudes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en transmisión: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPendientesSync = _solicitudes.where((s) => s.syncStatus == 'PENDIENTE').length;

    return Scaffold(
      drawer: const OficialDrawer(),
      appBar: AppBar(
        title: const Text('Transmisión y Sincronización'),
        actions: [
          IconButton(
            onPressed: _cargarSolicitudes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarSolicitudes,
        child: Column(
          children: [
            if (totalPendientesSync > 0) _buildSyncAlert(totalPendientesSync),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncAlert(int count) {
    return Container(
      color: Colors.amberAccent.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tienes $count solicitudes pendientes de transmisión.',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () async {
              for (var sol in _solicitudes.where((s) => s.syncStatus == 'PENDIENTE')) {
                await _transmitirSolicitud(sol);
              }
            },
            child: const Text('Enviar Todo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _cargarSolicitudes, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_solicitudes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 60, color: Colors.blueAccent),
                const SizedBox(height: 12),
                const Text(
                  'No hay solicitudes registradas.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Crea solicitudes en la ficha de cada cliente.',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _solicitudes.length,
      itemBuilder: (context, index) {
        final sol = _solicitudes[index];
        final transmitida = sol.estado == 'ENVIADA' || sol.estado == 'APROBADA';
        final syncPendiente = sol.syncStatus == 'PENDIENTE';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: syncPendiente ? Colors.amberAccent.withOpacity(0.2) : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Solicitud #${sol.id?.substring(0, 8) ?? 'Temp'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent),
                  ),
                  _buildStatusChip(sol.estado),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              _buildInfoRow('Cliente ID', sol.clienteId),
              _buildInfoRow('Monto Solicitado', 'S/ ${sol.montoSolicitado.toStringAsFixed(2)}'),
              _buildInfoRow('Plazo', '${sol.plazoMeses} meses'),
              _buildInfoRow('Destino', sol.destinoCredito),
              _buildInfoRow('Estado Sync', sol.syncStatus, color: syncPendiente ? Colors.amber : Colors.green),
              if (sol.createdAt != null)
                _buildInfoRow('Fecha Registro', sol.createdAt!.toLocal().toString().substring(0, 16)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Acción simulada de ver expediente de documentos
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Visualizando expediente digital de documentos...')),
                        );
                      },
                      child: const Text('Ver Expediente', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  if (!transmitida) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => _transmitirSolicitud(sol),
                        icon: const Icon(Icons.send_rounded, size: 14),
                        label: const Text('Transmitir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color ?? Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String estado) {
    Color chipColor;
    Color textColor;

    switch (estado.toUpperCase()) {
      case 'APROBADA':
        chipColor = Colors.green.withOpacity(0.12);
        textColor = Colors.greenAccent;
        break;
      case 'ENVIADA':
        chipColor = Colors.blue.withOpacity(0.12);
        textColor = Colors.blueAccent;
        break;
      case 'RECHAZADA':
      case 'ERROR_ENVIO':
        chipColor = Colors.red.withOpacity(0.12);
        textColor = Colors.redAccent;
        break;
      default:
        chipColor = Colors.orange.withOpacity(0.12);
        textColor = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        estado,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}
