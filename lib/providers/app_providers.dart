import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/ai_insight.dart';
import '../models/category.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import '../models/transaction.dart';
import '../repositories/goal_repository.dart';
import '../repositories/hive_boxes.dart';
import '../repositories/portfolio_repository.dart';
import '../services/ai_extraction_service.dart';
import '../services/insight_generator.dart';
import '../services/nse_market_service.dart';

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
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(AssetTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(HoldingAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(InsightSeverityAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(AiInsightAdapter());
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
        'salary': Category(id: 'salary', name: 'Salary', icon: '💰', colorHex: '0xFF1BAA6A', defaultAmount: 2000.0, isSetback: false),
        'groceries': Category(id: 'groceries', name: 'Groceries', icon: '🛒', colorHex: '0xFF81C784', defaultAmount: 500.0, isSetback: true),
        'food': Category(id: 'food', name: 'Food', icon: '🍽️', colorHex: '0xFFFFB74D', defaultAmount: 350.0, isSetback: true),
        'transport': Category(id: 'transport', name: 'Transport', icon: '🚕', colorHex: '0xFF4FC3F7', defaultAmount: 250.0, isSetback: true),
        'shopping': Category(id: 'shopping', name: 'Shopping', icon: '🛍️', colorHex: '0xFFBA68C8', defaultAmount: 600.0, isSetback: true),
        'bills': Category(id: 'bills', name: 'Bills', icon: '💡', colorHex: '0xFFFFD54F', defaultAmount: 500.0, isSetback: true),
        'health': Category(id: 'health', name: 'Health', icon: '🏥', colorHex: '0xFFEF5350', defaultAmount: 400.0, isSetback: true),
      });
    }
  }
  
  if (!Hive.isBoxOpen(HiveBoxes.settings)) {
    await Hive.openBox(HiveBoxes.settings);
  }
  if (!Hive.isBoxOpen(HiveBoxes.holdings)) {
    await Hive.openBox<Holding>(HiveBoxes.holdings);
  }
  if (!Hive.isBoxOpen(HiveBoxes.aiInsights)) {
    await Hive.openBox<AiInsight>(HiveBoxes.aiInsights);
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
  static const overallSavingsId = '__overall_savings__';

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

  Future<void> setActiveGoal(String? id) async {
    final box = ref.read(settingsBoxProvider);
    final storedId = id ?? overallSavingsId;
    await box.put('activeGoalId', storedId);
    state = storedId;
  }
}

final activeGoalIdProvider = NotifierProvider<ActiveGoalIdNotifier, String?>(() {
  return ActiveGoalIdNotifier();
});

final activeGoalProvider = Provider<Goal?>((ref) {
  final goals = ref.watch(goalsProvider);
  if (goals.isEmpty) return null;

  final activeId = ref.watch(activeGoalIdProvider);
  if (activeId == ActiveGoalIdNotifier.overallSavingsId) return null;
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

  Future<void> updateTransaction(Transaction transaction) async {
    final repository = ref.read(goalRepositoryProvider);
    await repository.updateTransaction(transaction);

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

// ===== Portfolio & AI Providers =====

final holdingsBoxProvider = Provider<Box<Holding>>((ref) {
  final async = ref.watch(hiveInitializerProvider);
  if (async is! AsyncData) {
    throw StateError('Hive is not initialized yet');
  }
  return Hive.box<Holding>(HiveBoxes.holdings);
});

final insightsBoxProvider = Provider<Box<AiInsight>>((ref) {
  final async = ref.watch(hiveInitializerProvider);
  if (async is! AsyncData) {
    throw StateError('Hive is not initialized yet');
  }
  return Hive.box<AiInsight>(HiveBoxes.aiInsights);
});

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepository(
    holdingsBox: ref.watch(holdingsBoxProvider),
    insightsBox: ref.watch(insightsBoxProvider),
  );
});

class HoldingsNotifier extends Notifier<List<Holding>> {
  @override
  List<Holding> build() {
    final repo = ref.read(portfolioRepositoryProvider);
    return repo.readHoldings();
  }

  Future<void> addHolding(Holding holding) async {
    final repo = ref.read(portfolioRepositoryProvider);
    await repo.addHolding(holding);
    state = repo.readHoldings();
  }

  Future<void> upsertHoldings(List<Holding> holdings) async {
    final repo = ref.read(portfolioRepositoryProvider);
    await repo.upsertHoldings(holdings);
    state = repo.readHoldings();
  }

  Future<void> deleteHolding(String id) async {
    final repo = ref.read(portfolioRepositoryProvider);
    await repo.deleteHolding(id);
    state = repo.readHoldings();
  }

  Future<void> refreshPrices() async {
    final repo = ref.read(portfolioRepositoryProvider);
    final marketService = ref.read(nseMarketServiceProvider);
    final currentHoldings = repo.readHoldings();
    await marketService.refreshPrices(currentHoldings);
    await repo.updatePrices(currentHoldings);
    state = repo.readHoldings();
  }
}

final holdingsProvider = NotifierProvider<HoldingsNotifier, List<Holding>>(() {
  return HoldingsNotifier();
});

class AiInsightsNotifier extends Notifier<List<AiInsight>> {
  @override
  List<AiInsight> build() {
    final repo = ref.read(portfolioRepositoryProvider);
    return repo.readInsights();
  }

  Future<void> refreshInsights() async {
    final generator = ref.read(insightGeneratorProvider);
    final holdings = ref.read(holdingsProvider);
    final goals = ref.read(goalsProvider);
    final insights = await generator.generateInsights(
      holdings: holdings,
      goals: goals,
    );
    final repo = ref.read(portfolioRepositoryProvider);
    await repo.saveInsights(insights);
    state = repo.readInsights();
  }
}

final aiInsightsProvider =
    NotifierProvider<AiInsightsNotifier, List<AiInsight>>(() {
  return AiInsightsNotifier();
});

final netWorthProvider = Provider<double>((ref) {
  final holdings = ref.watch(holdingsProvider);
  final goals = ref.watch(goalsProvider);
  final totalHoldingsValue =
      holdings.fold<double>(0, (sum, h) => sum + h.currentValue);
  final totalSavings =
      goals.fold<double>(0, (sum, g) => sum + g.currentAmount);
  return totalHoldingsValue + totalSavings;
});

final assetAllocationProvider = Provider<Map<String, double>>((ref) {
  final holdings = ref.watch(holdingsProvider);
  final map = <String, double>{};
  for (final h in holdings) {
    map[h.assetType.name] = (map[h.assetType.name] ?? 0) + h.currentValue;
  }
  return map;
});

final nseMarketServiceProvider = Provider<NseMarketService>((ref) {
  return NseMarketService();
});

final aiEndpointProvider = Provider<String>((ref) {
  final box = ref.read(settingsBoxProvider);
  return box.get(
    'aiEndpoint',
    defaultValue: 'https://finance-ai.hf.space',
  ) as String;
});

final aiExtractionServiceProvider = Provider<AiExtractionService>((ref) {
  final endpoint = ref.watch(aiEndpointProvider);
  return AiExtractionService(endpointUrl: endpoint);
});

final insightGeneratorProvider = Provider<InsightGenerator>((ref) {
  final aiService = ref.watch(aiExtractionServiceProvider);
  return InsightGenerator(aiService: aiService);
});
