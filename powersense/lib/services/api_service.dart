import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // URL base da API Laravel
  // Para Android Emulator: use 10.0.2.2
  // Para iOS Simulator: use localhost
  // Para dispositivo físico: use o IP da máquina (ex: 192.168.1.100)
  static const String baseUrl = 'http://10.29.154.12:8000/api';

  // Headers padrão
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers com autenticação
  static Future<Map<String, String>> get authHeaders async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTENTICAÇÃO ====================

  /// Registrar novo contador
  static Future<Map<String, dynamic>> register({
    required String numeroContador,
    required String nomeProprietario,
    required String endereco,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: headers,
        body: jsonEncode({
          'numero_contador': numeroContador,
          'nome_proprietario': nomeProprietario,
          'endereco': endereco,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Salvar token
        await saveToken(data['data']['token']);
        // Salvar dados do contador
        await saveContadorData(data['data']['contador']);
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao registrar',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: ${e.toString()}'};
    }
  }

  /// Login (autenticar contador)
  static Future<Map<String, dynamic>> login({
    required String numeroContador,
    required String nomeProprietario,
    String? password,
  }) async {
    try {
      final body = {
        'numero_contador': numeroContador,
        'nome_proprietario': nomeProprietario,
      };

      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Salvar token
        await saveToken(data['data']['token']);
        // Salvar dados do contador
        await saveContadorData(data['data']['contador']);
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Credenciais inválidas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: ${e.toString()}'};
    }
  }

  /// Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await authHeaders,
      );

      if (response.statusCode == 200) {
        await clearAuthData();
        return {'success': true, 'message': 'Logout realizado com sucesso'};
      } else {
        return {'success': false, 'message': 'Erro ao fazer logout'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: ${e.toString()}'};
    }
  }

  /// Obter dados do contador autenticado
  static Future<Map<String, dynamic>> me() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: await authHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Erro ao obter dados'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: ${e.toString()}'};
    }
  }

  // ==================== DASHBOARD ====================

  /// Obter dashboard completo
  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: await authHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Erro ao carregar dashboard'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: ${e.toString()}'};
    }
  }

  /// Obter consumo semanal
  static Future<Map<String, dynamic>> getConsumoSemanal() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/consumo/semanal'),
        headers: await authHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Erro ao carregar consumo'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: ${e.toString()}'};
    }
  }

  // ==================== RECARGAS ====================

  /// Inserir código de recarga
  static Future<Map<String, dynamic>> insertRecarga(
    String codigoRecarga,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recarga'),
        headers: await authHeaders,
        body: jsonEncode({'codigo_recarga': codigoRecarga}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao processar recarga',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: ${e.toString()}'};
    }
  }

  /// Obter histórico de recargas
  static Future<Map<String, dynamic>> getRecargas({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recargas?page=$page'),
        headers: await authHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Erro ao carregar recargas'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: ${e.toString()}'};
    }
  }

  /// Obter detalhes de uma recarga específica
  static Future<Map<String, dynamic>> getRecarga(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recarga/$id'),
        headers: await authHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Erro ao carregar recarga'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: ${e.toString()}'};
    }
  }

  // ==================== ARMAZENAMENTO LOCAL ====================

  /// Salvar token JWT
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Obter token JWT
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Salvar dados do contador
  static Future<void> saveContadorData(Map<String, dynamic> contador) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('contador_data', jsonEncode(contador));
  }

  /// Obter dados do contador salvos
  static Future<Map<String, dynamic>?> getContadorData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('contador_data');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  /// Verificar se está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Limpar dados de autenticação
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('contador_data');
  }
}
