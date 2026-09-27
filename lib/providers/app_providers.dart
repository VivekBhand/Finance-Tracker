import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/category.dart';
import '../models/goal.dart';
import '../models/transaction.dart';
import '../repositories/goal_repository.dart';
import '../repositories/hive_boxes.dart';

final hiveInitializerProvider = FutureProvider<void>((ref) async {
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(GoalAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(TransactionTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(TransactionAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(CategoryAdapter());
  }

  if (!Hive.isBoxOpen(HiveBoxes.goals)) {
    await Hive.openBox<Goal>(HiveBoxes.goals);
  }
  if (!Hive.isBoxOpen(HiveBoxes.transactions)) {
    await Hive.openBox<Transaction>(HiveBoxes.transactions);
  }
  if (!Hive.isBoxOpen(HiveBoxes.categories)) {
    final box = await Hive.openBox<Category>(HiveBoxes.categories);
    if (box.isEmpty) {
      await box.putAll({
        'salary': Category(id: 'salary', name: 'Salary', icon: '💰', colorHex: '0xFF1BAA6A', defaultAmount: 2500.0, isSetback: false),
        'freelance': Category(id: 'freelance', name: 'Freelance', icon: '💼', colorHex: '0xFF4CAF50', defaultAmount: 1200.0, isSetback: false),
        'coffee': Category(id: 'coffee', name: 'Skipped Coffee', icon: '☕', colorHex: '0xFF8D6E63', defaultAmount: 45.0, isSetback: false),
        'groceries': Category(id: 'groceries', name: 'Groceries', icon: '🛒', colorHex: '0xFF81C784', defaultAmount: 650.0, isSetback: true),
        'transport': Category(id: 'transport', name: 'Travel', icon: '🚕', colorHex: '0xFF4FC3F7', defaultAmount: 300.0, isSetback: false),
        'dining': Category(id: 'dining', name: 'Dining Out', icon: '🍽️', colorHex: '0xFFFFB74D', defaultAmount: 420.0, isSetback: true),
        'shopping': Category(id: 'shopping', name: 'Shopping', icon: '🛍️', colorHex: '0xFFBA68C8', defaultAmount: 800.0, isSetback: true),
        'utilities': Category(id: 'utilities', name: 'Bills', icon: '💡', colorHex: '0xFFFFD54F', defaultAmount: 550.0, isSetback: true),
        'health': Category(id: 'health', name: 'Health', icon: '🏥', colorHex: '0xFFEF5350', defaultAmount: 450.0, isSetback: true),
        'travel': Category(id: 'travel', name: 'Travel', icon: '✈️', colorHex: '0xFF64B5F6', defaultAmount: 1200.0, isSetback: true),
        'education': Category(id: 'education', name: 'Education', icon: '📚', colorHex: '0xFF9575CD', defaultAmount: 600.0, isSetback: true),
        'gift': Category(id: 'gift', name: 'Gift', icon: '🎁', colorHex: '0xFFFF8A80', defaultAmount: 350.0, isSetback: true),
      });
    }
  }
  
  if (!Hive.isBoxOpen(HiveBoxes.settings)) {
    await Hive.openBox(HiveBoxes.settings);
  }
});

final goalsBoxProvider = Provider<Box<Goal>>((ref) {
  final async = ref.watch(hiveInitializerProvider);
  if (async is! AsyncData) {
    throw StateError('Hive is not initialized yet');
  }
  return Hive.box<Goal>(HiveBoxes.goals);
});

final transactionsBoxProvider = Provider<Box<Transaction>>((ref) {
  final async = ref.watch(hiveInitializerProvider);
  if (async is! AsyncData) {
    throw StateError('Hive is not initialized yet');
  }
  return Hive.box<Transaction>(HiveBoxes.transactions);
});

final categoriesBoxProvider = Provider<Box<Category>>((ref) {
  final async = ref.watch(hiveInitializerProvider);
  if (async is! AsyncData) {
    throw StateError('Hive is not initialized yet');
  }
  return Hive.box<Category>(HiveBoxes.categories);
});

final settingsBoxProvider = Provider<Box>((ref) {
  final async = ref.watch(hiveInitializerProvider);
  if (async is! AsyncData) {
    throw StateError('Hive is not initialized yet');
  }
  return Hive.box(HiveBoxes.settings);
});

class CurrencyNotifier extends Notifier<String> {
  @override
  String build() {
    final box = ref.read(settingsBoxProvider);
    return box.get('currencyCode', defaultValue: 'INR') as String;
  }

  Future<void> setCurrency(String code) async {
    final box = ref.read(settingsBoxProvider);
    await box.put('currencyCode', code);
    state = code;
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, String>(() {
  return CurrencyNotifier();
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(
    goalsBox: ref.watch(goalsBoxProvider),
    transactionsBox: ref.watch(transactionsBoxProvider),
  );
});

final goalsProvider = NotifierProvider<GoalsNotifier, List<Goal>>(() {
  return GoalsNotifier();
});

final transactionsProvider = NotifierProvider<TransactionsNotifier, List<Transaction>>(() {
  return TransactionsNotifier();
});

final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final sorted = [...transactions]
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return sorted.take(5).toList();
});

class ActiveGoalIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    final box = ref.read(settingsBoxProvider);
    final savedId = box.get('activeGoalId') as String?;
    
    // If no saved ID, but we have goals, fallback to first goal's ID
    if (savedId == null) {
      final goals = ref.read(goalsProvider);
      if (goals.isNotEmpty) {
        return goals.first.id;
      }
    }
    return savedId;
  }

  Future<void> setActiveGoal(String id) async {
    final box = ref.read(settingsBoxProvider);
    await box.put('activeGoalId', id);
    state = id;
  }
}

