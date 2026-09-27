import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/transaction.dart';
import '../providers/analytics_provider.dart';
import '../providers/app_providers.dart';
import '../utils/currency.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(filteredTransactionsProvider);
    final categoryTotals = ref.watch(categoryAnalyticsProvider);
    final categorySpendTotals = ref.watch(categorySpendingProvider);
    final dailyTrend = ref.watch(dailyTrendProvider);
    final allCategories = ref.watch(categoriesBoxProvider).values.toList();

    final savings = transactions
        .where((t) => t.type == TransactionType.saving)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final setbacks = transactions
        .where((t) => t.type == TransactionType.setback)
        .fold<double>(0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: ListView(
            children: [
              const Text('Total Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(title: 'Saved', amount: savings, color: const Color(0xFF1BAA6A)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SummaryCard(title: 'Spent', amount: setbacks, color: const Color(0xFFE26767)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Category Split', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (categoryTotals.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No saved category data for this period.'),
                ))
              else
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _getSections(categoryTotals, allCategories, 'Saved'),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text('Spend Split', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (categorySpendTotals.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No spend category data for this period.'),
                ))
              else
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _getSections(categorySpendTotals, allCategories, 'Spent'),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text('Daily Savings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (dailyTrend.isEmpty)
                const Text('No daily trend yet.')
              else
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _maxDailyValue(dailyTrend),
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final keys = dailyTrend.keys.toList();
                              if (value < 0 || value >= keys.length) return const SizedBox();
                              final label = keys[value.toInt()].day.toString();
                              return Text(label, style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: dailyTrend.entries.toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: item.value.abs(),
                              color: item.value >= 0 ? const Color(0xFF1BAA6A) : const Color(0xFFE26767),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getSections(Map<String, double> categoryTotals, List<dynamic> categories, String sectionName) {
    if (categoryTotals.isEmpty) return [PieChartSectionData(value: 1, title: '', color: Colors.grey.shade300)];

    final total = categoryTotals.values.fold<double>(0, (sum, value) => sum + value);
    final colors = [
      const Color(0xFF1BAA6A),
      const Color(0xFF4FC3F7),
      const Color(0xFFFFB74D),
      const Color(0xFFBA68C8),
      const Color(0xFFEF5350),
      const Color(0xFF9575CD),
      const Color(0xFF81C784),
      const Color(0xFFFF8A80),
    ];

    return categoryTotals.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final categoryId = entry.value.key;
      dynamic category;
      for (final item in categories) {
        if (item.id == categoryId) {
          category = item;
          break;
        }
      }
      final name = category?.name ?? categoryId;
      final color = category != null
          ? Color(int.tryParse(category.colorHex.replaceFirst('0x', '0xFF')) ?? 0xFF1BAA6A)
          : colors[index % colors.length];
      final value = entry.value.value;
      final percent = total == 0 ? 0.0 : (value / total) * 100;
      return PieChartSectionData(
        value: value,
        title: '$name\n${percent.toStringAsFixed(0)}%',
        color: color,
        radius: 56,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  double _maxDailyValue(Map<DateTime, double> dailyTrend) {
    if (dailyTrend.isEmpty) return 1;
    final max = dailyTrend.values.fold<double>(0, (sum, value) => value.abs() > sum ? value.abs() : sum);
    return max == 0 ? 1 : max * 1.2;
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryCard({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(CurrencyFormatter.format(amount, 'INR'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
