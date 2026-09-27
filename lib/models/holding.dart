import 'package:hive/hive.dart';

enum AssetType { equity, mutualFund, fixedDeposit, gold, ppf, bond, other }

class Holding extends HiveObject {
  Holding({
    required this.id,
    required this.name,
    required this.assetType,
    required this.quantity,
    required this.avgBuyPrice,
    this.currentPrice = 0.0,
    this.symbol,
    this.isin,
    this.folioNumber,
    this.amcName,
    this.maturityDate,
    this.lastUpdated,
  });

  String id;
  String name;
  AssetType assetType;
  double quantity;
  double avgBuyPrice;
  double currentPrice;
  String? symbol;
  String? isin;
  String? folioNumber;
  String? amcName;
  DateTime? maturityDate;
  DateTime? lastUpdated;

  double get investedValue => quantity * avgBuyPrice;
  double get currentValue => quantity * currentPrice;
  double get unrealizedGain => currentValue - investedValue;
  double get returnPercent =>
      investedValue > 0 ? ((currentValue - investedValue) / investedValue) * 100 : 0;

  Holding copyWith({
    String? id,
    String? name,
    AssetType? assetType,
    double? quantity,
    double? avgBuyPrice,
    double? currentPrice,
    String? symbol,
    String? isin,
    String? folioNumber,
    String? amcName,
    DateTime? maturityDate,
    DateTime? lastUpdated,
  }) {
    return Holding(
      id: id ?? this.id,
      name: name ?? this.name,
      assetType: assetType ?? this.assetType,
      quantity: quantity ?? this.quantity,
      avgBuyPrice: avgBuyPrice ?? this.avgBuyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      symbol: symbol ?? this.symbol,
      isin: isin ?? this.isin,
      folioNumber: folioNumber ?? this.folioNumber,
      amcName: amcName ?? this.amcName,
      maturityDate: maturityDate ?? this.maturityDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class AssetTypeAdapter extends TypeAdapter<AssetType> {
  @override
  int get typeId => 5;

  @override
  AssetType read(BinaryReader reader) {
    final index = reader.readByte();
    return AssetType.values[index];
  }

  @override
  void write(BinaryWriter writer, AssetType obj) {
    writer.writeByte(obj.index);
  }
}

class HoldingAdapter extends TypeAdapter<Holding> {
  @override
  int get typeId => 6;

  @override
  Holding read(BinaryReader reader) {
    final fields = reader.readMap();
    return Holding(
      id: fields['id'] as String,
      name: fields['name'] as String,
      assetType: AssetType.values[(fields['assetType'] as num).toInt()],
      quantity: (fields['quantity'] as num).toDouble(),
      avgBuyPrice: (fields['avgBuyPrice'] as num).toDouble(),
      currentPrice: (fields['currentPrice'] as num?)?.toDouble() ?? 0.0,
      symbol: fields['symbol'] as String?,
      isin: fields['isin'] as String?,
      folioNumber: fields['folioNumber'] as String?,
      amcName: fields['amcName'] as String?,
      maturityDate: fields['maturityDate'] == null
          ? null
          : DateTime.parse(fields['maturityDate'] as String),
      lastUpdated: fields['lastUpdated'] == null
          ? null
          : DateTime.parse(fields['lastUpdated'] as String),
    );
  }

  @override
  void write(BinaryWriter writer, Holding obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'assetType': obj.assetType.index,
      'quantity': obj.quantity,
      'avgBuyPrice': obj.avgBuyPrice,
      'currentPrice': obj.currentPrice,
      'symbol': obj.symbol,
      'isin': obj.isin,
      'folioNumber': obj.folioNumber,
      'amcName': obj.amcName,
      'maturityDate': obj.maturityDate?.toIso8601String(),
      'lastUpdated': obj.lastUpdated?.toIso8601String(),
    });
  }
}
