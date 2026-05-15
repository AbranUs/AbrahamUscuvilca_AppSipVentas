import 'package:flutter/material.dart';
import '../../navigation/app_routes.dart';
import '../../ui/theme/app_theme.dart';
import '../../viewmodel/cartera_viewmodel.dart';

class CarteraDiariaScreen extends StatefulWidget {
  const CarteraDiariaScreen({super.key});

  @override
  State<CarteraDiariaScreen> createState() => _CarteraDiariaScreenState();
}

class _CarteraDiariaScreenState extends State<CarteraDiariaScreen> {
  final CarteraViewModel viewModel = CarteraViewModel();

  void cerrarSesion() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Color estadoColor(String estado) {
    if (estado == 'Visitado') {
      return Colors.green;
    }
    return AppTheme.sipBlue;
  }

  IconData gestionIcono(String tipoGestion) {
    if (tipoGestion == 'Cobranza') {
      return Icons.payments;
    } else if (tipoGestion == 'Renovación') {
      return Icons.refresh;
    }
    return Icons.person_add;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,

      appBar: AppBar(
        title: const Text('Cartera diaria'),
        actions: [
          IconButton(
            onPressed: cerrarSesion,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.sipDarkBlue,
                    AppTheme.sipBlue,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.sipDarkBlue,
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${viewModel.nombreOficial}',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Clientes asignados para visitar hoy',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _ResumenCard(
                    titulo: 'Total',
                    valor: viewModel.totalVisitas.toString(),
                    icono: Icons.groups,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ResumenCard(
                    titulo: 'Pendientes',
                    valor: viewModel.pendientes.toString(),
                    icono: Icons.schedule,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ResumenCard(
                    titulo: 'Visitados',
                    valor: viewModel.visitados.toString(),
                    icono: Icons.check_circle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            const Text(
              'Lista de clientes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: viewModel.clientes.length,
                itemBuilder: (context, index) {
                  final cliente = viewModel.clientes[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.sipBlue,
                        child: Icon(
                          gestionIcono(cliente.tipoGestion),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        cliente.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        cliente.tipoGestion,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: estadoColor(cliente.estado).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cliente.estado,
                          style: TextStyle(
                            color: estadoColor(cliente.estado),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;

  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 10,
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: AppTheme.sipBlue,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}