class HotspotNode {
  final String deviceId;
  final String location;
  final double currentPm25;
  final double predictedPm25;
  final String riskLevel; // "LOW", "MODERATE", "HIGH", "CRITICAL"
  final String trend; // "RISING", "FALLING", "STABLE"
  final String recommendedAction;

  HotspotNode({
    required this.deviceId,
    required this.location,
    required this.currentPm25,
    required this.predictedPm25,
    required this.riskLevel,
    required this.trend,
    required this.recommendedAction,
  });

  bool get isCritical => riskLevel == 'CRITICAL' || riskLevel == 'HIGH';

  factory HotspotNode.fromJson(Map<String, dynamic> json) {
    return HotspotNode(
      deviceId: json['deviceId'] ?? json['device_id'] ?? 'ESP32_NODE_01',
      location: json['location'] ?? 'Urban Corridor',
      currentPm25: (json['currentPm25'] as num?)?.toDouble() ??
          (json['pm25'] as num?)?.toDouble() ??
          0.0,
      predictedPm25: (json['predictedPm25'] as num?)?.toDouble() ??
          (json['predicted_pm25'] as num?)?.toDouble() ??
          0.0,
      riskLevel: json['riskLevel'] ?? json['risk_level'] ?? 'MODERATE',
      trend: json['trend'] ?? 'STABLE',
      recommendedAction: json['recommendedAction'] ??
          json['recommended_action'] ??
          'Maintain normal telemetry monitoring',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'location': location,
      'currentPm25': currentPm25,
      'predictedPm25': predictedPm25,
      'riskLevel': riskLevel,
      'trend': trend,
      'recommendedAction': recommendedAction,
    };
  }
}
