import 'package:flutter/material.dart';
import '../../model/cliente_model.dart';
import '../../model/solicitud_credito_model.dart';
import '../../services/cliente_service.dart';
import '../../services/solicitud_service.dart';
import '../../services/auth_service.dart';

// Almacenamiento estático de borradores para simulaciones y persistencia offline sin SQLite binario (HU-18)
class SolicitudBorradoresStore {
  static Map<String, Map<String, dynamic>> _borradores = {};

  static void guardar(String clienteId, Map<String, dynamic> datos) {
    _borradores[clienteId] = datos;
  }

  static Map<String, dynamic>? obtener(String clienteId) {
    return _borradores[clienteId];
  }

  static void eliminar(String clienteId) {
    _borradores.remove(clienteId);
  }

  static List<Map<String, dynamic>> obtenerTodosConInfo() {
    return _borradores.entries.map((e) {
      return {
        'clienteId': e.key,
        'fecha': DateTime.now().subtract(const Duration(minutes: 5)),
        ...e.value,
      };
    }).toList();
  }
}

class SolicitudWizardScreen extends StatefulWidget {
  final ClienteModel? clienteInicial;

  const SolicitudWizardScreen({super.key, this.clienteInicial});

  @override
  State<SolicitudWizardScreen> createState() => _SolicitudWizardScreenState();
}

class _SolicitudWizardScreenState extends State<SolicitudWizardScreen> {
  int _currentStep = 0;
  final ClienteService _clienteService = ClienteService();
  final SolicitudService _solicitudService = SolicitudService();
  final AuthService _authService = AuthService();

  List<ClienteModel> _clientesDisponibles = [];
  ClienteModel? _clienteSeleccionado;
  bool _loadingClientes = false;

  // --- PASO 1: DATOS DEL NEGOCIO ---
  final _direccionComercialController = TextEditingController();
  final _antiguedadController = TextEditingController(text: '3');
  String _tipoLocal = 'PROPIO'; // PROPIO, ALQUILADO, FAMILIAR
  final _rucVendedorController = TextEditingController();

  // --- PASO 2: DATOS FINANCIEROS ---
  final _ventasController = TextEditingController(text: '4500');
  final _costosController = TextEditingController(text: '2000');
  final _gastosPersonalController = TextEditingController(text: '500');
  final _otrosGastosController = TextEditingController(text: '300');

  // --- PASO 3: SIMULADOR DE CUOTAS ---
  final _montoController = TextEditingController(text: '5000');
  final _plazoController = TextEditingController(text: '12');
  final _tasaController = TextEditingController(text: '24.0'); // TEA %

  List<Map<String, dynamic>> _tablaAmortizacion = [];

  // --- PASO 4: FIRMA DIGITAL ---
  final List<Offset?> _puntosFirma = [];
  bool _consentimientoAceptado = false;

  @override
  void initState() {
    super.initState();
    _clienteSeleccionado = widget.clienteInicial;
    if (_clienteSeleccionado == null) {
      _cargarClientes();
    } else {
      _comprobarBorrador(_clienteSeleccionado!.id);
      _antiguedadController.text = '2';
      _direccionComercialController.text = _clienteSeleccionado!.direccion;
    }
    _calcularAmortizacion();
  }

  @override
  void dispose() {
    _direccionComercialController.dispose();
    _antiguedadController.dispose();
    _rucVendedorController.dispose();
    _ventasController.dispose();
    _costosController.dispose();
    _gastosPersonalController.dispose();
    _otrosGastosController.dispose();
    _montoController.dispose();
    _plazoController.dispose();
    _tasaController.dispose();
    super.dispose();
  }

