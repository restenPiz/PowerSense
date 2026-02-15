import 'package:flutter/material.dart';
import 'package:powersense/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _lowBalanceAlert = true;
  bool _highConsumptionAlert = true;
  bool _savingTips = true;

  Map<String, dynamic>? contadorData;

  @override
  void initState() {
    super.initState();
    _loadContadorData();
  }

  Future<void> _loadContadorData() async {
    final data = await ApiService.me();
    if (mounted) {
      setState(() {
        contadorData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(Icons.settings, color: const Color(0xFF0066CC), size: 28),
                SizedBox(width: 12),
                Text(
                  'Configurações',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3C3C3C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Account Information
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações da Conta',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    'Número do Contador',
                    contadorData?['nome_proprietario'] ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem('Nome do Titular', 'João Silva'),
                  const SizedBox(height: 12),
                  _buildInfoItem('Endereço', 'Av. Julius Nyerere, Maputo'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notifications
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notificações',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationToggle(
                    'Saldo Baixo',
                    'Avisar quando saldo < 100 kWh',
                    _lowBalanceAlert,
                    (value) {
                      setState(() {
                        _lowBalanceAlert = value;
                      });
                    },
                  ),
                  const Divider(height: 32),
                  _buildNotificationToggle(
                    'Consumo Alto',
                    'Avisar quando consumo anormal',
                    _highConsumptionAlert,
                    (value) {
                      setState(() {
                        _highConsumptionAlert = value;
                      });
                    },
                  ),
                  const Divider(height: 32),
                  _buildNotificationToggle(
                    'Dicas de Economia',
                    'Receber sugestões semanais',
                    _savingTips,
                    (value) {
                      setState(() {
                        _savingTips = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suporte',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildSupportButton(
                    'Central de Ajuda',
                    'Perguntas frequentes e guias',
                    Icons.help_outline,
                    () {},
                  ),
                  const SizedBox(height: 12),
                  _buildSupportButton(
                    'Contactar Suporte',
                    'Chat ao vivo • 24/7',
                    Icons.chat_bubble_outline,
                    () {},
                  ),
                  const SizedBox(height: 12),
                  _buildSupportButton(
                    'Reportar Problema',
                    'Feedback e bugs',
                    Icons.bug_report_outlined,
                    () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Info
            Center(
              child: Column(
                children: [
                  Text(
                    'PowerSense v1.0.0',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 PowerSense Moçambique',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF0066CC),
        ),
      ],
    );
  }

  Widget _buildSupportButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
