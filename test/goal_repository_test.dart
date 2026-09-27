import 'dart:io';

import 'package:finance_tracker/models/goal.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/repositories/goal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Box<Goal> goalsBox;
  late Box<Transaction> transactionsBox;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('finance_tracker_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GoalAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TransactionAdapter());
    }

    goalsBox = await Hive.openBox<Goal>('goals_test');
    transactionsBox = await Hive.openBox<Transaction>('transactions_test');
    await goalsBox.clear();
    await transactionsBox.clear();
  });

  tearDown(() async {
    await goalsBox.close();
    await transactionsBox.close();
  });

  test('syncGoalAmount reflects net progress from saving and setback transactions', () async {
    final goal = Goal(
      id: 'goal-1',
      title: 'MacBook Pro',
      targetAmount: 1500,
      currentAmount: 0,
    );

    await goalsBox.put(goal.id, goal);

    final repo = GoalRepository(goalsBox: goalsBox, transactionsBox: transactionsBox);

    await transactionsBox.put(
      'txn-1',
      Transaction(
        id: 'txn-1',
        goalId: goal.id,
        amount: 200,
        type: TransactionType.saving,
        categoryId: 'coffee',
      ),
    );

    await transactionsBox.put(
      'txn-2',
      Transaction(
        id: 'txn-2',
        goalId: goal.id,
        amount: 50,
        type: TransactionType.setback,
        categoryId: 'food',
      ),
    );

    await repo.syncGoalAmount(goal.id);

    expect(goalsBox.get(goal.id)!.currentAmount, 150.0);
  });

  test('deleteTransaction recalculates goal amount immediately', () async {
    final goal = Goal(
      id: 'goal-2',
      title: 'New Phone',
      targetAmount: 700,
      currentAmount: 0,
    );

    await goalsBox.put(goal.id, goal);

    final repo = GoalRepository(goalsBox: goalsBox, transactionsBox: transactionsBox);

    final saving = Transaction(
      id: 'save-1',
      goalId: goal.id,
      amount: 80,
      type: TransactionType.saving,
      categoryId: 'transport',
    );

    final setback = Transaction(
      id: 'spend-1',
      goalId: goal.id,
      amount: 25,
      type: TransactionType.setback,
      categoryId: 'shopping',
    );

    await repo.addTransaction(saving);
    await repo.addTransaction(setback);
    await repo.deleteTransaction(saving.id);

    expect(goalsBox.get(goal.id)!.currentAmount, -25.0);
  });
}
