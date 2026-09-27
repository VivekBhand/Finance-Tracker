import 'package:hive/hive.dart';

class Goal extends HiveObject {
  Goal({
    required this.id,
    required this.title,
    this.targetAmount,
    this.currentAmount = 0.0,
    this.deadline,
    this.iconPath,
  });

  String id;
  String title;
  double? targetAmount;
  double currentAmount;
  DateTime? deadline;
  String? iconPath;

  Goal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? iconPath,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  double get progressPercent {
    if (targetAmount == null || targetAmount! <= 0) return 0;
    return (currentAmount / targetAmount!).clamp(0.0, 1.0);
  }

  bool get isCompleted => targetAmount != null && currentAmount >= targetAmount!;
}

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  int get typeId => 1;

  @override
  Goal read(BinaryReader reader) {
    final fields = reader.readMap();
    return Goal(
      id: fields['id'] as String,
      title: fields['title'] as String,
      targetAmount: fields['targetAmount'] == null ? null : (fields['targetAmount'] as num).toDouble(),
      currentAmount: (fields['currentAmount'] as num? ?? 0).toDouble(),
      deadline: fields['deadline'] == null ? null : DateTime.parse(fields['deadline'] as String),
      iconPath: fields['iconPath'] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer.writeMap({
      'id': obj.id,
      'title': obj.title,
      'targetAmount': obj.targetAmount,
      'currentAmount': obj.currentAmount,
      'deadline': obj.deadline?.toIso8601String(),
      'iconPath': obj.iconPath,
    });
  }
}
