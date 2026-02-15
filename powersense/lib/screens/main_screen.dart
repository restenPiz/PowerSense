import 'package:flutter/material.dart';
import 'package:powersense/services/api_service.dart';
import 'auth/login_screen.dart';
import 'main/home_screen.dart';
import 'main/analytics_screen.dart';
import 'main/recharge_screen.dart';
import 'main/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? contadorData;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalyticsScreen(),
    const RechargeScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadContadorData();
  }

  Future<void> _loadContadorData() async {
    final data = await ApiService.getContadorData();
    if (mounted) {
      setState(() {
        contadorData = data;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    // Mostrar diálogo de confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Fazer logout
      await ApiService.logout();

      // Navegar para tela de login
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text(
          'PowerSense',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Text(
              TimeOfDay.now().format(context),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        actions: [
          // Botão de logout
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            onPressed: _handleLogout,
            tooltip: 'Sair',
          ),
          // Bateria
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                width: 20,
                height: 14,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.5),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0066CC),
          unselectedItemColor: Colors.grey.shade500,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Análise',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_outlined),
              activeIcon: Icon(Icons.credit_card),
              label: 'Recarga',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Config',
            ),
          ],
        ),
      ),
    );
  }
}
