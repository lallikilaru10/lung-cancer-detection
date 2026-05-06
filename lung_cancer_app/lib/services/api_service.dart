import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class PredictionResult {
  final String predictedClass;
  final String displayName;
  final double confidence;
  final String severity;
  final String description;
  final List<ClassProbability> allProbabilities;
  final bool isConfident;
  final String? warning;

  PredictionResult({
    required this.predictedClass,
    required this.displayName,
    required this.confidence,
    required this.severity,
    required this.description,
    required this.allProbabilities,
    required this.isConfident,
    this.warning,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      predictedClass: json['predicted_class'] ?? '',
      displayName: json['display_name'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 'none',
      description: json['description'] ?? '',
      allProbabilities: (json['all_probabilities'] as List<dynamic>?)
              ?.map((e) => ClassProbability.fromJson(e))
              .toList() ??
          [],
      isConfident: json['is_confident'] ?? false,
      warning: json['warning'],
    );
  }
}

class ClassProbability {
  final String className;
  final String displayName;
  final double probability;
  final String severity;

  ClassProbability({
    required this.className,
    required this.displayName,
    required this.probability,
    required this.severity,
  });

  factory ClassProbability.fromJson(Map<String, dynamic> json) {
    return ClassProbability(
      className: json['class'] ?? '',
      displayName: json['display_name'] ?? '',
      probability: (json['probability'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 'none',
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static Future<PredictionResult> predict(
      Uint8List imageBytes, String fileName) async {
    final uri = Uri.parse('$baseUrl/predict');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return PredictionResult.fromJson(json);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to get prediction');
    }
  }

  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
