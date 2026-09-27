import 'package:hive/hive.dart';

import '../models/ai_insight.dart';
import '../models/holding.dart';

/// Repository for portfolio holdings and AI insights.
class PortfolioRepository {
  PortfolioRepository({
    required Box<Holding> holdingsBox,
    required Box<AiInsight> insightsBox,
  })  : _holdingsBox = holdingsBox,
        _insightsBox = insightsBox;

  final Box<Holding> _holdingsBox;
  final Box<AiInsight> _insightsBox;

  // --- Holdings ---

  List<Holding> readHoldings() => _holdingsBox.values.toList();

  Holding? readHolding(String id) => _holdingsBox.get(id);

  Future<void> addHolding(Holding holding) async {
    await _holdingsBox.put(holding.id, holding);
  }

  Future<void> deleteHolding(String id) async {
    await _holdingsBox.delete(id);
  }

  Future<void> upsertHoldings(List<Holding> holdings) async {
    for (final h in holdings) {
      await _holdingsBox.put(h.id, h);
    }
  }

  Future<void> updatePrices(List<Holding> updatedHoldings) async {
    for (final h in updatedHoldings) {
      await _holdingsBox.put(h.id, h);
    }
  }

  double get totalInvestedValue =>
      _holdingsBox.values.fold(0, (sum, h) => sum + h.investedValue);

  double get totalCurrentValue =>
      _holdingsBox.values.fold(0, (sum, h) => sum + h.currentValue);

  Map<String, double> get assetAllocation {
    final map = <String, double>{};
    for (final h in _holdingsBox.values) {
      map[h.assetType.name] = (map[h.assetType.name] ?? 0) + h.currentValue;
    }
    return map;
  }

  // --- AI Insights ---

  List<AiInsight> readInsights() {
    final insights = _insightsBox.values.toList();
    insights.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return insights;
  }

  Future<void> saveInsights(List<AiInsight> insights) async {
    await _insightsBox.clear();
    for (final insight in insights) {
      await _insightsBox.put(insight.id, insight);
    }
  }

  Future<void> clearInsights() async {
    await _insightsBox.clear();
  }
}
