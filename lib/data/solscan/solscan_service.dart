
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/utils/logger.dart';

class SolscanService {
  final String baseUrl = 'https://public-api.solscan.io';

  Future<Map<String, dynamic>> getTransaction(String txSignature) async {
    try {
      final url = Uri.parse('$baseUrl/v1/transaction?tx=$txSignature');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to fetch transaction');
      }
    } catch (e) {
      logger.e('Error fetching transaction: $e');
      throw Exception('Error fetching transaction: $e');
    }
  }

  Future<List<dynamic>> getAccountTokens(String walletAddress) async {
    try {
      final url = Uri.parse('$baseUrl/account/tokens?address=$walletAddress');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to fetch tokens');
      }
    } catch (e) {
      logger.e('Error fetching account tokens: $e');
      throw Exception('Error fetching account tokens: $e');
    }
  }
}
