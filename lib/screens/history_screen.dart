import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../providers/analytics_provider.dart';
import '../providers/app_providers.dart';
import '../utils/currency.dart';
import '../widgets/add_transaction_sheet.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(filteredTransactionsProvider);
    final categoriesBox = ref.watch(categoriesBoxProvider);
    final categories = categoriesBox.values.toList();
    final filter = ref.watch(analyticsFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TimeFilter.values.map((timeFilter) {
                  final selected = filter == timeFilter;
                  return ChoiceChip(
                    label: Text(_labelForFilter(timeFilter)),
                    selected: selected,
                    onSelected: (_) {
                      ref.read(analyticsFilterProvider.notifier).setFilter(timeFilter);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('No transactions yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = transactions[index];
                          final isSaving = item.type == TransactionType.saving;
                          final cat = categories.firstWhere(
                            (c) => c.id == item.categoryId,
                            orElse: () => categories.first,
                          );
                          void openEditor() {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              backgroundColor: Colors.transparent,
                              constraints: const BoxConstraints(maxWidth: 720),
                              builder: (_) => AddTransactionSheet(
                                isSaving: isSaving,
                                initialTransaction: item,
                              ),
                            );
                          }

                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              ref.read(transactionsProvider.notifier).deleteTransaction(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Transaction deleted')),
                              );
                            },
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: openEditor,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
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
                                    child: Text(cat.icon, style: const TextStyle(fontSize: 16)),
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isSaving ? '+' : '-'}${CurrencyFormatter.format(item.amount, 'INR')}',
                                        style: TextStyle(
                                          color: isSaving
                                              ? const Color(0xFF1BAA6A)
                                              : const Color(0xFFE26767),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextButton.icon(
                                        onPressed: openEditor,
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                        label: const Text('Edit'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _labelForFilter(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.week:
        return '7D';
      case TimeFilter.month:
        return '1M';
      case TimeFilter.allTime:
        return 'All';
      case TimeFilter.custom:
        return 'Custom';
    }
  }
}
