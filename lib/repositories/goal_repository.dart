import 'package:hive/hive.dart';

import '../models/goal.dart';
import '../models/transaction.dart';

class GoalRepository {
  GoalRepository({
    required Box<Goal> goalsBox,
    required Box<Transaction> transactionsBox,
  })  : _goalsBox = goalsBox,
        _transactionsBox = transactionsBox;

  final Box<Goal> _goalsBox;
  final Box<Transaction> _transactionsBox;

  List<Goal> readGoals() {
    final goals = _goalsBox.values.toList();
    return goals..sort((a, b) => a.title.compareTo(b.title));
  }

  Goal? readGoal(String goalId) => _goalsBox.get(goalId);

  Map<String, double> categoryBreakdownForGoal(String goalId) {
    final totals = <String, double>{};

    for (final transaction in _transactionsBox.values.where((item) => item.goalId == goalId)) {
      final key = transaction.categoryId;
      totals[key] = (totals[key] ?? 0) + transaction.amount;
    }

    return totals;
  }

  Map<String, double> dailySavingsForGoal(String goalId) {
    final totals = <String, double>{};

    for (final transaction in _transactionsBox.values.where((item) => item.goalId == goalId)) {
      final dayKey = transaction.timestamp.toLocal().toIso8601String().split('T').first;
      totals[dayKey] = (totals[dayKey] ?? 0) + transaction.signedAmount;
    }

    return totals;
  }

  Future<void> addGoal(Goal goal) async {
    await _goalsBox.put(goal.id, goal);
    await syncGoalAmount(goal.id);
  }

  Future<void> deleteGoal(String goalId) async {
    await _goalsBox.delete(goalId);

    final txnsToDelete = _transactionsBox.values
        .where((t) => t.goalId == goalId)
        .map((t) => t.id)
        .toList();
    if (txnsToDelete.isNotEmpty) {
      await _transactionsBox.deleteAll(txnsToDelete);
    }
  }

  Future<void> syncGoalAmount(String goalId) async {
    final goal = _goalsBox.get(goalId);
    if (goal == null) return;

    final total = _transactionsBox.values
        .where((transaction) => transaction.goalId == goalId)
        .fold<double>(0, (sum, transaction) => sum + transaction.signedAmount);

    final updatedGoal = goal.copyWith(currentAmount: total);
    await _goalsBox.put(goalId, updatedGoal);
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _transactionsBox.put(transaction.id, transaction);
    await syncGoalAmount(transaction.goalId);
  }

  Future<void> deleteTransaction(String transactionId) async {
    final transaction = _transactionsBox.get(transactionId);
    if (transaction == null) return;

    final goalId = transaction.goalId;
    await _transactionsBox.delete(transactionId);
    await syncGoalAmount(goalId);
  }

}

