import 'package:flutter/material.dart';
import 'dart:async';

import 'package:powersense/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dados do dashboard
  double balance = 0.0;
  double currentPower = 0.0;
  int daysRemaining = 0;
  double consumoHoje = 0.0;

  // Estados de loading
  bool isLoading = true;
  String? errorMessage;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    // Refresh automático a cada 30 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Carregar dados do dashboard da API
  Future<void> _loadDashboardData() async {
    try {
      final result = await ApiService.getDashboard();
      print('DEBUG Home Dashboard result: $result');

      if (result['success'] && mounted) {
        final data = result['data'];
        print('DEBUG Home data: $data');

        final kwhBalance = _parseDouble(data['saldo']['kwh']);
        final consumoHojeValue = _parseDouble(data['consumo']['hoje']);

        print(
          'DEBUG kwhBalance: $kwhBalance, consumoHojeValue: $consumoHojeValue',
        );

        setState(() {
          balance = kwhBalance;
          daysRemaining = data['saldo']['dias_estimados'] ?? 0;
          consumoHoje = consumoHojeValue;

          // Calcular potência atual aproximada (simulado por agora)
          // Em produção, isso viria de um medidor em tempo real
          currentPower = consumoHoje / 24; // kW médio do dia

          isLoading = false;
          errorMessage = null;
        });
      } else {
        final errorMsg = result['message'] ?? 'Erro ao carregar dados';
        print('DEBUG Home error: $errorMsg');
        setState(() {
          isLoading = false;
          errorMessage = errorMsg;
        });
      }
    } catch (e) {
      print('DEBUG Home exception: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Erro de conexão: ${e.toString()}';
        });
      }
    }
  }

  /// Pull to refresh
  Future<void> _handleRefresh() async {
    await _loadDashboardData();
  }

  /// Converter valor para double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('DEBUG: Failed to parse double from "$value": $e');
        return 0.0;
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // Tela de loading
    if (isLoading) {
      return Container(
        color: Colors.grey.shade50,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Tela de erro
    if (errorMessage != null) {
      return Container(
        color: Colors.grey.shade50,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar dados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadDashboardData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tela principal com dados
    return Container(
      color: Colors.grey.shade50,
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert Banner
              if (balance < 200)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border(
                      left: BorderSide(color: Colors.orange.shade500, width: 4),
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade500,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo baixo!',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            Text(
                              'Recomendamos recarregar em breve',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Main Balance Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066CC), Color(0xFF004C99)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.battery_charging_full,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Saldo Disponível',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: Colors.white.withOpacity(0.75),
                            size: 20,
                          ),
                          onPressed: _loadDashboardData,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${balance.toStringAsFixed(1)} kWh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white.withOpacity(0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Estimativa: $daysRemaining dias restantes',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Consumo Hoje',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${consumoHoje.toStringAsFixed(1)} kWh',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bolt,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.credit_card,
                      title: 'Inserir Código',
                      subtitle: 'Adicionar recarga',
                      color: const Color(0xFF0066CC),
                      onTap: () {
                        // Mudar para tab de recarga (index 2)
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.bar_chart,
                      title: 'Ver Análises',
                      subtitle: 'Gráficos',
                      color: Colors.grey.shade600,
                      outlined: true,
                      onTap: () {
                        // Mudar para tab de analytics (index 1)
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Energy Saving Tips
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
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Dicas de Economia',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTip(
                      '💡',
                      'Desligue aparelhos em standby - economize até 15% por mês',
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      '❄️',
                      'Seu ar condicionado consome 45% da sua energia',
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      '⏰',
                      'Pico de consumo às 19h - considere usar aparelhos depois das 22h',
                    ),
                  ],
                ),
              ),

              // Última atualização
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Última atualização: ${TimeOfDay.now().format(context)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool outlined = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: outlined ? Colors.white : Colors.white,
          border: Border.all(
            color: outlined ? Colors.grey.shade200 : color,
            width: outlined ? 1 : 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
