import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../providers/app_providers.dart';
import '../screens/onboarding_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/goal_hero_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showAddTransactionSheet(BuildContext context, bool isSaving) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (context) => AddTransactionSheet(isSaving: isSaving),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final activeGoalId = ref.watch(activeGoalIdProvider);
    final transactions = ref.watch(transactionsProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);
    final categoriesBox = ref.watch(categoriesBoxProvider);
    final categories = categoriesBox.values.toList();
    final overallSavings = transactions
        .where((transaction) => transaction.goalId == null)
        .fold<double>(0, (sum, item) => sum + item.signedAmount);
    final activeGoal = ref.watch(activeGoalProvider);
    final isOverallSelected = activeGoalId == ActiveGoalIdNotifier.overallSavingsId || goals.isEmpty;
    final overviewAmount = isOverallSelected ? overallSavings : activeGoal?.currentAmount ?? 0;
    final computedGoalProgress = goals.map((goal) {
      final currentAmount = transactions
          .where((transaction) => transaction.goalId == goal.id)
          .fold<double>(0, (sum, item) => sum + item.signedAmount);
      final progress = goal.targetAmount == null || goal.targetAmount! <= 0
          ? 0.0
          : (currentAmount / goal.targetAmount!).clamp(0.0, 1.0);
      return MapEntry(goal, {'amount': currentAmount, 'progress': progress});
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Micro Savings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1BAA6A), Color(0xFF2ECF8F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (goals.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: activeGoalId ?? goals.first.id,
                                dropdownColor: const Color(0xFF1BAA6A),
                                style: const TextStyle(color: Colors.white),
                                iconEnabledColor: Colors.white,
                                items: [
                                  const DropdownMenuItem(
                                    value: ActiveGoalIdNotifier.overallSavingsId,
                                    child: Text('Overall savings'),
                                  ),
                                  ...goals.map((goal) => DropdownMenuItem(
                                          value: goal.id,
                                          child: Text(goal.title),
                                        )),
                                ],
                                onChanged: (selectedId) {
                                  if (selectedId == null) return;
                                  ref.read(activeGoalIdProvider.notifier).setActiveGoal(
                                        selectedId == ActiveGoalIdNotifier.overallSavingsId
                                            ? null
                                            : selectedId,
                                      );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '₹${overviewAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                        isOverallSelected ? 'Overall savings' : 'Progress for ${activeGoal?.title ?? ''}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const GoalHeroCard(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      label: '+ Save',
                      color: const Color(0xFFEAF9F0),
                      textColor: const Color(0xFF1BAA6A),
                      onTap: () => _showAddTransactionSheet(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionButton(
                      label: '- Spend',
                      color: const Color(0xFFFDECEC),
                      textColor: const Color(0xFFE26767),
                      onTap: () => _showAddTransactionSheet(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (goals.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Goals',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1E2D),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const OnboardingScreen(),
                              ),
                            );
                          },
                          child: const Text('Add goal'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...computedGoalProgress.map((entry) {
                      final goal = entry.key;
                      final amount = entry.value['amount'] as double;
                      final progress = entry.value['progress'] as double;
                      final percent = goal.targetAmount == null ? 0 : (progress * 100).round();
                      final isComplete = goal.targetAmount != null && amount >= goal.targetAmount!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F7FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(goal.iconPath ?? '🎯', style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E1E2D),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    goal.targetAmount == null
                                        ? '₹${amount.toStringAsFixed(0)} saved • no target yet'
                                        : '₹${amount.toStringAsFixed(0)} / ₹${goal.targetAmount!.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 90,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$percent%',
                                    style: TextStyle(
                                      color: isComplete ? const Color(0xFFF1B31C) : const Color(0xFF1BAA6A),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: goal.targetAmount == null ? 0 : progress,
                                    minHeight: 7,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isComplete ? const Color(0xFFF1B31C) : const Color(0xFF1BAA6A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              const SizedBox(height: 24),
              const Text(
                'Quick categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E2D),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSetback = cat.isSetback;
                    return ActionChip(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade200),
                      label: Text(
                        '${cat.icon} ${cat.name} ${isSetback ? '-' : '+'}₹${cat.defaultAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        final activeGoal = ref.read(activeGoalProvider);
                        ref.read(transactionsProvider.notifier).addTransaction(
                          Transaction(
                            id: 'txn-${DateTime.now().millisecondsSinceEpoch}',
                            goalId: activeGoal?.id,
                            amount: cat.defaultAmount,
                            type: isSetback ? TransactionType.setback : TransactionType.saving,
                            categoryId: cat.id,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E2D),
                ),
              ),
              const SizedBox(height: 12),
              if (recentTransactions.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    itemCount: recentTransactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = recentTransactions[index];
                      final isSaving = item.type == TransactionType.saving;
                      final cat = categories.firstWhere(
                        (c) => c.id == item.categoryId,
                        orElse: () => categories.first,
                      );

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isSaving
                                  ? const Color(0xFFEAF9F0)
                                  : const Color(0xFFFDECEC),
                              child: Text(
                                cat.icon,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.note?.isNotEmpty == true ? item.note! : cat.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E1E2D),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.timestamp.toLocal().toString().split(' ')[0],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isSaving ? '+' : '-'}₹${item.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: isSaving
                                    ? const Color(0xFF1BAA6A)
                                    : const Color(0xFFE26767),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text('No recent activity yet.'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
