import 'package:flutter/material.dart';
import 'dart:async' as dart_async;
import '../../navigation/app_routes.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';

class LoginOficialScreen extends StatefulWidget {
  const LoginOficialScreen({super.key});

  @override
  State<LoginOficialScreen> createState() => _LoginOficialScreenState();
}

class _LoginOficialScreenState extends State<LoginOficialScreen> {
  final AuthOficialViewModel _viewModel = AuthOficialViewModel();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _ocultarPassword = true;

  int _intentosFallidos = 0;
  bool _bloqueado = false;
  int _segundosRestantes = 0;
  dart_async.Timer? _timerBloqueo;

  @override
  void dispose() {
    _codigoController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    _timerBloqueo?.cancel();
    super.dispose();
  }

  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final restantes = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${restantes.toString().padLeft(2, '0')}';
  }

  void _iniciarTimerBloqueo() {
    setState(() {
      _bloqueado = true;
      _segundosRestantes = 1800; // 30 minutos
    });
    _timerBloqueo = dart_async.Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_segundosRestantes <= 1) {
        timer.cancel();
        setState(() {
          _bloqueado = false;
          _segundosRestantes = 0;
          _intentosFallidos = 0;
        });
      } else {
        setState(() {
          _segundosRestantes--;
        });
      }
    });
  }

  Future<void> _iniciarSesion() async {
    if (_bloqueado) return;
    FocusScope.of(context).unfocus();

    if (_codigoController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _mostrarSnackBar('Ingrese código de oficial y contraseña.');
      return;
    }

    final ok = await _viewModel.login(
      codigoEmpleado: _codigoController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      _intentosFallidos = 0;
      Navigator.pushReplacementNamed(context, AppRoutes.homeShell);
    } else {
      setState(() {
        _intentosFallidos++;
      });
      if (_intentosFallidos >= 5) {
        _iniciarTimerBloqueo();
        _mostrarSnackBar('Demasiados intentos fallidos. Bloqueado por 30 minutos.');
      } else {
        _mostrarSnackBar('${_viewModel.errorMessage ?? 'No se pudo iniciar sesión.'} (Intento $_intentosFallidos/5)');
      }
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0B1735),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildLoginCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.network(
              'https://media.licdn.com/dms/image/v2/D4E0BAQFTga6lGOfkYA/company-logo_200_200/B4EZ0wD_QyHAAM-/0/1774627845546/sip_per_logo?e=2147483647&v=beta&t=Kk9xx0-8uI_FqIh4yeZWcBgLI_WEsZFjPPAf2dwlRG4',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Fuerza de Ventas - SIP',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Acceso para oficiales de crédito',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.65)),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Iniciar sesión',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codigoController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Código de oficial',
              hintText: 'Ejemplo: OFI001',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _ocultarPassword,
            onSubmitted: (_) => _iniciarSesion(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _ocultarPassword = !_ocultarPassword;
                  });
                },
                icon: Icon(
                  _ocultarPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: (_viewModel.isLoading || _bloqueado) ? null : _iniciarSesion,
            child: _viewModel.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(_bloqueado ? 'Bloqueado (${_formatearTiempo(_segundosRestantes)})' : 'Ingresar'),
          ),
          const SizedBox(height: 14),
          Text(
            'La autenticación se realiza con Supabase Auth y la tabla oficiales.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.48),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
