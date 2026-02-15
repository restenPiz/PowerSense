import 'package:flutter/material.dart';
import 'package:powersense/services/api_service.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _autoRecharge = false;
  String _selectedThreshold = '50 kWh';

  List<Map<String, dynamic>> recentRecharges = [];
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRechargesHistory();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Carregar histórico de recargas da API
  Future<void> _loadRechargesHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getRecargas();

      if (result['success'] && mounted) {
        final data = result['data'];

        // Parsing dos dados da API
        List<Map<String, dynamic>> parsedRecharges = [];

        if (data['data'] != null && data['data'] is List) {
          parsedRecharges = (data['data'] as List).map((item) {
            return {
              'id': item['id'],
              'date': _formatDate(item['data_recarga']),
              'amount': (item['valor_mt'] ?? 0).toDouble(),
              'kwh': (item['kwh'] ?? 0).toDouble(),
              'code': _maskCode(item['codigo_recarga'] ?? ''),
              'status': item['status'] ?? 'confirmado',
            };
          }).toList();
        }

        setState(() {
          recentRecharges = parsedRecharges;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = result['message'] ?? 'Erro ao carregar histórico';
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

  /// Processar código de recarga
  Future<void> _handleRecharge() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _showErrorDialog('Por favor, insira o código de recarga');
      return;
    }

    if (code.length != 20) {
      _showErrorDialog('O código deve ter 20 dígitos');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final result = await ApiService.insertRecarga(code);

      if (!mounted) return;

      if (result['success']) {
        final data = result['data'];
        _codeController.clear();

        // Recarregar histórico
        await _loadRechargesHistory();

        // Mostrar sucesso
        _showSuccessDialog(
          'Recarga realizada com sucesso!',
          'Novo saldo: ${data['novo_saldo']} kWh',
        );
      } else {
        _showErrorDialog(result['message'] ?? 'Erro ao processar recarga');
      }
    } catch (e) {
      _showErrorDialog('Erro de conexão: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  /// Formatar data para exibição
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Data indisponível';

    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Fev',
        'Mar',
        'Abr',
        'Mai',
        'Jun',
        'Jul',
        'Ago',
        'Set',
        'Out',
        'Nov',
        'Dez',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  /// Mascarar código de recarga
  String _maskCode(String code) {
    if (code.length < 5) return code;
    return '${code.substring(0, 5)}-XXXXX-XXXXX-XXXXX';
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await _loadRechargesHistory();
  }

  @override
  Widget build(BuildContext context) {
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
                    Icons.credit_card,
                    color: const Color(0xFF0066CC),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Recargas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3C3C3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Insert Code Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inserir Código de Recarga',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Digite o código de 20 dígitos que recebeu',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _codeController,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Courier',
                          letterSpacing: 2,
                          color: Colors.grey.shade800,
                        ),
                        maxLength: 20,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '12345678901234567890',
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _handleRecharge,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF059669),
                                  ),
                                ),
                              )
                            : const Text(
                                'Confirmar Recarga',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Recharges
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Histórico de Recargas',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: _loadRechargesHistory,
                          color: const Color(0xFF0066CC),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (recentRecharges.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Nenhuma recarga encontrada',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...recentRecharges.map((recharge) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${recharge['kwh']} kWh',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        recharge['date'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${recharge['amount']} MT',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '10 MT/kWh',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  recharge['code'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Auto-recharge Settings (Feature preview - não conectado ainda)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bolt,
                              color: const Color(0xFF0066CC),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Recarga Automática',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Switch(
                          value: _autoRecharge,
                          onChanged: (value) {
                            setState(() {
                              _autoRecharge = value;
                            });
                            // TODO: Salvar preferência na API
                          },
                          activeColor: const Color(0xFF0066CC),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Recarregue automaticamente quando o saldo atingir:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedThreshold,
                          isExpanded: true,
                          items: ['50 kWh', '100 kWh', '150 kWh', '200 kWh']
                              .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              })
                              .toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedThreshold = newValue;
                              });
                              // TODO: Salvar preferência na API
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Funcionalidade em breve',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
