class SensorData {
  final double co2;
  final double smoke;
  final double temperature;
  final double humidity;
  final int aqi;
  final String? aqiStatus;
  final String? deviceId;
  final DateTime? recordedAt;

  SensorData({
    required this.co2,
    required this.smoke,
    required this.temperature,
    required this.humidity,
    required this.aqi,
    this.aqiStatus,
    this.deviceId,
    this.recordedAt,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      co2: (json['co2'] is num) ? (json['co2'] as num).toDouble() : 0.0,
      smoke: (json['smoke'] is num) ? (json['smoke'] as num).toDouble() : 0.0,
      temperature: (json['temperature'] is num)
          ? (json['temperature'] as num).toDouble()
          : 0.0,
      humidity: (json['humidity'] is num)
          ? (json['humidity'] as num).toDouble()
          : 0.0,
      aqi: (json['aqi'] is num) ? (json['aqi'] as num).toInt() : 0,
      aqiStatus: json['aqiStatus'] as String?,
      deviceId: json['deviceId'] as String?,
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'co2': co2,
      'smoke': smoke,
      'temperature': temperature,
      'humidity': humidity,
      'aqi': aqi,
      'aqiStatus': aqiStatus,
      'deviceId': deviceId,
      'recordedAt': recordedAt?.toIso8601String(),
    };
  }
}