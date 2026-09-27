import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import 'app_providers.dart';

enum TimeFilter { week, month, allTime, custom }

class AnalyticsState {
  AnalyticsState({
    required this.filter,
    required this.transactions,
  });

  final TimeFilter filter;
  final List<Transaction> transactions;
}

class AnalyticsFilterNotifier extends Notifier<TimeFilter> {
  @override
  TimeFilter build() {
    return TimeFilter.allTime;
  }

  void setFilter(TimeFilter newFilter) {
    state = newFilter;
  }
}

final analyticsFilterProvider = NotifierProvider<AnalyticsFilterNotifier, TimeFilter>(() {
  return AnalyticsFilterNotifier();
});

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final activeGoal = ref.watch(activeGoalProvider);
  if (activeGoal == null) return [];

  final allTransactions = ref.watch(transactionsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  
  final goalTransactions = allTransactions.where((t) => t.goalId == activeGoal.id).toList();

  final now = DateTime.now();
  switch (filter) {
    case TimeFilter.week:
      final start = now.subtract(const Duration(days: 7));
      return goalTransactions.where((t) => t.timestamp.isAfter(start)).toList();
    case TimeFilter.month:
      final start = DateTime(now.year, now.month - 1, now.day);
      return goalTransactions.where((t) => t.timestamp.isAfter(start)).toList();
    case TimeFilter.allTime:
    case TimeFilter.custom:
      return goalTransactions;
  }
});

final categoryAnalyticsProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  final Map<String, double> totals = {};

  for (final t in transactions) {
    if (t.type == TransactionType.saving) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }
  }
  return totals;
});

final categorySpendingProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  final Map<String, double> totals = {};

  for (final t in transactions) {
    if (t.type == TransactionType.setback) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }
  }
  return totals;
});

final dailyTrendProvider = Provider<Map<DateTime, double>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  final Map<DateTime, double> dailyTotals = {};

  for (final t in transactions) {
    final date = DateTime(t.timestamp.year, t.timestamp.month, t.timestamp.day);
    dailyTotals[date] = (dailyTotals[date] ?? 0) + t.signedAmount;
  }
  
  // Sort by date
  final sortedKeys = dailyTotals.keys.toList()..sort();
  final Map<DateTime, double> sortedTotals = {};
  for (final key in sortedKeys) {
    sortedTotals[key] = dailyTotals[key]!;
  }
  
  return sortedTotals;
});
