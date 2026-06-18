import 'package:flutter/material.dart';

class PreEvaluacionCampanasScreen extends StatefulWidget {
  const PreEvaluacionCampanasScreen({super.key});

  @override
  State<PreEvaluacionCampanasScreen> createState() => _PreEvaluacionCampanasScreenState();
}

class _PreEvaluacionCampanasScreenState extends State<PreEvaluacionCampanasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controladores Pre-evaluación
  final _ingresosController = TextEditingController(text: '3500');
  final _gastosNegocioController = TextEditingController(text: '1200');
  final _gastosFamiliaresController = TextEditingController(text: '800');
  final _cuotasOtrasDeudasController = TextEditingController(text: '300');
  final _montoSolicitudController = TextEditingController(text: '5000');
  final _plazoController = TextEditingController(text: '12');

  String _dictamen = 'APTO'; // APTO, REVISAR, NO PROCEDE
  double _excedente = 1200;
  double _capacidadPago = 840;
  double _cuotaEstimada = 490;

  // Catálogo de Campañas (HU-16)
  final List<Map<String, dynamic>> _campanas = [
    {
      'id': '1',
      'nombre': 'Campaña Fiestas Patrias 2026',
      'descripcion': 'Financiamiento rápido para stock de mercadería con tasa preferencial del 18% TEA.',
      'montoMax': 30000.0,
      'tasa': '18.0% TEA',
      'expiracion': DateTime(2026, 07, 31),
      'color': Colors.redAccent,
    },
    {
      'id': '2',
      'nombre': 'Campaña Reactiva Bodegas',
      'descripcion': 'Dirigido a comercios minoristas de abarrotes. Evaluación simplificada sin firma de cónyuge.',
      'montoMax': 15000.0,
      'tasa': '22.0% TEA',
      'expiracion': DateTime(2026, 09, 15),
      'color': Colors.blueAccent,
    },
    {
      'id': '3',
      'nombre': 'Campaña Campesina Agro',
      'descripcion': 'Crédito agrícola con periodo de gracia de hasta 3 meses para cultivos transitorios.',
      'montoMax': 25000.0,
      'tasa': '16.5% TEA',
      'expiracion': DateTime(2026, 05, 30), // Expirado
      'color': Colors.amberAccent,
    },
    {
      'id': '4',
      'nombre': 'Campaña Mujer Emprendedora',
      'descripcion': 'Exclusivo para mujeres jefas de hogar con negocios de manufactura o comercio de ropa.',
      'montoMax': 20000.0,
      'tasa': '19.5% TEA',
      'expiracion': DateTime(2026, 12, 31),
      'color': Colors.purpleAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calcularPreEvaluacion();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ingresosController.dispose();
    _gastosNegocioController.dispose();
    _gastosFamiliaresController.dispose();
    _cuotasOtrasDeudasController.dispose();
    _montoSolicitudController.dispose();
    _plazoController.dispose();
    super.dispose();
  }

  void _calcularPreEvaluacion() {
    final ingresos = double.tryParse(_ingresosController.text) ?? 0.0;
    final gastosNeg = double.tryParse(_gastosNegocioController.text) ?? 0.0;
    final gastosFam = double.tryParse(_gastosFamiliaresController.text) ?? 0.0;
    final cuotasOtras = double.tryParse(_cuotasOtrasDeudasController.text) ?? 0.0;
    final montoSolicitado = double.tryParse(_montoSolicitudController.text) ?? 0.0;
    final plazo = int.tryParse(_plazoController.text) ?? 1;

    // Calcular excedente
    final totalGastos = gastosNeg + gastosFam;
    final excedenteCalculado = ingresos - totalGastos;

    // Capacidad de pago (70% del excedente)
    final capPago = excedenteCalculado * 0.70;

    // Tasa mensual simulada del 2%
    const tasaMensual = 0.02;
    // Cuota estimada formula frances simplificada
    final cuotaEst = montoSolicitado * (tasaMensual * MathPow(1 + tasaMensual, plazo)) / (MathPow(1 + tasaMensual, plazo) - 1);

    String dictamenCalculado = 'APTO';
    if (excedenteCalculado <= 0) {
      dictamenCalculado = 'NO PROCEDE';
    } else if (capPago < (cuotaEst + cuotasOtras)) {
      dictamenCalculado = 'REVISAR';
      if (excedenteCalculado < cuotaEst) {
        dictamenCalculado = 'NO PROCEDE';
      }
    }

    setState(() {
      _excedente = excedenteCalculado;
      _capacidadPago = capPago;
      _cuotaEstimada = cuotaEst.isNaN || cuotaEst.isInfinite ? 0.0 : cuotaEst;
      _dictamen = dictamenCalculado;
    });
  }

  double MathPow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Pre-evaluación y Campañas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF60A5FA),
          labelColor: const Color(0xFF60A5FA),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Pre-evaluar'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Campañas Activas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPreEvaluacionTab(),
          _buildCampanasTab(now),
        ],
      ),
    );
  }

  Widget _buildPreEvaluacionTab() {
    Color dictamenColor = Colors.greenAccent;
    IconData dictamenIcon = Icons.check_circle;
    String dictamenDesc = 'Cliente cumple con excedentes holgados y capacidad de pago óptima.';

    if (_dictamen == 'REVISAR') {
      dictamenColor = Colors.amberAccent;
      dictamenIcon = Icons.warning_amber_rounded;
      dictamenDesc = 'Capacidad de pago ajustada. Requiere aval o reducción del monto solicitado.';
    } else if (_dictamen == 'NO PROCEDE') {
      dictamenColor = Colors.redAccent;
      dictamenIcon = Icons.cancel;
      dictamenDesc = 'Cliente sobreendeudado o con flujo de caja negativo. Solicitud inviable.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de Dictamen
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: dictamenColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dictamenColor.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(dictamenIcon, color: dictamenColor, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'DICTAMEN: $_dictamen',
                      style: TextStyle(color: dictamenColor, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  dictamenDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultIndicator('Excedente Neto', 'S/ ${_excedente.toStringAsFixed(2)}', Colors.white),
                    _buildResultIndicator('Capac. Pago (70%)', 'S/ ${_capacidadPago.toStringAsFixed(2)}', Colors.white),
                    _buildResultIndicator('Cuota Est.', 'S/ ${_cuotaEstimada.toStringAsFixed(2)}', dictamenColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Formulario de Entradas
          const Text(
            'FORMULARIO DE EVALUACIÓN DE INGRESOS',
            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _ingresosController,
            label: 'Ingresos Mensuales Declarados (S/)',
            icon: Icons.monetization_on_outlined,
          ),
          const SizedBox(height: 14),
          _buildNumberField(
            controller: _gastosNegocioController,
            label: 'Gastos de Operación del Negocio (S/)',
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 14),
          _buildNumberField(
            controller: _gastosFamiliaresController,
            label: 'Gastos Familiares / Canasta Básica (S/)',
            icon: Icons.home_outlined,
          ),
          const SizedBox(height: 14),
          _buildNumberField(
            controller: _cuotasOtrasDeudasController,
            label: 'Cuotas de Otras Deudas Financieras (S/)',
            icon: Icons.credit_card_outlined,
          ),
          const Divider(color: Colors.white10, height: 30),
          const Text(
            'DATOS DEL CRÉDITO SIMULADO',
            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: _montoSolicitudController,
                  label: 'Monto Solicitado',
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  controller: _plazoController,
                  label: 'Plazo (Meses)',
                  icon: Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guardando pre-evaluación en el registro de prospección...')),
              );
            },
            child: const Text('Guardar Registro de Prospección', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCampanasTab(DateTime now) {
    // Filtrar campanas no expiradas (o mostrarlas etiquetadas)
    final campanasFiltradas = _campanas.where((c) {
      final exp = c['expiracion'] as DateTime;
      return exp.isAfter(now) || exp.year == now.year && exp.month == now.month && exp.day == now.day;
    }).toList();

    final campanasExpiradas = _campanas.where((c) {
      final exp = c['expiracion'] as DateTime;
      return exp.isBefore(now) && !(exp.year == now.year && exp.month == now.month && exp.day == now.day);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'CAMPAÑAS VIGENTES',
          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 10),
        if (campanasFiltradas.isEmpty)
          const Card(
            color: Color(0xFF1E293B),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No hay campañas de colocación vigentes en este momento.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          ...campanasFiltradas.map((c) => _buildCampanaCard(c, expired: false)),
        const SizedBox(height: 24),
        const Text(
          'CAMPAÑAS ANTERIORES / EXPIRADAS',
          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 10),
        ...campanasExpiradas.map((c) => _buildCampanaCard(c, expired: true)),
      ],
    );
  }

  Widget _buildCampanaCard(Map<String, dynamic> c, {required bool expired}) {
    final exp = c['expiracion'] as DateTime;
    final formattedDate = '${exp.day.toString().padLeft(2, '0')}/${exp.month.toString().padLeft(2, '0')}/${exp.year}';
    final Color badgeColor = expired ? Colors.grey : (c['color'] as Color);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: expired ? Colors.white10 : badgeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  c['nombre'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: expired ? Colors.white54 : Colors.white,
                    decoration: expired ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: expired ? Colors.white10 : badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  expired ? 'EXPIRADA' : 'VIGENTE',
                  style: TextStyle(color: expired ? Colors.white38 : badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c['descripcion'],
            style: TextStyle(color: expired ? Colors.white38 : Colors.white70, fontSize: 12),
          ),
          const Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCampanaInfoDetail('Monto Max.', 'S/ ${c['montoMax'].toStringAsFixed(0)}', expired),
              _buildCampanaInfoDetail('Tasa Preferencial', c['tasa'], expired),
              _buildCampanaInfoDetail('Vence el', formattedDate, expired),
            ],
          ),
          if (!expired) ...[
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: badgeColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Interés en la "${c['nombre']}" registrado con éxito.')),
                );
              },
              child: const Text('Registrar Interés de Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCampanaInfoDetail(String label, String val, bool expired) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 3),
        Text(val, style: TextStyle(color: expired ? Colors.white54 : Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      ],
    );
  }

  Widget _buildResultIndicator(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFF60A5FA), size: 18),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      onChanged: (val) {
        _calcularPreEvaluacion();
      },
    );
  }
}
