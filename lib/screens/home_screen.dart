import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../providers/app_providers.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/goal_hero_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showAddTransactionSheet(BuildContext context, bool isSaving) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(isSaving: isSaving),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final activeGoalId = ref.watch(activeGoalIdProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);
    final categoriesBox = ref.watch(categoriesBoxProvider);
    final categories = categoriesBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Micro Savings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
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
              if (goals.length > 1)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: activeGoalId ?? goals.first.id,
                      isExpanded: true,
                      items: goals
                          .map((goal) => DropdownMenuItem(
                                value: goal.id,
                                child: Text(goal.title),
                              ))
                          .toList(),
                      onChanged: (selectedId) {
                        if (selectedId == null) return;
                        ref.read(activeGoalIdProvider.notifier).setActiveGoal(selectedId);
                      },
                    ),
                  ),
                ),
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
                        '${cat.icon} ${cat.name} ${isSetback ? '-' : '+'}\$${cat.defaultAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        final activeGoal = ref.read(activeGoalProvider);
                        if (activeGoal == null) return;
                        ref.read(transactionsProvider.notifier).addTransaction(
                          Transaction(
                            id: 'txn-${DateTime.now().millisecondsSinceEpoch}',
                            goalId: activeGoal.id,
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
                              '${isSaving ? '+' : '-'}\$${item.amount.toStringAsFixed(2)}',
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
