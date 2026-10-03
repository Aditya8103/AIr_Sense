class SensorData {
  final double co2;
  final double smoke;
  final double temperature;
  final double humidity;
  final int aqi;
  final double pm25;
  final double pm10;
  final String? aqiStatus;
  final String? deviceId;
  final String? zoneName;
  final DateTime? recordedAt;

  SensorData({
    required this.co2,
    required this.smoke,
    required this.temperature,
    required this.humidity,
    required this.aqi,
    this.pm25 = 45.0,
    this.pm10 = 85.0,
    this.aqiStatus,
    this.deviceId,
    this.zoneName,
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
      pm25: (json['pm25'] is num)
          ? (json['pm25'] as num).toDouble()
          : ((json['smoke'] is num) ? ((json['smoke'] as num).toDouble() * 35.0).clamp(12.0, 350.0) : 45.0),
      pm10: (json['pm10'] is num)
          ? (json['pm10'] as num).toDouble()
          : ((json['smoke'] is num) ? ((json['smoke'] as num).toDouble() * 65.0).clamp(25.0, 480.0) : 85.0),
      aqiStatus: json['aqiStatus'] as String?,
      deviceId: json['deviceId'] as String?,
      zoneName: json['zoneName'] as String?,
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
      'pm25': pm25,
      'pm10': pm10,
      'aqiStatus': aqiStatus,
      'deviceId': deviceId,
      'zoneName': zoneName,
      'recordedAt': recordedAt?.toIso8601String(),
    };
  }
}