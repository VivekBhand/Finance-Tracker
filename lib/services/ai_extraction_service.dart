import 'dart:convert';

import 'package:dio/dio.dart';

/// Calls the public Hugging Face Space endpoint for AI parsing.
/// No API key required — the Space is publicly accessible.
class AiExtractionService {
  AiExtractionService({required this.endpointUrl});

  final String endpointUrl;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
  ));

  /// Check if the HF Space backend is reachable.
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.get('$endpointUrl/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Extract investment holdings from sanitized document text.
  Future<List<Map<String, dynamic>>> extractHoldings(String sanitizedText) async {
    final response = await _dio.post('$endpointUrl/parse', data: {
      'text': sanitizedText,
      'task': 'extract_holdings',
    });
    final parsed = jsonDecode(response.data['result'] as String);
    return List<Map<String, dynamic>>.from(parsed['holdings'] ?? []);
  }

  /// Extract bank transactions from sanitized statement text.
  Future<List<Map<String, dynamic>>> extractTransactions(String sanitizedText) async {
    final response = await _dio.post('$endpointUrl/parse', data: {
      'text': sanitizedText,
      'task': 'extract_transactions',
    });
    final parsed = jsonDecode(response.data['result'] as String);
    return List<Map<String, dynamic>>.from(parsed['transactions'] ?? []);
  }

  /// Generate AI-powered portfolio insights.
  Future<List<Map<String, dynamic>>> generateInsights({
    required String portfolioSummary,
    required String goalsSummary,
  }) async {
    final response = await _dio.post('$endpointUrl/parse', data: {
      'text': goalsSummary,
      'task': 'generate_insights',
      'context': portfolioSummary,
    });
    final parsed = jsonDecode(response.data['result'] as String);
    return List<Map<String, dynamic>>.from(parsed['insights'] ?? []);
  }
}
