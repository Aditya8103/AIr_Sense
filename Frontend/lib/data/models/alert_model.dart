class AlertModel {
  final int? id;
  final String deviceId;
  final String alertType;
  final String message;
  final String severity;
  final bool isRead;
  final DateTime? createdAt;

  AlertModel({
    this.id,
    required this.deviceId,
    required this.alertType,
    required this.message,
    required this.severity,
    this.isRead = false,
    this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as int?,
      deviceId: json['deviceId'] ?? '',
      alertType: json['alertType'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'INFO',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
