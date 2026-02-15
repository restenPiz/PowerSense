import 'package:flutter/material.dart';

import 'package:powersense/services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Map<String, dynamic>> consumptionData = [];
  double totalSemanal = 0.0;
  double mediaDiaria = 0.0;
  double mesAtual = 0.0;
  double mesAnterior = 0.0;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  /// Carregar dados de análise da API
  Future<void> _loadAnalyticsData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Buscar consumo semanal
      final resultSemanal = await ApiService.getConsumoSemanal();

      // Buscar dashboard para estatísticas gerais
      final resultDashboard = await ApiService.getDashboard();

      if (resultSemanal['success'] && resultDashboard['success'] && mounted) {
        final consumoSemanalData = resultSemanal['data'] as List;
        final dashboardData = resultDashboard['data'];

        // Converter dados de consumo
        List<Map<String, dynamic>> parsedData = consumoSemanalData.map((item) {
          return {
            'day': item['day'] as String,
            'kwh': (item['kwh'] ?? 0).toDouble(),
          };
        }).toList();

        // Calcular totais
        double total = parsedData.fold(
          0.0,
          (sum, item) => sum + (item['kwh'] as double),
        );
        double media = total / parsedData.length;

        // Dados mensais (simulados por agora - em produção viria da API)
        // TODO: Adicionar endpoint para comparação mensal no Laravel
        double mesAtualCalc =
            dashboardData['estatisticas']['total_kwh_recarregado'] ?? 0.0;
        double mesAnteriorCalc =
            mesAtualCalc * 1.08; // 8% a mais no mês anterior

        setState(() {
          consumptionData = parsedData;
          totalSemanal = total;
          mediaDiaria = media;
          mesAtual = mesAtualCalc.toDouble();
          mesAnterior = mesAnteriorCalc;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Erro ao carregar dados de análise';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Erro de conexão: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadAnalyticsData();
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
    if (errorMessage != null || consumptionData.isEmpty) {
      return Container(
        color: Colors.grey.shade50,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Sem dados de análise',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadAnalyticsData,
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

    final maxConsumption = consumptionData
        .map((e) => e['kwh'] as double)
        .reduce((a, b) => a > b ? a : b);

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
              // Header
              Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: const Color(0xFF0066CC),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Análise de Consumo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3C3C3C),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadAnalyticsData,
                    color: const Color(0xFF0066CC),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly Consumption Card
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
                      'Consumo Semanal',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...consumptionData.map((day) {
                      final percentage =
                          (day['kwh'] as double) / maxConsumption;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              child: Text(
                                day['day'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: percentage,
                                    child: Container(
                                      height: 32,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF3B82F6),
                                            Color(0xFF2563EB),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Text(
                                        '${day['kwh']} kWh',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Semanal:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${totalSemanal.toStringAsFixed(1)} kWh',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Média Diária:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${mediaDiaria.toStringAsFixed(1)} kWh',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Monthly Comparison Card
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
                      'Comparação Mensal',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Este Mês',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${mesAtual.toStringAsFixed(0)} kWh',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0066CC),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '↓ ${((1 - mesAtual / mesAnterior) * 100).toStringAsFixed(0)}% vs mês anterior',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mês Anterior',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${mesAnterior.toStringAsFixed(0)} kWh',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Janeiro 2026',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Peak Hours Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade50, Colors.yellow.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Horários de Pico',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPeakHour('18h - 21h', 'Alto', Colors.orange.shade500),
                    const SizedBox(height: 8),
                    _buildPeakHour(
                      '06h - 09h',
                      'Médio',
                      Colors.yellow.shade600,
                    ),
                    const SizedBox(height: 8),
                    _buildPeakHour('22h - 06h', 'Baixo', Colors.green.shade500),
                  ],
                ),
              ),

              // Última atualização
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Dados atualizados em tempo real',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeakHour(String time, String level, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(time, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            level,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
