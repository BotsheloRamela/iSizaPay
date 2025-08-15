// lib/features/blockchain/data/solscan/solscan_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class SolscanService {
  final String baseUrl = 'https://public-api.solscan.io';

  Future<Map<String, dynamic>> getTransaction(String txSignature) async {
    final url = Uri.parse('$baseUrl/v1/transaction?tx=$txSignature');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to fetch transaction');
    }
  }

  Future<List<dynamic>> getAccountTokens(String walletAddress) async {
    final url = Uri.parse('$baseUrl/account/tokens?address=$walletAddress');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to fetch tokens');
    }
  }
}
