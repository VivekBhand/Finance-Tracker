import 'package:hive/hive.dart';

enum TransactionType {
  saving,
  setback,
}

class Transaction extends HiveObject {
  Transaction({
    required this.id,
    this.goalId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String id;
  String? goalId;
  double amount;
  TransactionType type;
  String categoryId;
  String? note;
  DateTime timestamp;

  Transaction copyWith({
    String? id,
    String? goalId,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? note,
    DateTime? timestamp,
  }) {
    return Transaction(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  double get signedAmount {
    if (type == TransactionType.saving) return amount;
    return -amount;
  }
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  int get typeId => 2;

  @override
  TransactionType read(BinaryReader reader) {
    final index = reader.readByte();
    return TransactionType.values[index];
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    writer.writeByte(obj.index);
  }
}

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  int get typeId => 3;

  @override
  Transaction read(BinaryReader reader) {
    final fields = reader.readMap();
    return Transaction(
      id: fields['id'] as String,
      goalId: fields['goalId'] as String?,
      amount: (fields['amount'] as num).toDouble(),
      type: TransactionType.values[(fields['type'] as num).toInt()],
      categoryId: fields['categoryId'] as String,
      note: fields['note'] as String?,
      timestamp: fields['timestamp'] == null ? null : DateTime.parse(fields['timestamp'] as String),
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer.writeMap({
      'id': obj.id,
      'goalId': obj.goalId,
      'amount': obj.amount,
      'type': obj.type.index,
      'categoryId': obj.categoryId,
      'note': obj.note,
      'timestamp': obj.timestamp.toIso8601String(),
    });
  }
}
