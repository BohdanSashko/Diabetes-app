class MealRecord {
  final int id;
  final String mealType;
  final String food;
  final double carbs;
  final double servings;
  final double totalCarbs;
  final String? note;
  final DateTime time;

  MealRecord({
    required this.id,
    required this.mealType,
    required this.food,
    required this.carbs,
    required this.servings,
    required this.totalCarbs,
    this.note,
    required this.time,
  });

  factory MealRecord.fromJson(Map<String, dynamic> json) {
    return MealRecord(
      id: json['id'],
      mealType: json['meal_type'],
      food: json['food'],
      carbs: (json['carbs'] as num).toDouble(),
      servings: (json['servings'] as num).toDouble(),
      totalCarbs: (json['total_carbs'] as num).toDouble(),
      note: json['note'],
      time: DateTime.parse(json['time']),
    );
  }
}
