import 'dart:io' as io;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../model/cliente_model.dart';
import '../../model/buro_credito_model.dart';
import '../../model/solicitud_credito_model.dart';
import '../../services/cliente_service.dart';
import '../../services/buro_credito_service.dart';
import '../../services/solicitud_service.dart';
import '../../services/documento_service.dart';
import '../../services/auth_service.dart';
import '../solicitud/solicitud_wizard_screen.dart';
import '../documento/camara_simulador_screen.dart';

class ClienteDetalleScreen extends StatefulWidget {
  final ClienteModel cliente;

  const ClienteDetalleScreen({super.key, required this.cliente});

  @override
  State<ClienteDetalleScreen> createState() => _ClienteDetalleScreenState();
}

class _ClienteDetalleScreenState extends State<ClienteDetalleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClienteService _clienteService = ClienteService();
  final BuroCreditoService _buroService = BuroCreditoService();
  final SolicitudService _solicitudService = SolicitudService();
  final DocumentoService _documentoService = DocumentoService();
  final AuthService _authService = AuthService();

  // Estados de carga
  bool _loadingHistorial = true;
  bool _loadingProductos = true;
  bool _loadingBuro = true;

  // Listas de datos
  List<Map<String, dynamic>> _historial = [];
  List<Map<String, dynamic>> _productos = [];
  List<BuroCreditoModel> _consultasBuro = [];

  // Formulario de Nueva Solicitud
  final _montoController = TextEditingController();
  final _plazoController = TextEditingController();
  final _destinoController = TextEditingController();

  // Carga de Documentos
  String _tipoDocSeleccionado = 'DNI_FRONTAL';
  bool _subiendoDocumento = false;
  bool _consentimientoBuro = false;
  bool _clienteBloqueadoListasNegras = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarDatosDePestanas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _montoController.dispose();
    _plazoController.dispose();
    _destinoController.dispose();
    super.dispose();
  }

  void _cargarDatosDePestanas() {
    _cargarHistorial();
    _cargarProductos();
    _cargarConsultasBuro();
  }

  Future<void> _cargarHistorial() async {
    try {
      final res = await _clienteService.obtenerHistorialCrediticio(widget.cliente.id);
      if (mounted) {
        setState(() {
          _historial = res;
          _loadingHistorial = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingHistorial = false);
    }
  }

  Future<void> _cargarProductos() async {
    try {
      final res = await _clienteService.obtenerProductosActivos(widget.cliente.id);
      if (mounted) {
        setState(() {
          _productos = res;
          _loadingProductos = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingProductos = false);
    }
  }

  Future<void> _cargarConsultasBuro() async {
    try {
      final res = await _buroService.obtenerConsultasPorCliente(widget.cliente.id);
      if (mounted) {
        setState(() {
          _consultasBuro = res;
          _loadingBuro = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingBuro = false);
    }
  }

  // --- ACCIÓN: CONSULTAR BURÓ ---
  Future<void> _consultarBuroCredito() async {
    if (!_consentimientoBuro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe marcar la casilla de consentimiento firmado para continuar.')),
      );
      return;
    }

    final nombreLower = widget.cliente.nombreCompleto.toLowerCase();
    final isBlacklisted = widget.cliente.dni == '99999999' ||
        nombreLower.contains('osama') ||
        nombreLower.contains('pep') ||
        nombreLower.contains('ofac');

    if (isBlacklisted) {
      setState(() {
        _clienteBloqueadoListasNegras = true;
        _loadingBuro = false;
      });

      // Registrar auditoría de cruce restrictivo en base de datos Supabase (HU-24)
      try {
        final oficial = await _authService.obtenerOficialActual();
        await Supabase.instance.client.from('buro_credito').insert({
          'cliente_id': widget.cliente.id,
          'oficial_id': oficial?.id ?? 'bd86ac36-985d-472f-ba8e-326373fd2df5',
          'score': 0,
          'resultado': 'BLOQUEADO: Coincidencia en Listas Restrictivas (PEP/OFAC) - Auditoría Enviada',
          'proveedor': 'AUDIT_PEP_OFAC',
          'estado_consulta': 'BLOQUEADO',
          'payload_respuesta': {'audit': 'OFAC/PEP Match', 'nombre': widget.cliente.nombreCompleto, 'dni': widget.cliente.dni},
        });
      } catch (_) {}

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Row(
            children: [
              Icon(Icons.gavel, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('BLOQUEO DE SEGURIDAD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            'El sistema ha detectado una coincidencia crítica en Listas Negras (OFAC / PEP) para el cliente ${widget.cliente.nombreCompleto}.\n\n'
            'Toda operación comercial y de registro ha sido bloqueada preventivamente.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _loadingBuro = true);
    try {
      final oficial = await _authService.obtenerOficialActual();
      if (oficial == null) throw Exception('No hay sesión de oficial.');

      // Registrar consulta
      final nuevaConsulta = await _buroService.registrarConsultaPendiente(
        clienteId: widget.cliente.id,
        oficialId: oficial.id,
      );

      // Generar score aleatorio para simular consulta real
      final scoreSimulado = 400 + (widget.cliente.dni.hashCode % 400); // 400 a 800
      String resultadoSimulado = 'RIESGO ALTO';
      if (scoreSimulado > 650) {
        resultadoSimulado = 'RIESGO BAJO - APROBADO';
      } else if (scoreSimulado > 550) {
        resultadoSimulado = 'RIESGO MEDIO - OBSERVADO';
      }

      // Actualizar en Supabase directamente
      await Supabase.instance.client.from('buro_credito').update({
        'score': scoreSimulado,
        'resultado': resultadoSimulado,
        'proveedor': 'EQUIFAX_API',
        'estado_consulta': 'COMPLETADA',
        'payload_respuesta': {'score': scoreSimulado, 'resultado': resultadoSimulado},
      }).eq('id', nuevaConsulta.id!);

      await _cargarConsultasBuro();

      if (mounted) {
        _mostrarResultadoBuro(scoreSimulado, resultadoSimulado);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al consultar buró: $e')),
        );
        setState(() => _loadingBuro = false);
      }
    }
  }

  void _mostrarResultadoBuro(int score, String resultado) {
    Color scoreColor = Colors.redAccent;
    if (score > 650) {
      scoreColor = Colors.greenAccent;
    } else if (score > 550) {
      scoreColor = Colors.amberAccent;
    }

    final double percent = (score - 300) / 550.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Resultado de Buró de Crédito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            SizedBox(
              width: 140,
              height: 80,
              child: CustomPaint(
                painter: TachometerPainter(
                  scorePercent: percent.clamp(0.0, 1.0),
                  scoreColor: scoreColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$score PUNTOS',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: scoreColor),
            ),
            const SizedBox(height: 10),
            Text(
              resultado,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: scoreColor),
            ),
            const SizedBox(height: 8),
            const Text(
              'Consulta realizada mediante canal oficial Equifax/Experian.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- ACCIÓN: CREAR SOLICITUD DE CRÉDITO ---
  void _mostrarFormularioSolicitud() {
    _montoController.clear();
    _plazoController.clear();
    _destinoController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nueva Solicitud de Crédito',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Monto Solicitado (S/)',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _plazoController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Plazo (Meses)',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _destinoController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Destino del Crédito',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business_center, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _crearSolicitud,
              child: const Text('Crear Solicitud', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _crearSolicitud() async {
    final monto = double.tryParse(_montoController.text);
    final plazo = int.tryParse(_plazoController.text);
    final destino = _destinoController.text.trim();

    if (monto == null || plazo == null || destino.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos correctamente.')),
      );
      return;
    }

    Navigator.pop(context); // Cerrar bottom sheet

    try {
      final oficial = await _authService.obtenerOficialActual();
      if (oficial == null) throw Exception('No hay sesión de oficial.');

      final nuevaSolicitud = SolicitudCreditoModel(
        clienteId: widget.cliente.id,
        oficialId: oficial.id,
        montoSolicitado: monto,
        plazoMeses: plazo,
        destinoCredito: destino,
        estado: 'REGISTRADA',
        syncStatus: 'PENDIENTE', // Iniciado offline
      );

      await _solicitudService.crearSolicitud(nuevaSolicitud);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Solicitud registrada correctamente! Puedes transmitirla en la pestaña Sincronización.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar solicitud: $e')),
        );
      }
    }
  }

  // --- ACCIÓN: SUBIR DOCUMENTOS (WEB SAFE) ---
  Future<void> _subirDocumentoMock() async {
    setState(() => _subiendoDocumento = true);

    try {
      final oficial = await _authService.obtenerOficialActual();
      if (oficial == null) throw Exception('No hay sesión de oficial.');

      // Simulamos progreso de carga
      await Future.delayed(const Duration(seconds: 2));

      final idFalsoSolicitud = 'f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c';
      final nombreArchivo = 'doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '${oficial.id}/${widget.cliente.id}/$idFalsoSolicitud/$_tipoDocSeleccionado/$nombreArchivo';

      if (kIsWeb) {
        // En web, insertamos la metadata directamente evitando dart:io.File
        await Supabase.instance.client.from('documentos').insert({
          'solicitud_id': idFalsoSolicitud,
          'cliente_id': widget.cliente.id,
          'oficial_id': oficial.id,
          'tipo_documento': _tipoDocSeleccionado,
          'nombre_archivo': nombreArchivo,
          'storage_path': storagePath,
          'estado_subida': 'SUBIDO',
          'sync_status': 'SINCRONIZADO',
        });
      } else {
        // En móviles/desktop creamos un archivo falso para la carga
        final archivoFalso = io.File('dummy_path.jpg');
        // Aquí llamaríamos al servicio real, pero en demo simulamos la inserción direta
        await Supabase.instance.client.from('documentos').insert({
          'solicitud_id': idFalsoSolicitud,
          'cliente_id': widget.cliente.id,
          'oficial_id': oficial.id,
          'tipo_documento': _tipoDocSeleccionado,
          'nombre_archivo': nombreArchivo,
          'storage_path': storagePath,
          'estado_subida': 'SUBIDO',
          'sync_status': 'SINCRONIZADO',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Documento $_tipoDocSeleccionado subido y asociado con éxito.')),
        );
        setState(() => _subiendoDocumento = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir documento: $e')),
        );
        setState(() => _subiendoDocumento = false);
      }
    }
  }

  void _mostrarAlertasMora() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Alertas de Mora y Riesgo',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAlertaItem(
              titulo: 'Retraso en otra Entidad (Equifax)',
              detalle: 'El cliente registra 12 días de atraso en Caja Arequipa por S/ 420.00 en su cuota de Mayo.',
              tipo: 'MORA',
            ),
            const SizedBox(height: 12),
            _buildAlertaItem(
              titulo: 'Múltiples Consultas Recientes',
              detalle: 'Se han realizado 3 consultas al buró de crédito en los últimos 7 días por otras entidades.',
              tipo: 'RIESGO',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertaItem({required String titulo, required String detalle, required String tipo}) {
    Color cardColor = tipo == 'MORA' ? Colors.redAccent.withOpacity(0.1) : Colors.amberAccent.withOpacity(0.1);
    Color borderColor = tipo == 'MORA' ? Colors.redAccent : Colors.amberAccent;
    IconData icon = tipo == 'MORA' ? Icons.error_outline : Icons.warning_amber_outlined;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(color: borderColor, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(detalle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cliente.nombreCompleto),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_active, color: Colors.amberAccent),
                onPressed: _mostrarAlertasMora,
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.info_outline)),
            Tab(text: 'Historial', icon: Icon(Icons.history)),
            Tab(text: 'Productos', icon: Icon(Icons.account_balance_wallet_outlined)),
            Tab(text: 'Gestión', icon: Icon(Icons.assignment_turned_in_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPestanaGeneral(),
          _buildPestanaHistorial(),
          _buildPestanaProductos(),
          _buildPestanaGestion(),
        ],
      ),
    );
  }

  // --- DISEÑO PESTAÑA: GENERAL ---
  Widget _buildPestanaGeneral() {
    final cliente = widget.cliente;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_clienteBloqueadoListasNegras)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent),
            ),
            child: const Row(
              children: [
                Icon(Icons.gavel, color: Colors.redAccent),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ATENCIÓN: Este cliente ha sido bloqueado preventivamente por coincidencia en Listas Restrictivas Internacionales (OFAC / PEP). Se ha emitido una alerta de auditoría.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        _buildInfoCard(
          title: 'Información Personal',
          icon: Icons.person,
          children: [
            _buildDetailRow('Nombres', cliente.nombres),
            _buildDetailRow('Apellidos', cliente.apellidos),
            _buildDetailRow('DNI / Cédula', cliente.dni),
            Row(
              children: [
                Expanded(child: _buildDetailRow('Teléfono', cliente.telefono)),
                IconButton(
                  tooltip: 'Llamar directo',
                  icon: const Icon(Icons.phone_in_talk, color: Colors.greenAccent, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Iniciando llamada de voz directa al número ${cliente.telefono}...')),
                    );
                  },
                ),
              ],
            ),
            _buildDetailRow('Fecha Registro', cliente.fechaRegistro?.toLocal().toString().substring(0, 10) ?? '-'),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Evaluación y Oferta Preaprobada',
          icon: Icons.campaign,
          children: [
            _buildDetailRow('Semáforo de Riesgo', 'APTO (RIESGO BAJO)', color: Colors.greenAccent),
            _buildDetailRow('Monto Preaprobado', 'S/ 15,000.00'),
            _buildDetailRow('Confianza del Sistema', '95% (Excelente)'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() {
                  _montoController.text = '15000';
                  _plazoController.text = '12';
                  _destinoController.text = 'Capital de trabajo campaña preaprobado';
                  _tabController.animateTo(3); // Ir a la pestaña de Gestión
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Formulario prellenado con la oferta preaprobada.')),
                );
              },
              icon: const Icon(Icons.forward_to_inbox_rounded),
              label: const Text('Pre-llenar Solicitud', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Dirección y Ubicación',
          icon: Icons.location_on,
          children: [
            _buildDetailRow('Dirección Física', cliente.direccion),
            _buildDetailRow('Latitud GPS', cliente.latitud?.toStringAsFixed(6) ?? 'No registrada'),
            _buildDetailRow('Longitud GPS', cliente.longitud?.toStringAsFixed(6) ?? 'No registrada'),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.blueAccent),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mostrando ubicación en Google Maps...')),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Ver Mapa de Dirección'),
            ),
          ],
        ),
      ],
    );
  }

  // --- DISEÑO PESTAÑA: HISTORIAL ---
  Widget _buildPestanaHistorial() {
    if (_loadingHistorial) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _buildPaymentHistoryChart(),
        const SizedBox(height: 10),
        if (_historial.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('El cliente no registra historial crediticio anterior.', style: TextStyle(color: Colors.white60)),
          ))
        else
          ..._historial.map((item) {
            final estado = item['estado'].toString().toUpperCase();
            Color badgeColor = Colors.green;
            if (estado == 'MORA') badgeColor = Colors.amber;
            if (estado == 'CASTIGADO') badgeColor = Colors.red;

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(Icons.history_edu, color: badgeColor),
                title: Text('Desembolso: S/ ${item['monto']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text('Fecha: ${item['fecha_desembolso']} | Plazo: ${item['plazo_meses']} meses', style: const TextStyle(color: Colors.white60)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: badgeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text(estado, style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPaymentHistoryChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Historial de Pagos (Últimos 12 meses)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('98% Puntualidad', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(12, (index) {
              final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Set', 'Oct', 'Nov', 'Dic'];
              Color barColor = Colors.greenAccent;
              if (index == 4) barColor = Colors.amberAccent; // retraso
              if (index == 9) barColor = Colors.redAccent; // mora

              return Column(
                children: [
                  Container(
                    width: 14,
                    height: 40,
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: barColor, width: 1.5),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.maxFinite,
                        height: index == 4 ? 20 : (index == 9 ? 12 : 36),
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(2),
                            bottomRight: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(meses[index], style: const TextStyle(fontSize: 9, color: Colors.white38)),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: Colors.greenAccent, label: 'Puntual'),
              SizedBox(width: 12),
              _LegendItem(color: Colors.amberAccent, label: 'Atraso < 8d'),
              SizedBox(width: 12),
              _LegendItem(color: Colors.redAccent, label: 'Mora > 30d'),
            ],
          ),
        ],
      ),
    );
  }

  // --- DISEÑO PESTAÑA: PRODUCTOS ACTIVOS ---
  Widget _buildPestanaProductos() {
    if (_loadingProductos) return const Center(child: CircularProgressIndicator());

    if (_productos.isEmpty) {
      return const Center(child: Text('El cliente no cuenta con créditos vigentes.', style: TextStyle(color: Colors.white60)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: _productos.length,
      itemBuilder: (context, index) {
        final prod = _productos[index];
        final total = int.tryParse(prod['cuotas_totales']?.toString() ?? '1') ?? 1;
        final pagadas = int.tryParse(prod['cuotas_pagadas']?.toString() ?? '0') ?? 0;
        final avance = pagadas / total;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prod['nombre_producto']?.toString() ?? 'Préstamo',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Monto Desembolsado', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                  Text('S/ ${prod['monto_original']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saldo Pendiente', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                  Text('S/ ${prod['saldo_pendiente']}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progreso de Cuotas ($pagadas / $total)', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                  Text('${(avance * 100).toInt()}%', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: avance,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DISEÑO PESTAÑA: GESTIÓN (BURÓ, SOLICITUD Y EXPEDIENTE) ---
  Widget _buildPestanaGestion() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Bloque Buró
        _buildInfoCard(
          title: 'Evaluación del Buró',
          icon: Icons.security,
          children: [
            const Text(
              'Realiza una consulta en línea con las principales centrales de riesgo crediticio para habilitar ofertas.',
              style: TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'El cliente otorga consentimiento firmado para consultar centrales de riesgo (Equifax/Experian)',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              value: _consentimientoBuro,
              activeColor: Colors.blueAccent,
              onChanged: _clienteBloqueadoListasNegras ? null : (val) {
                if (val != null) setState(() => _consentimientoBuro = val);
              },
            ),
            const SizedBox(height: 10),
            if (_loadingBuro)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_consultasBuro.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Último score registrado:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Text(
                      '${_consultasBuro.first.score ?? 'N/A'} puntos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: (_consultasBuro.first.score ?? 0) > 650 ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Resultado:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Text(_consultasBuro.first.resultado, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent)),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _consentimientoBuro && !_clienteBloqueadoListasNegras ? const Color(0xFF2563EB) : Colors.grey,
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: _consentimientoBuro && !_clienteBloqueadoListasNegras ? _consultarBuroCredito : null,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Consultar Score Buró', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // Bloque Solicitudes
        _buildInfoCard(
          title: 'Registro de Crédito',
          icon: Icons.note_add_outlined,
          children: [
            const Text(
              'Registra una nueva postulación de crédito comercial para el negocio del cliente.',
              style: TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _clienteBloqueadoListasNegras ? Colors.grey : Colors.green,
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: _clienteBloqueadoListasNegras
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Operación no permitida: Cliente en listas restrictivas (OFAC/PEP).')),
                      );
                    }
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SolicitudWizardScreen(clienteInicial: widget.cliente),
                        ),
                      );
                    },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Nueva Solicitud de Crédito', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Bloque Expediente Digital
        _buildInfoCard(
          title: 'Expediente y Documentos',
          icon: Icons.folder_open_outlined,
          children: [
            const Text(
              'Carga los documentos probatorios requeridos para completar el expediente del cliente (DNI, Recibo de Servicios).',
              style: TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _tipoDocSeleccionado,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Tipo de Documento',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'DNI_FRONTAL', child: Text('DNI - Frontal')),
                DropdownMenuItem(value: 'DNI_REVERSO', child: Text('DNI - Reverso')),
                DropdownMenuItem(value: 'RECIBO_LUZ', child: Text('Recibo de Luz/Agua')),
                DropdownMenuItem(value: 'FOTO_NEGOCIO', child: Text('Fotografía del Negocio')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _tipoDocSeleccionado = val);
              },
            ),
            const SizedBox(height: 14),
            if (_subiendoDocumento)
              const Column(
                children: [
                  LinearProgressIndicator(),
                  SizedBox(height: 6),
                  Text('Subiendo archivo al servidor...', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  side: const BorderSide(color: Colors.white12),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CamaraSimuladorScreen(
                        tipoDocumento: _tipoDocSeleccionado,
                        clienteId: widget.cliente.id,
                        clienteNombre: widget.cliente.nombreCompleto,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Tomar Foto / Cargar Archivo'),
              ),
          ],
        ),
      ],
    );
  }

  // --- HELPERS DE DISEÑO ---
  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

class TachometerPainter extends CustomPainter {
  final double scorePercent;
  final Color scoreColor;

  TachometerPainter({required this.scorePercent, required this.scoreColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 5);
    final radius = size.width / 2;

    // Dibujar el arco base
    final paintBase = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      math.pi,
      math.pi,
      false,
      paintBase,
    );

    // Dibujar el arco de progreso
    final paintProgress = Paint()
      ..color = scoreColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      math.pi,
      math.pi * scorePercent,
      false,
      paintProgress,
    );

    // Dibujar puntero
    final paintNeedle = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final angle = math.pi + (math.pi * scorePercent);
    final needleEnd = Offset(
      center.dx + (radius - 18) * math.cos(angle),
      center.dy + (radius - 18) * math.sin(angle),
    );

    canvas.drawLine(center, needleEnd, paintNeedle);

    final paintCenter = Paint()..color = Colors.white;
    canvas.drawCircle(center, 6, paintCenter);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
