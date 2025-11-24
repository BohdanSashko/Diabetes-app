


class UserProfile {
  final String id;
  final String? diabetesType;
  final bool usesInsulin;
  final double targetLow;
  final double targetHigh;
  final String? name;

  UserProfile({
    required this.id,
    this.name,
    this.diabetesType,
    this.usesInsulin = false,
    this.targetLow = 4.0,
    this.targetHigh = 8.0,
  });

  /// Конструктор з JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String?,
      diabetesType: json['diabetes_type'] as String?,
      usesInsulin: json['uses_insulin'] ?? false,
      targetLow: (json['target_low'] ?? 4.0).toDouble(),
      targetHigh: (json['target_high'] ?? 8.0).toDouble(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'diabetes_type': diabetesType,
      'uses_insulin': usesInsulin,
      'target_low': targetLow,
      'target_high': targetHigh,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}