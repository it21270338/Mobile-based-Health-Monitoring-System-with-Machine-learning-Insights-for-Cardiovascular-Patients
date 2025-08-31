class PainLocation {
  final String bodyPart;
  final double severity;
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  PainLocation({
    required this.bodyPart,
    required this.severity,
    required this.x,
    required this.y,
    required this.z,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'bodyPart': bodyPart,
      'severity': severity,
      'x': x,
      'y': y,
      'z': z,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