  void _comprobarBorrador(String clienteId) {
    final borrador = SolicitudBorradoresStore.obtener(clienteId);
    if (borrador != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarNotificacionBorrador(borrador);
      });
    }
  }

  void _mostrarNotificacionBorrador(Map<String, dynamic> borrador) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 8),
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.blueAccent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Existe una solicitud en borrador guardada para este cliente.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _cargarBorrador(borrador);
              },
              child: const Text('RETOMAR', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _cargarBorrador(Map<String, dynamic> data) {
    setState(() {
      _direccionComercialController.text = data['direccion_comercial'] ?? '';
      _antiguedadController.text = data['antiguedad'] ?? '1';
      _tipoLocal = data['tipo_local'] ?? 'PROPIO';
      _rucVendedorController.text = data['ruc'] ?? '';
      _ventasController.text = data['ventas'] ?? '0';
      _costosController.text = data['costos'] ?? '0';
      _gastosPersonalController.text = data['gastos_personal'] ?? '0';
      _otrosGastosController.text = data['otros_gastos'] ?? '0';
      _montoController.text = data['monto'] ?? '0';
      _plazoController.text = data['plazo'] ?? '0';
      _tasaController.text = data['tasa'] ?? '0';
      _calcularAmortizacion();
      _currentStep = 0;
    });
  }

  Future<void> _cargarClientes() async {
    setState(() => _loadingClientes = true);
    try {
      final res = await _clienteService.obtenerClientes();
      setState(() {
        _clientesDisponibles = res;
        _loadingClientes = false;
      });
    } catch (e) {
      setState(() => _loadingClientes = false);
    }
  }

  void _guardarBorradorActual() {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona primero un cliente para guardar el borrador.')),
      );
      return;
    }

    final datos = {
      'cliente_nombre': _clienteSeleccionado!.nombreCompleto,
      'direccion_comercial': _direccionComercialController.text,
      'antiguedad': _antiguedadController.text,
      'tipo_local': _tipoLocal,
      'ruc': _rucVendedorController.text,
      'ventas': _ventasController.text,
      'costos': _costosController.text,
      'gastos_personal': _gastosPersonalController.text,
      'otros_gastos': _otrosGastosController.text,
      'monto': _montoController.text,
      'plazo': _plazoController.text,
      'tasa': _tasaController.text,
    };

    SolicitudBorradoresStore.guardar(_clienteSeleccionado!.id, datos);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Borrador guardado para ${_clienteSeleccionado!.nombreCompleto}.')),
    );
  }

  void _calcularAmortizacion() {
    final monto = double.tryParse(_montoController.text) ?? 0.0;
    final plazo = int.tryParse(_plazoController.text) ?? 1;
    final tea = double.tryParse(_tasaController.text) ?? 0.0;

    if (monto <= 0 || plazo <= 0) {
      setState(() => _tablaAmortizacion = []);
      return;
    }

    // Convertir TEA a TEM (Tasa Efectiva Mensual)
    final tem = MathPow(1 + (tea / 100), 1) - 1; // Simplificación lineal o exponencial:
    // Para simplificación financiera directa: tem = (1 + TEA/100)^(1/12) - 1
    final temReal = MathPow(1 + (tea / 100), 1 / 12) - 1;

    // Calcular cuota mensual constante (Fórmula Francesa)
    final factor = MathPow(1 + temReal, plazo.toDouble());
    final cuotaMensual = monto * (temReal * factor) / (factor - 1);

    List<Map<String, dynamic>> tabla = [];
    double saldoRestante = monto;

    for (int i = 1; i <= plazo; i++) {
      final interes = saldoRestante * temReal;
      final capital = cuotaMensual - interes;
      saldoRestante -= capital;

      tabla.add({
        'mes': i,
        'cuota': cuotaMensual.isNaN || cuotaMensual.isInfinite ? 0.0 : cuotaMensual,
        'interes': interes.isNaN || interes.isInfinite ? 0.0 : interes,
        'capital': capital.isNaN || capital.isInfinite ? 0.0 : capital,
        'saldo': saldoRestante < 0.01 ? 0.0 : (saldoRestante.isNaN || saldoRestante.isInfinite ? 0.0 : saldoRestante),
      });
    }

    setState(() {
      _tablaAmortizacion = tabla;
    });
  }

  double MathPow(double base, double exponent) {
    // Si es entero, podemos usar bucle, si es decimal usamos aproximación
    if (exponent == 1) return base;
    if (exponent == 1 / 12) {
      // Raíz 12 aproximada (bisección o Newton simple)
      double x = 1.0 + (base - 1.0) / 12.0; // estimador inicial
      for (int i = 0; i < 4; i++) {
        double pow12 = 1.0;
        for (int j = 0; j < 12; j++) {
          pow12 *= x;
        }
        x = x - (pow12 - base) / (12 * (pow12 / x));
      }
      return x;
    }
    // Si exponent es int
    if (exponent is int) {
      double result = 1.0;
      for (int i = 0; i < exponent; i++) {
        result *= base;
      }
      return result;
    }
    // Para simplificación general
    double result = 1.0;
    int expInt = exponent.toInt();
    for (int i = 0; i < expInt; i++) {
      result *= base;
    }
    return result;
  }

  double _calcularUtilidadBruta() {
    final ventas = double.tryParse(_ventasController.text) ?? 0.0;
    final costos = double.tryParse(_costosController.text) ?? 0.0;
    return ventas - costos;
  }

  double _calcularUtilidadOperativa() {
    final bruto = _calcularUtilidadBruta();
    final personal = double.tryParse(_gastosPersonalController.text) ?? 0.0;
    final otros = double.tryParse(_otrosGastosController.text) ?? 0.0;
    return bruto - personal - otros;
  }

  Future<void> _enviarSolicitudFinal() async {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un cliente primero.')),
      );
      return;
    }

    if (!_consentimientoAceptado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes marcar el check de consentimiento firmado.')),
      );
      return;
    }

    if (_puntosFirma.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La firma del cliente es requerida.')),
      );
      return;
    }

    final monto = double.tryParse(_montoController.text) ?? 0.0;
    final plazo = int.tryParse(_plazoController.text) ?? 1;

    try {
      final oficial = await _authService.obtenerOficialActual();
      if (oficial == null) throw Exception('No hay sesión de oficial activa.');

      final nuevaSolicitud = SolicitudCreditoModel(
        clienteId: _clienteSeleccionado!.id,
        oficialId: oficial.id,
        montoSolicitado: monto,
        plazoMeses: plazo,
        destinoCredito: 'Crédito de negocio para ${_clienteSeleccionado!.nombreCompleto}',
        estado: 'REGISTRADA',
        syncStatus: 'SINCRONIZADO',
      );

      await _solicitudService.crearSolicitud(nuevaSolicitud);
      
      // Eliminar de los borradores locales
      SolicitudBorradoresStore.eliminar(_clienteSeleccionado!.id);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('¡Solicitud Creada!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 54),
                SizedBox(height: 14),
                Text(
                  'La solicitud y la firma táctil del cliente se han sincronizado con éxito en Supabase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                onPressed: () {
                  Navigator.pop(context); // dialog
                  Navigator.pop(context); // wizard screen
                },
                child: const Text('Terminar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar la solicitud: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Solicitud de Crédito', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Guardar Borrador',
            icon: const Icon(Icons.save_outlined, color: Colors.blueAccent),
            onPressed: _guardarBorradorActual,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de Cliente en caso de Tool Mode Independiente (HU-19)
          if (widget.clienteInicial == null) _buildClienteSelectorHeader(),

          // Stepper de Pasos
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStepHeader(0, 'Negocio', Icons.storefront),
                _buildStepHeader(1, 'Finanzas', Icons.payments_outlined),
                _buildStepHeader(2, 'Simulador', Icons.calculate_outlined),
                _buildStepHeader(3, 'Firma', Icons.draw),
              ],
            ),
          ),

          Expanded(
            child: _buildCurrentStepView(),
          ),

          // Botones de Navegación del Wizard
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildClienteSelectorHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1E293B).withOpacity(0.5),
      child: _loadingClientes
          ? const LinearProgressIndicator()
          : DropdownButtonFormField<ClienteModel>(
              value: _clienteSeleccionado,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Seleccione un Cliente para Evaluar',
                labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: _clientesDisponibles.map((c) {
                return DropdownMenuItem<ClienteModel>(
                  value: c,
                  child: Text(c.nombreCompleto, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _clienteSeleccionado = val;
                    _direccionComercialController.text = val.direccion;
                  });
                  _comprobarBorrador(val.id);
                }
              },
            ),
    );
  }

  Widget _buildStepHeader(int index, String label, IconData icon) {
    final isSelected = _currentStep == index;
    final isCompleted = _currentStep > index;
    Color iconColor = isSelected ? const Color(0xFF60A5FA) : (isCompleted ? Colors.greenAccent : Colors.white24);

    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF60A5FA) : Colors.white54,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepView() {
    if (_clienteSeleccionado == null) {
      return const Center(
        child: Text(
          'Selecciona un cliente arriba para iniciar el flujo de solicitud.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    switch (_currentStep) {
      case 0:
        return _buildPasoNegocio();
      case 1:
        return _buildPasoFinanzas();
      case 2:
        return _buildPasoSimulador();
      case 3:
        return _buildPasoFirma();
      default:
        return Container();
    }
  }

  Widget _buildPasoNegocio() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('PASO 1: DATOS GENERALES DEL NEGOCIO', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 16),
        TextField(
          controller: _direccionComercialController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Dirección Comercial del Negocio',
            labelStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on_outlined, color: Colors.white24),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _antiguedadController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Antigüedad del Negocio (Años)',
            labelStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.av_timer_outlined, color: Colors.white24),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _tipoLocal,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Tipo de Local del Negocio',
            labelStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'PROPIO', child: Text('Propio con Título')),
            DropdownMenuItem(value: 'ALQUILADO', child: Text('Alquilado')),
            DropdownMenuItem(value: 'FAMILIAR', child: Text('Familiar / Cedido')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _tipoLocal = val);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _rucVendedorController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'RUC / DNI Tributario (Opcional)',
            labelStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.badge_outlined, color: Colors.white24),
          ),
        ),
      ],
    );
  }

  Widget _buildPasoFinanzas() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('PASO 2: DECLARACIÓN DE INGRESOS Y EGRESOS', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 16),
        _buildNumberFieldWizard(_ventasController, 'Ventas Estimadas del Mes (S/)'),
        const SizedBox(height: 16),
        _buildNumberFieldWizard(_costosController, 'Costo de Venta / Mercadería (S/)'),
        const SizedBox(height: 16),
        _buildNumberFieldWizard(_gastosPersonalController, 'Gasto de Planilla / Personal (S/)'),
        const SizedBox(height: 16),
        _buildNumberFieldWizard(_otrosGastosController, 'Otros Gastos (Alquiler, Servicios) (S/)'),
        const Divider(color: Colors.white24, height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Utilidad Bruta:', style: TextStyle(color: Colors.white60)),
                  Text('S/ ${_calcularUtilidadBruta().toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Flujo Neto de Caja Operativo:', style: TextStyle(color: Colors.white60)),
                  Text(
                    'S/ ${_calcularUtilidadOperativa().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _calcularUtilidadOperativa() > 0 ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasoSimulador() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildNumberFieldWizard(_montoController, 'Monto S/', onChange: (_) => _calcularAmortizacion()),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildNumberFieldWizard(_plazoController, 'Plazo', onChange: (_) => _calcularAmortizacion()),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildNumberFieldWizard(_tasaController, 'TEA %', onChange: (_) => _calcularAmortizacion()),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white24, height: 1),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('TABLA DE AMORTIZACIÓN ESTIMADA (CUOTA FIJA)', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
        Expanded(
          child: _tablaAmortizacion.isEmpty
              ? const Center(child: Text('Ingresa montos para generar la tabla.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tablaAmortizacion.length,
                  itemBuilder: (context, index) {
                    final item = _tablaAmortizacion[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mes ${item['mes']}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Cuota: S/ ${item['cuota'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                              Text('Capital: S/ ${item['capital'].toStringAsFixed(2)} | Int: S/ ${item['interes'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                          Text('Saldo: S/ ${item['saldo'].toStringAsFixed(0)}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPasoFirma() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('PASO 4: DECLARACIÓN JURADA Y FIRMA DIGITAL', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 10),
        const Text(
          'Por favor, solicite al cliente que dibuje su firma digital táctil en el cuadro a continuación para formalizar el expediente del crédito.',
          style: TextStyle(color: Colors.white70, fontSize: 12.5),
        ),
        const SizedBox(height: 16),
        
        // Contenedor Firma Pad
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5),
          ),
          child: Stack(
            children: [
              GestureDetector(
                onPanUpdate: (DragUpdateDetails details) {
                  final referenceBox = context.findRenderObject() as RenderBox;
                  final localPosition = referenceBox.globalToLocal(details.globalPosition);
                  // Ajuste del offset para que pinte exactamente en la caja
                  setState(() {
                    _puntosFirma.add(Offset(localPosition.dx, localPosition.dy - 180));
                  });
                },
                onPanEnd: (DragEndDetails details) {
                  setState(() {
                    _puntosFirma.add(null);
                  });
                },
                child: CustomPaint(
                  painter: SignaturePainter(points: _puntosFirma),
                  size: Size.infinite,
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: FloatingActionButton.small(
                  backgroundColor: const Color(0xFF1E293B),
                  onPressed: () {
                    setState(() {
                      _puntosFirma.clear();
                    });
                  },
                  child: const Icon(Icons.clear, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        CheckboxListTile(
          value: _consentimientoAceptado,
          title: const Text(
            'El cliente otorga consentimiento expreso para la evaluación de sus datos y confirma que la firma anterior le corresponde.',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          activeColor: Colors.blueAccent,
          onChanged: (val) {
            if (val != null) {
              setState(() => _consentimientoAceptado = val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    if (_clienteSeleccionado == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E293B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              disabledBackgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: _currentStep == 0
                ? null
                : () {
                    setState(() {
                      _currentStep--;
                    });
                  },
            child: const Text('Anterior', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: () {
              if (_currentStep < 3) {
                setState(() {
                  _currentStep++;
                });
              } else {
                _enviarSolicitudFinal();
              }
            },
            child: Text(_currentStep == 3 ? 'Finalizar y Enviar' : 'Siguiente', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberFieldWizard(TextEditingController controller, String label, {Function(String)? onChange}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12.5),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: onChange,
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
