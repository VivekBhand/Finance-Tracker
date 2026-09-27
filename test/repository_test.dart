import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import 'package:finance_tracker/models/goal.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/repositories/goal_repository.dart';

void main() {
  late Box<Goal> goalsBox;
  late Box<Transaction> transactionsBox;
  late GoalRepository repository;
  
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(GoalAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
  });

  setUp(() async {
    goalsBox = await Hive.openBox<Goal>('test_goals');
    transactionsBox = await Hive.openBox<Transaction>('test_transactions');
    await goalsBox.clear();
    await transactionsBox.clear();
    
    repository = GoalRepository(
      goalsBox: goalsBox,
      transactionsBox: transactionsBox,
    );
  });
  
  tearDown(() async {
    await goalsBox.close();
    await transactionsBox.close();
  });

  test('Goal sync logic correctly computes net progress from transactions', () async {
    final goalId = const Uuid().v4();
    final goal = Goal(id: goalId, title: 'MacBook', targetAmount: 1500);
    await repository.addGoal(goal);
    
    // Add saving
    final tx1 = Transaction(id: 't1', goalId: goalId, amount: 20, type: TransactionType.saving, categoryId: 'coffee');
    await repository.addTransaction(tx1);
    expect(goalsBox.get(goalId)?.currentAmount, 20.0);
    
    // Add setback
    final tx2 = Transaction(id: 't2', goalId: goalId, amount: 5, type: TransactionType.setback, categoryId: 'snack');
    await repository.addTransaction(tx2);
    expect(goalsBox.get(goalId)?.currentAmount, 15.0);
  });

  test('Transaction deletion properly recalculates goal total', () async {
    final goalId = const Uuid().v4();
    final goal = Goal(id: goalId, title: 'Trip', targetAmount: 500);
    await repository.addGoal(goal);
    
    final tx1 = Transaction(id: 't1', goalId: goalId, amount: 100, type: TransactionType.saving, categoryId: 'c1');
    final tx2 = Transaction(id: 't2', goalId: goalId, amount: 50, type: TransactionType.saving, categoryId: 'c2');
    
    await repository.addTransaction(tx1);
    await repository.addTransaction(tx2);
    expect(goalsBox.get(goalId)?.currentAmount, 150.0);
    
    // Delete t1
    await repository.deleteTransaction('t1');
    
    // Goal should now only reflect t2
    expect(goalsBox.get(goalId)?.currentAmount, 50.0);
  });
  
  test('Goal deletion cascades and deletes associated transactions', () async {
    final goalId = const Uuid().v4();
    final goal = Goal(id: goalId, title: 'Trip', targetAmount: 500);
    await repository.addGoal(goal);
    
    final tx1 = Transaction(id: 't1', goalId: goalId, amount: 100, type: TransactionType.saving, categoryId: 'c1');
    await repository.addTransaction(tx1);
    
    expect(transactionsBox.containsKey('t1'), true);
    
    // Delete goal
    await repository.deleteGoal(goalId);
    
    // Transaction should be gone
    expect(transactionsBox.containsKey('t1'), false);
  });

  test('multiple goals keep transaction totals isolated from each other', () async {
    final goalA = Goal(id: const Uuid().v4(), title: 'Home', targetAmount: 1000);
    final goalB = Goal(id: const Uuid().v4(), title: 'Travel', targetAmount: 2000);

    await repository.addGoal(goalA);
    await repository.addGoal(goalB);

    await repository.addTransaction(
      Transaction(id: 'tx-a1', goalId: goalA.id, amount: 200, type: TransactionType.saving, categoryId: 'food'),
    );
    await repository.addTransaction(
      Transaction(id: 'tx-a2', goalId: goalA.id, amount: 50, type: TransactionType.setback, categoryId: 'shopping'),
    );
    await repository.addTransaction(
      Transaction(id: 'tx-b1', goalId: goalB.id, amount: 250, type: TransactionType.saving, categoryId: 'transport'),
    );

    expect(repository.readGoal(goalA.id)?.currentAmount, 150.0);
    expect(repository.readGoal(goalB.id)?.currentAmount, 250.0);
  });

  test('repository can aggregate category and daily totals for a goal', () async {
    final goalId = const Uuid().v4();
    final goal = Goal(id: goalId, title: 'Emergency Fund', targetAmount: 1500);
    await repository.addGoal(goal);

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    await repository.addTransaction(
      Transaction(id: 'day-1', goalId: goalId, amount: 120, type: TransactionType.saving, categoryId: 'food', timestamp: yesterday),
    );
    await repository.addTransaction(
      Transaction(id: 'day-2', goalId: goalId, amount: 80, type: TransactionType.saving, categoryId: 'food', timestamp: today),
    );
    await repository.addTransaction(
      Transaction(id: 'day-3', goalId: goalId, amount: 50, type: TransactionType.setback, categoryId: 'shopping', timestamp: today),
    );

    final categoryTotals = repository.categoryBreakdownForGoal(goalId);
    expect(categoryTotals['food'], 200.0);
    expect(categoryTotals['shopping'], 50.0);

    final dailyTotals = repository.dailySavingsForGoal(goalId);
    expect(dailyTotals.containsKey(_dateKey(yesterday)), true);
    expect(dailyTotals.containsKey(_dateKey(today)), true);
    expect(dailyTotals[_dateKey(today)], 30.0);
  });
}

String _dateKey(DateTime value) => value.toLocal().toIso8601String().split('T').first;
