import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prediction.dart';
import '../utils/app_config.dart';

class PredictionApiService {
  PredictionApiService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.backendBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<List<PredictionRecommendation>> fetchRecommendations({
    required DateTime targetDate,
  }) async {
    final uri = Uri.parse('$_baseUrl/predict');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'targetDate': targetDate.toIso8601String(),
        'bakery': 'Pastelería Charito’s',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Prediction API failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final recommendations =
        (decoded['recommendations'] ?? decoded['predictions']) as List<dynamic>?;

    if (recommendations == null) {
      throw const FormatException(
        'Prediction API response must include recommendations.',
      );
    }

    return recommendations
        .map(
          (item) => PredictionRecommendation.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}
