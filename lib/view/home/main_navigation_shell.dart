import 'package:flutter/material.dart';
import 'cartera_diaria_screen.dart';
import '../ruta/ruta_visitas_screen.dart';
import '../transmision/transmision_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CarteraDiariaScreen(),
    RutaVisitasScreen(),
    TransmisionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F172A),
          selectedItemColor: const Color(0xFF60A5FA),
          unselectedItemColor: Colors.white.withOpacity(0.4),
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Cartera',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Ruta',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sync_outlined),
              activeIcon: Icon(Icons.sync),
              label: 'Transmisión',
            ),
          ],
        ),
      ),
    );
  }
}
