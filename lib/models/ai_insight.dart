import 'package:hive/hive.dart';

enum InsightSeverity { info, suggestion, warning, critical }

class AiInsight extends HiveObject {
  AiInsight({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    this.relatedHoldingId,
    this.relatedGoalId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String id;
  String title;
  String body;
  InsightSeverity severity;
  String? relatedHoldingId;
  String? relatedGoalId;
  DateTime createdAt;
}

class InsightSeverityAdapter extends TypeAdapter<InsightSeverity> {
  @override
  int get typeId => 7;

  @override
  InsightSeverity read(BinaryReader reader) {
    final index = reader.readByte();
    return InsightSeverity.values[index];
  }

  @override
  void write(BinaryWriter writer, InsightSeverity obj) {
    writer.writeByte(obj.index);
  }
}

class AiInsightAdapter extends TypeAdapter<AiInsight> {
  @override
  int get typeId => 8;

  @override
  AiInsight read(BinaryReader reader) {
    final fields = reader.readMap();
    return AiInsight(
      id: fields['id'] as String,
      title: fields['title'] as String,
      body: fields['body'] as String,
      severity: InsightSeverity.values[(fields['severity'] as num).toInt()],
      relatedHoldingId: fields['relatedHoldingId'] as String?,
      relatedGoalId: fields['relatedGoalId'] as String?,
      createdAt: fields['createdAt'] == null
          ? null
          : DateTime.parse(fields['createdAt'] as String),
    );
  }

  @override
  void write(BinaryWriter writer, AiInsight obj) {
    writer.writeMap({
      'id': obj.id,
      'title': obj.title,
      'body': obj.body,
      'severity': obj.severity.index,
      'relatedHoldingId': obj.relatedHoldingId,
      'relatedGoalId': obj.relatedGoalId,
      'createdAt': obj.createdAt.toIso8601String(),
    });
  }
}
