import 'package:flutter/material.dart';
import '../../model/ruta_visita_model.dart';
import '../../services/auth_service.dart';
import '../../services/ruta_visita_service.dart';
import '../home/widgets/oficial_drawer.dart';

class RutaVisitasScreen extends StatefulWidget {
  const RutaVisitasScreen({super.key});

  @override
  State<RutaVisitasScreen> createState() => _RutaVisitasScreenState();
}

class _RutaVisitasScreenState extends State<RutaVisitasScreen> {
  final RutaVisitaService _rutaService = RutaVisitaService();
  final AuthService _authService = AuthService();

  List<RutaVisitaModel> _rutas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarRutas();
  }

  Future<void> _cargarRutas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final oficial = await _authService.obtenerOficialActual();
      if (oficial == null) {
        throw Exception('No se encontró la sesión del oficial.');
      }

      final rutas = await _rutaService.obtenerRutaDelDia(oficialId: oficial.id);
      if (mounted) {
        setState(() {
          _rutas = rutas;
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

  void _verMapaSimulado(RutaVisitaModel ruta, int index) {
    final latController = TextEditingController(text: ruta.latitud.toString());
    final lonController = TextEditingController(text: ruta.longitud.toString());
    final dirController = TextEditingController(text: ruta.direccion);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Row(
              children: [
                const Icon(Icons.map, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Visita: ${ruta.clienteNombre}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 160,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Opacity(
                            opacity: 0.1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                6,
                                (i) => const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Icon(Icons.grid_3x3, size: 20, color: Colors.white),
                                    Icon(Icons.grid_3x3, size: 20, color: Colors.white),
                                    Icon(Icons.grid_3x3, size: 20, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: CustomPaint(
                            size: const Size(160, 160),
                            painter: _MapRoutePainter(),
                          ),
                        ),
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on, size: 30, color: Colors.redAccent),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Dirección Geocodificada (Editable):', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  TextField(
                    controller: dirController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Latitud:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            TextField(
                              controller: latController,
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Longitud:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            TextField(
                              controller: lonController,
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                onPressed: () {
                  final latVal = double.tryParse(latController.text) ?? ruta.latitud;
                  final lonVal = double.tryParse(lonController.text) ?? ruta.longitud;
                  final dirVal = dirController.text.trim();

                  setState(() {
                    _rutas[index] = RutaVisitaModel(
                      id: ruta.id,
                      carteraId: ruta.carteraId,
                      clienteId: ruta.clienteId,
                      oficialId: ruta.oficialId,
                      latitud: latVal,
                      longitud: lonVal,
                      direccion: dirVal.isEmpty ? ruta.direccion : dirVal,
                      estadoVisita: ruta.estadoVisita,
                      fechaVisita: ruta.fechaVisita,
                      clienteNombre: ruta.clienteNombre,
                    );
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coordenadas GPS y dirección geocodificada actualizadas localmente.')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _iniciarVerificacionVisita(RutaVisitaModel ruta, int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.gps_fixed, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('Verificando Ubicación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Validando geocerca GPS para ${ruta.clienteNombre}...',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rango permitido: 500 metros.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loader
      _mostrarAdvertenciaGeocerca(ruta, index);
    });
  }

  void _mostrarAdvertenciaGeocerca(RutaVisitaModel ruta, int index) {
    final justifController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amberAccent),
            SizedBox(width: 10),
            Text('Visita Fuera de Geocerca', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu ubicación GPS actual se encuentra a 720 metros del domicilio registrado de ${ruta.clienteNombre}.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para completar la visita fuera del rango (500m), debes ingresar una justificación obligatoria:',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: justifController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Justificación de visita',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              final justificacion = justifController.text.trim();
              if (justificacion.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor ingrese la justificación obligatoria.')),
                );
                return;
               }

              Navigator.pop(context);
              setState(() {
                _rutas[index] = RutaVisitaModel(
                  id: ruta.id,
                  carteraId: ruta.carteraId,
                  clienteId: ruta.clienteId,
                  oficialId: ruta.oficialId,
                  latitud: ruta.latitud,
                  longitud: ruta.longitud,
                  direccion: ruta.direccion,
                  estadoVisita: 'COMPLETADO',
                  fechaVisita: ruta.fechaVisita,
                  clienteNombre: ruta.clienteNombre,
                );
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Visita completada y justificada: "$justificacion"')),
              );
            },
            child: const Text('Guardar y Completar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const OficialDrawer(),
      appBar: AppBar(
        title: const Text('Ruta de visitas'),
        actions: [
          IconButton(
            onPressed: _cargarRutas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarRutas,
        child: _buildBody(),
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
            ElevatedButton(onPressed: _cargarRutas, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_rutas.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              children: [
                const Icon(Icons.directions_run_outlined, size: 60, color: Colors.blueAccent),
                const SizedBox(height: 12),
                const Text(
                  'No tienes rutas asignadas para hoy.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Las visitas programadas aparecerán aquí.',
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
      itemCount: _rutas.length,
      itemBuilder: (context, index) {
        final ruta = _rutas[index];
        final completado = ruta.estadoVisita.toUpperCase() == 'COMPLETADO';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: completado ? Colors.greenAccent.withOpacity(0.2) : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: completado ? Colors.green.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                    child: Icon(
                      completado ? Icons.check : Icons.directions_car,
                      color: completado ? Colors.greenAccent : Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ruta.clienteNombre,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Orden: #${index + 1}',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: completado ? Colors.greenAccent.withOpacity(0.12) : Colors.orangeAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ruta.estadoVisita,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: completado ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.white.withOpacity(0.4)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ruta.direccion,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _verMapaSimulado(ruta, index),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Ver en Mapa', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: completado ? Colors.grey : const Color(0xFF2563EB),
                      ),
                      onPressed: completado ? null : () => _iniciarVerificacionVisita(ruta, index),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Completar', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Pintor personalizado para simular una ruta GPS con estilo moderno
class _MapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(20, 160)
      ..quadraticBezierTo(50, 120, 80, 130)
      ..lineTo(110, 80)
      ..quadraticBezierTo(140, 50, 100, 100);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = Colors.blue;
    canvas.drawCircle(const Offset(20, 160), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