final activeGoalIdProvider = NotifierProvider<ActiveGoalIdNotifier, String?>(() {
  return ActiveGoalIdNotifier();
});

final activeGoalProvider = Provider<Goal?>((ref) {
  final goals = ref.watch(goalsProvider);
  if (goals.isEmpty) return null;

  final activeId = ref.watch(activeGoalIdProvider);
  final activeGoal = activeId != null && goals.any((g) => g.id == activeId)
      ? goals.firstWhere((g) => g.id == activeId)
      : goals.first;

  final transactions = ref.watch(transactionsProvider);
  final computedCurrent = transactions
      .where((transaction) => transaction.goalId == activeGoal.id)
      .fold<double>(0, (sum, transaction) => sum + transaction.signedAmount);

  return activeGoal.copyWith(currentAmount: computedCurrent);
});

final homeDashboardProvider = Provider<HomeDashboardState>((ref) {
  final activeGoal = ref.watch(activeGoalProvider);
  final recentTransactions = ref.watch(recentTransactionsProvider);

  return HomeDashboardState(
    goal: activeGoal,
    recentTransactions: recentTransactions,
    amountSaved: activeGoal?.currentAmount ?? 0,
    progress: activeGoal == null ? 0 : activeGoal.progressPercent,
  );
});

class HomeDashboardState {
  const HomeDashboardState({
    required this.goal,
    required this.recentTransactions,
    required this.amountSaved,
    required this.progress,
  });

  final Goal? goal;
  final List<Transaction> recentTransactions;
  final double amountSaved;
  final double progress;
}

class GoalsNotifier extends Notifier<List<Goal>> {
  @override
  List<Goal> build() {
    final repository = ref.read(goalRepositoryProvider);
    return repository.readGoals();
  }

  Future<void> addGoal(Goal goal) async {
    final repository = ref.read(goalRepositoryProvider);
    await repository.addGoal(goal);
    state = repository.readGoals();
  }

  Future<void> deleteGoal(String goalId) async {
    final repository = ref.read(goalRepositoryProvider);
    await repository.deleteGoal(goalId);
    state = repository.readGoals();
  }
}

class TransactionsNotifier extends Notifier<List<Transaction>> {
  @override
  List<Transaction> build() {
    final box = ref.read(transactionsBoxProvider);
    return box.values.toList().reversed.toList();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final repository = ref.read(goalRepositoryProvider);
    await repository.addTransaction(transaction);
    
    final box = ref.read(transactionsBoxProvider);
    state = box.values.toList().reversed.toList();
  }

  Future<void> deleteTransaction(String transactionId) async {
    final repository = ref.read(goalRepositoryProvider);
    await repository.deleteTransaction(transactionId);
    
    final box = ref.read(transactionsBoxProvider);
    state = box.values.toList().reversed.toList();
  }
}
