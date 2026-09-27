import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/ai_insight.dart';
import '../models/holding.dart';
import '../providers/app_providers.dart';
import '../utils/currency.dart';
import 'document_upload_screen.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsProvider);
    final insights = ref.watch(aiInsightsProvider);
    final netWorth = ref.watch(netWorthProvider);
    final currency = ref.watch(currencyProvider);
    final allocation = ref.watch(assetAllocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio & Insights'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh prices & insights',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Updating prices & insights...')),
              );
              await ref.read(holdingsProvider.notifier).refreshPrices();
              await ref.read(aiInsightsProvider.notifier).refreshInsights();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DocumentUploadScreen(),
            ),
          );
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload CAS/Statement'),
        backgroundColor: const Color(0xFF1BAA6A),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Net Worth Summary Card
            _NetWorthCard(netWorth: netWorth, currency: currency),
            const SizedBox(height: 24),

            // Asset Allocation Donut Chart
            if (allocation.isNotEmpty) ...[
              const Text('Asset Allocation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 35,
                    sections: _buildAllocationSections(allocation),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // AI Insight Static Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Insights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    ref.read(aiInsightsProvider.notifier).refreshInsights();
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Analyze'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (insights.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No insights yet. Tap "Analyze" to generate insights from your holdings and goals.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...insights.map((insight) => _InsightCard(insight: insight)),

            const SizedBox(height: 24),

            // Holdings List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Holdings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${holdings.length} assets',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            if (holdings.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No investments tracked yet',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap "Upload CAS/Statement" to import mutual funds, stocks, or FDs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...holdings.map((h) => _HoldingTile(holding: h, currency: currency)),

            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildAllocationSections(
      Map<String, double> alloc) {
    final colors = <String, Color>{
      'equity': const Color(0xFF4FC3F7),
      'mutualFund': const Color(0xFF1BAA6A),
      'fixedDeposit': const Color(0xFFFFB74D),
      'gold': const Color(0xFFFFD54F),
      'ppf': const Color(0xFF81C784),
      'bond': const Color(0xFFBA68C8),
      'other': Colors.grey,
    };

    final total = alloc.values.fold<double>(0, (s, v) => s + v);
    if (total == 0) return [];

    return alloc.entries.map((entry) {
      final pct = (entry.value / total) * 100;
      final color = colors[entry.key] ?? Colors.grey;
      return PieChartSectionData(
        value: entry.value,
        title: '${pct.toStringAsFixed(0)}%',
        color: color,
        radius: 45,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.netWorth, required this.currency});
  final double netWorth;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2D), Color(0xFF2D2D44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Net Worth',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(netWorth, currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Includes Micro-Savings Goals + Portfolio Investments',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final AiInsight insight;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    IconData icon;

    switch (insight.severity) {
      case InsightSeverity.critical:
        bg = const Color(0xFFFDECEC);
        border = const Color(0xFFE26767);
        icon = Icons.warning_amber_rounded;
        break;
      case InsightSeverity.warning:
        bg = const Color(0xFFFFF3E0);
        border = const Color(0xFFFFB74D);
        icon = Icons.error_outline;
        break;
      case InsightSeverity.suggestion:
        bg = const Color(0xFFEAF9F0);
        border = const Color(0xFF1BAA6A);
        icon = Icons.lightbulb_outline;
        break;
      case InsightSeverity.info:
        bg = const Color(0xFFE3F2FD);
        border = const Color(0xFF4FC3F7);
        icon = Icons.info_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: border, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.body,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingTile extends StatelessWidget {
  const _HoldingTile({required this.holding, required this.currency});
  final Holding holding;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isPositive = holding.unrealizedGain >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _assetColor(holding.assetType).withValues(alpha: 0.15),
            child: Text(
              _assetEmoji(holding.assetType),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${holding.quantity} units @ ${CurrencyFormatter.format(holding.avgBuyPrice, currency)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(holding.currentValue, currency),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                '${isPositive ? '+' : ''}${holding.returnPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isPositive
                      ? const Color(0xFF1BAA6A)
                      : const Color(0xFFE26767),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _assetColor(AssetType type) {
    switch (type) {
      case AssetType.equity:
        return const Color(0xFF4FC3F7);
      case AssetType.mutualFund:
        return const Color(0xFF1BAA6A);
      case AssetType.fixedDeposit:
        return const Color(0xFFFFB74D);
      case AssetType.gold:
        return const Color(0xFFFFD54F);
      case AssetType.ppf:
        return const Color(0xFF81C784);
      case AssetType.bond:
        return const Color(0xFFBA68C8);
      default:
        return Colors.grey;
    }
  }

  String _assetEmoji(AssetType type) {
    switch (type) {
      case AssetType.equity:
        return '📈';
      case AssetType.mutualFund:
        return '📊';
      case AssetType.fixedDeposit:
        return '🏦';
      case AssetType.gold:
        return '🪙';
      case AssetType.ppf:
        return '🛡️';
      case AssetType.bond:
        return '📜';
      default:
        return '💼';
    }
  }
}
