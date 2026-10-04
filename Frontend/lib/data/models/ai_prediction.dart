class AIPrediction {
  final String deviceId;
  final String location;
  final double currentPm25;
  final double predictedPm25;
  final String predictionHorizon; // e.g. "1 hour"
  final String trend; // "RISING", "FALLING", "STABLE"
  final String riskLevel; // "LOW", "MODERATE", "HIGH", "CRITICAL"
  final String recommendedAction;
  final String modelVersion;
  final String algorithm;

  AIPrediction({
    required this.deviceId,
    required this.location,
    required this.currentPm25,
    required this.predictedPm25,
    required this.predictionHorizon,
    required this.trend,
    required this.riskLevel,
    required this.recommendedAction,
    required this.modelVersion,
    required this.algorithm,
  });

  factory AIPrediction.fromJson(Map<String, dynamic> json) {
    return AIPrediction(
      deviceId: json['device_id'] ?? json['deviceId'] ?? 'ESP32_AIR_01',
      location: json['location'] ?? 'Junction Central Corridor',
      currentPm25: (json['current_pm25'] as num?)?.toDouble() ??
          (json['pm25'] as num?)?.toDouble() ??
          86.4,
      predictedPm25: (json['predicted_pm25'] as num?)?.toDouble() ??
          (json['predictedPm25'] as num?)?.toDouble() ??
          112.5,
      predictionHorizon: json['prediction_horizon'] ?? '1 hour',
      trend: json['trend'] ?? 'RISING',
      riskLevel: json['risk_level'] ?? json['riskLevel'] ?? 'HIGH',
      recommendedAction: json['recommended_action'] ??
          json['recommendedAction'] ??
          'Extend green traffic cycles & deploy misting cannons.',
      modelVersion: json['model_version'] ?? 'v1.0-uci-trained',
      algorithm: json['algorithm'] ?? 'Ridge / Time-Series Ensemble',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'location': location,
      'currentPm25': currentPm25,
      'predictedPm25': predictedPm25,
      'predictionHorizon': predictionHorizon,
      'trend': trend,
      'riskLevel': riskLevel,
      'recommendedAction': recommendedAction,
      'modelVersion': modelVersion,
      'algorithm': algorithm,
    };
  }
}
