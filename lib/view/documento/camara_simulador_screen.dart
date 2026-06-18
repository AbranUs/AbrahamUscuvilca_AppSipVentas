import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class CamaraSimuladorScreen extends StatefulWidget {
  final String tipoDocumento;
  final String clienteId;
  final String clienteNombre;

  const CamaraSimuladorScreen({
    super.key,
    required this.tipoDocumento,
    required this.clienteId,
    required this.clienteNombre,
  });

  @override
  State<CamaraSimuladorScreen> createState() => _CamaraSimuladorScreenState();
}

class _CamaraSimuladorScreenState extends State<CamaraSimuladorScreen> {
  bool _fotoCapturada = false;
  bool _analizandoNitidez = false;
  bool _guardando = false;

  // Parámetros de calidad simulados (HU-21)
  double _enfoque = 0.94;
  double _brillo = 0.82;
  double _nitidez = 0.91;
  String _resolucion = '1920x1080 px';
  String _pesoComprimido = '145 KB';

  // Configuración de visor
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _capturarFoto() async {
    setState(() {
      _analizandoNitidez = true;
    });

    // Simular escaneo y análisis automático de nitidez
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _fotoCapturada = true;
      _analizandoNitidez = false;
    });
  }

  Future<void> _eliminarFoto() async {
    // Confirmación obligatoria antes de eliminar (HU-22)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Descartar Captura', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          '¿Estás seguro de que deseas descartar esta fotografía del documento? Deberás capturarla nuevamente.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _fotoCapturada = false;
        _transformationController.value = Matrix4.identity(); // reset zoom
      });
    }
  }

  Future<void> _guardarDocumento() async {
    setState(() => _guardando = true);

    try {
      final auth = AuthService();
      final oficial = await auth.obtenerOficialActual();
      if (oficial == null) throw Exception('No hay sesión de oficial.');

      final nombreArchivo = 'doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '${oficial.id}/${widget.clienteId}/${widget.tipoDocumento}/$nombreArchivo';

      // Insertar metadatos en base de datos Supabase
      await Supabase.instance.client.from('documentos').insert({
        'cliente_id': widget.clienteId,
        'oficial_id': oficial.id,
        'tipo_documento': widget.tipoDocumento,
        'nombre_archivo': nombreArchivo,
        'storage_path': storagePath,
        'estado_subida': 'SUBIDO',
        'sync_status': 'SINCRONIZADO',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Documento ${widget.tipoDocumento} subido e integrado al expediente.')),
        );
        Navigator.pop(context, true); // Retornar true indicando éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar documento: $e')),
        );
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Capturar: ${widget.tipoDocumento.replaceAll('_', ' ')}'),
      ),
      body: Stack(
        children: [
          if (!_fotoCapturada) ...[
            // VISTA CÁMARA ACTIVA MOCK
            Positioned.fill(child: _buildCameraViewport()),
            // CUADRÍCULA DE ENCUADRE Y CORNERS
            Positioned.fill(child: _buildFrameOverlay()),
            // CONTROLES DE CAPTURA
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildCameraCaptureControls(),
            ),
          ] else ...[
            // VISOR CON ZOOM DE DOCUMENTO CAPTURADO (HU-22)
            Positioned.fill(child: _buildDocumentVisor()),
            // METADATOS DE NITIDEZ / CALIDAD (HU-21)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: _buildQualityOverlayCard(),
            ),
            // CONTROLES DE CONFIRMACIÓN
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _buildVisorConfirmationControls(),
            ),
          ],
          if (_analizandoNitidez || _guardando)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.greenAccent),
                    const SizedBox(height: 16),
                    Text(
                      _analizandoNitidez ? 'Analizando nitidez de imagen...' : 'Procesando y guardando documento...',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraViewport() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt, color: Colors.white10, size: 64),
            SizedBox(height: 12),
            Text(
              'SIMULADOR DE CÁMARA ACTIVA',
              style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrameOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        children: [
          const Text(
            'ENFOQUE AUTOMÁTICO ACTIVO',
            style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            'Cliente: ${widget.clienteNombre}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const Spacer(),
          // Caja de guía
          AspectRatio(
            aspectRatio: 1.586, // Proporciones de un DNI o tarjeta plástica
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2),
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent,
              ),
              child: Stack(
                children: [
                  // Línea de escaneo láser mock
                  _ScanLaserEffect(),
                  // Guías de cuadrícula opcionales
                  _buildGridLines(),
                ],
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Coloque el documento plano y evite reflejos de luz directa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLines() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Divider(color: Colors.white24, height: 1),
        const Divider(color: Colors.white24, height: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(width: 1, height: 120, color: Colors.white24),
            Container(width: 1, height: 120, color: Colors.white24),
          ],
        ),
      ],
    );
  }

  Widget _buildCameraCaptureControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.flash_off, color: Colors.white, size: 24),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Flash desactivado')),
            );
          },
        ),
        GestureDetector(
          onTap: _capturarFoto,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.grid_on, color: Colors.greenAccent, size: 24),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildDocumentVisor() {
    // Generar un fondo visual simulado del documento
    final String label = widget.tipoDocumento.replaceAll('_', ' ');

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 4.0, // Permite zoom táctil de alta definición (HU-22)
      child: Center(
        child: AspectRatio(
          aspectRatio: 1.586,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white54, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DOCUMENTO OFICIAL',
                          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          label,
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ],
                    ),
                    const Icon(Icons.security, color: Colors.blueAccent, size: 24),
                  ],
                ),
                Center(
                  child: Column(
                    children: [
                      Text(
                        widget.clienteNombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'DNI: ********  |  Perú',
                        style: TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FOTO REGISTRADA CON ÉXITO',
                      style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'REGISTRO OFICIAL',
                      style: TextStyle(color: Colors.black38, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualityOverlayCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xCC1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ANÁLISIS DE NITIDEZ DE IMAGEN',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enfoque: ${(_enfoque * 100).toInt()}%  |  Brillo: ${(_brillo * 100).toInt()}%  |  Resolución: $_resolucion',
                  style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                ),
                Text(
                  'Comprimido para sincronización rápida offline: $_pesoComprimido',
                  style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisorConfirmationControls() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.15),
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _eliminarFoto,
            icon: const Icon(Icons.delete),
            label: const Text('Eliminar Foto', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _guardarDocumento,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar y Subir', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _ScanLaserEffect extends StatefulWidget {
  @override
  State<_ScanLaserEffect> createState() => _ScanLaserEffectState();
}

class _ScanLaserEffectState extends State<_ScanLaserEffect> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Align(
          alignment: Alignment(0, (_anim.value * 2) - 1),
          child: Container(
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.8),
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
