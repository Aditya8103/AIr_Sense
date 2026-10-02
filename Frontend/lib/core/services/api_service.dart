import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/models/sensor_data.dart';
import '../../data/models/alert_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Determine host based on runtime platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    // Android Emulator routes localhost through 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }
    // Windows, macOS, Linux, iOS Simulator
    return 'http://localhost:8080/api';
  }

  String baseUrl = defaultBaseUrl;

  /// Fetch the latest single sensor reading
  Future<SensorData?> fetchLatestReading({String? deviceId}) async {
    try {
      final uri = Uri.parse('$baseUrl/sensors/latest').replace(
        queryParameters: deviceId != null ? {'deviceId': deviceId} : null,
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return SensorData.fromJson(body['data']);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching latest reading: $e');
    }
    return null;
  }

  /// Live periodic stream of sensor readings (mimics Firebase onValue.listen)
  Stream<SensorData> getSensorStream({
    String? deviceId,
    Duration interval = const Duration(seconds: 3),
  }) async* {
    while (true) {
      final data = await fetchLatestReading(deviceId: deviceId);
      if (data != null) {
        yield data;
      }
      await Future.delayed(interval);
    }
  }

  /// Fetch historical readings for analytics charts (1H, 24H, 7D, 30D)
  Future<List<SensorData>> fetchHistory({
    String? deviceId,
    String range = '24H',
  }) async {
    try {
      final queryParams = <String, String>{'range': range};
      if (deviceId != null) {
        queryParams['deviceId'] = deviceId;
      }

      final uri = Uri.parse('$baseUrl/sensors/history')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List)
              .map((item) => SensorData.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching sensor history: $e');
    }
    return [];
  }

  /// Fetch alerts list
  Future<List<AlertModel>> fetchAlerts({String? deviceId}) async {
    try {
      final uri = Uri.parse('$baseUrl/alerts').replace(
        queryParameters: deviceId != null ? {'deviceId': deviceId} : null,
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List)
              .map((item) => AlertModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching alerts: $e');
    }
    return [];
  }

  /// Mark alert as read
  Future<bool> markAlertAsRead(int alertId) async {
    try {
      final uri = Uri.parse('$baseUrl/alerts/$alertId/read');
      final response = await http.put(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Error marking alert as read: $e');
      return false;
    }
  }
}
