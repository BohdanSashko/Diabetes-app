class InsulinRecord {
  final int id;
  final double units;
  final String type; // rapid, basal
  final DateTime time;
  final String? note;

  InsulinRecord({
    required this.id,
    required this.units,
    required this.type,
    required this.time,
    this.note,
  });

  factory InsulinRecord.fromJson(Map<String, dynamic> json) {
    return InsulinRecord(
      id: json['id'],
      units: (json['units'] as num).toDouble(),
      type: json['type'],
      time: DateTime.parse(json['time']),
      note: json['note'],
    );
  }
}
