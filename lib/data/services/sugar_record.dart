class SugarRecord {
  final String id;
  final String userId;
  final double glucose;
  final DateTime measuredAt;
  final String? note;

  SugarRecord({
    required this.id,
    required this.userId,
    required this.glucose,
    required this.measuredAt,
    this.note,
  });

  factory SugarRecord.fromJson(Map<String, dynamic> json) {
    return SugarRecord(
      id: json['id'],
      userId: json['user_id'],
      glucose: (json['glucose'] as num).toDouble(),
      measuredAt: DateTime.parse(json['measured_at']),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'glucose': glucose,
    'measured_at': measuredAt.toIso8601String(),
    'note': note,
  };
}
