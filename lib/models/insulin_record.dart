class InsulinRecord {
  final int id;
  final double units;
  final String type;
  final String? note;
  final DateTime recorded_at;

  InsulinRecord({
    required this.id,
    required this.units,
    required this.type,
    this.note,
    required this.recorded_at,
  });

  factory InsulinRecord.fromJson(Map<String, dynamic> json) {
    return InsulinRecord(
      id: json['id'],
      units: (json['units'] as num).toDouble(),
      type: json['type'],
      note: json['note'],
      recorded_at: DateTime.parse(json['recorded_at']),
    );
  }
}
