import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _codigoController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  /// Maneja el login
  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();

    if (_codigoController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _mostrarSnackBar('Ingrese código de oficial y contraseña.');
      return;
    }

    // Login usando código de empleado
    final ok = await _viewModel.login(
      codigoEmpleado: _codigoController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.cartera);
    } else {
      _mostrarSnackBar(
        _viewModel.errorMessage ?? 'No se pudo iniciar sesión.',
      );
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
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
          child: const Icon(
            Icons.account_balance,
            color: Color(0xFF60A5FA),
            size: 42,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'APP 2 — Fuerza de Ventas',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Acceso para oficiales de crédito',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.65),
          ),
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
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
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
            onPressed: _viewModel.isLoading ? null : _iniciarSesion,
            child: _viewModel.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                    ),
                  )
                : const Text('Ingresar'),
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