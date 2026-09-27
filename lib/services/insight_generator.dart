import '../models/ai_insight.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import 'ai_extraction_service.dart';

/// Hybrid insight generator: rule-based (always available) + AI-powered (when HF Space is reachable).
class InsightGenerator {
  InsightGenerator({required AiExtractionService aiService})
      : _ai = aiService;

  final AiExtractionService _ai;

  /// Generate insights from portfolio holdings and savings goals.
  Future<List<AiInsight>> generateInsights({
    required List<Holding> holdings,
    required List<Goal> goals,
  }) async {
    final insights = <AiInsight>[];

    // ===== Rule-Based Insights (instant, offline) =====

    final totalValue =
        holdings.fold<double>(0, (sum, h) => sum + h.currentValue);

    // Empty portfolio nudge
    if (holdings.isEmpty) {
      insights.add(AiInsight(
        id: 'empty-portfolio',
        title: '📄 No Holdings Yet',
        body: 'Upload a consolidated account statement (CAS) or bank statement '
            'to automatically import your investments.',
        severity: InsightSeverity.info,
      ));
    }

    // Concentration risk: any single holding > 40% of portfolio
    if (totalValue > 0) {
      for (final h in holdings) {
        final pct = (h.currentValue / totalValue) * 100;
        if (pct > 40) {
          insights.add(AiInsight(
            id: 'conc-${h.id}',
            title: '⚠️ High Concentration: ${h.name}',
            body: '${h.name} is ${pct.toStringAsFixed(0)}% of your portfolio. '
                'Consider diversifying to reduce single-asset risk.',
            severity: InsightSeverity.warning,
            relatedHoldingId: h.id,
          ));
        }
      }
    }

    // Underperforming holdings (> 10% loss)
    for (final h in holdings) {
      if (h.investedValue > 0 && h.returnPercent < -10) {
        insights.add(AiInsight(
          id: 'perf-${h.id}',
          title: '📉 ${h.name} down ${h.returnPercent.toStringAsFixed(1)}%',
          body: 'This holding has lost more than 10% from your purchase price. '
              'Review if the fundamentals still support your investment thesis.',
          severity: InsightSeverity.warning,
          relatedHoldingId: h.id,
        ));
      }
    }

    // FD vs inflation warning
    for (final h
        in holdings.where((h) => h.assetType == AssetType.fixedDeposit)) {
      if (h.investedValue > 0 && h.returnPercent < 6) {
        insights.add(AiInsight(
          id: 'fd-${h.id}',
          title: '💡 FD Returns Below Inflation',
          body: 'Your FD "${h.name}" is earning ~${h.returnPercent.toStringAsFixed(1)}%. '
              'With CPI inflation at ~5-6%, your real returns may be negative. '
              'Consider debt mutual funds for better post-tax returns.',
          severity: InsightSeverity.suggestion,
          relatedHoldingId: h.id,
        ));
      }
    }

    // 100% equity warning
    if (holdings.isNotEmpty && totalValue > 0) {
      final equityValue = holdings
          .where((h) => h.assetType == AssetType.equity)
          .fold<double>(0, (sum, h) => sum + h.currentValue);
      if (equityValue / totalValue > 0.95) {
        insights.add(AiInsight(
          id: 'alloc-equity',
          title: '💡 Portfolio is Nearly 100% Equity',
          body: 'Consider adding debt instruments (FDs, debt MFs, PPF) for '
              'stability, especially if you have short-term goals.',
          severity: InsightSeverity.suggestion,
        ));
      }
    }

    // Goal pace tracking
    for (final g in goals) {
      final target = g.targetAmount ?? 0.0;
      if (g.deadline != null && target > 0) {
        final daysLeft = g.deadline!.difference(DateTime.now()).inDays;
        final remaining = target - g.currentAmount;
        if (daysLeft > 0 && remaining > 0) {
          final dailyNeeded = remaining / daysLeft;
          insights.add(AiInsight(
            id: 'goal-${g.id}',
            title: '🎯 ${g.title}: ₹${dailyNeeded.toStringAsFixed(0)}/day needed',
            body: 'You need to save ₹${dailyNeeded.toStringAsFixed(0)} per day '
                'to reach ₹${target.toStringAsFixed(0)} by your deadline. '
                '$daysLeft days remaining.',
            severity: daysLeft < 30
                ? InsightSeverity.critical
                : InsightSeverity.info,
            relatedGoalId: g.id,
          ));
        }
      }
    }

    // ===== AI-Generated Insights (graceful fallback) =====
    try {
      final portfolioSummary = _buildPortfolioSummary(holdings);
      final goalsSummary = _buildGoalsSummary(goals);
      final aiInsights = await _ai.generateInsights(
        portfolioSummary: portfolioSummary,
        goalsSummary: goalsSummary,
      );

      for (int i = 0; i < aiInsights.length; i++) {
        final raw = aiInsights[i];
        insights.add(AiInsight(
          id: 'ai-${DateTime.now().millisecondsSinceEpoch}-$i',
          title: raw['title']?.toString() ?? 'AI Insight',
          body: raw['body']?.toString() ?? '',
          severity: _parseSeverity(raw['severity']?.toString()),
        ));
      }
    } catch (_) {
      // AI unavailable — rule-based insights are still shown
    }

    return insights;
  }

  InsightSeverity _parseSeverity(String? value) {
    switch (value) {
      case 'warning':
        return InsightSeverity.warning;
      case 'critical':
        return InsightSeverity.critical;
      case 'suggestion':
        return InsightSeverity.suggestion;
      default:
        return InsightSeverity.info;
    }
  }

  String _buildPortfolioSummary(List<Holding> holdings) {
    if (holdings.isEmpty) return 'Portfolio is empty.';

    final buffer = StringBuffer('Indian Portfolio Holdings:\n');
    double totalInvested = 0, totalCurrent = 0;
    final alloc = <String, double>{};

    for (final h in holdings) {
      buffer.writeln('- ${h.name} (${h.assetType.name}): '
          '${h.quantity} units @ avg ₹${h.avgBuyPrice.toStringAsFixed(2)}, '
          'current ₹${h.currentPrice.toStringAsFixed(2)}, '
          'return: ${h.returnPercent.toStringAsFixed(1)}%');
      totalInvested += h.investedValue;
      totalCurrent += h.currentValue;
      alloc[h.assetType.name] =
          (alloc[h.assetType.name] ?? 0) + h.currentValue;
    }

    buffer.writeln('\nTotal Invested: ₹${totalInvested.toStringAsFixed(0)}');
    buffer.writeln('Total Current: ₹${totalCurrent.toStringAsFixed(0)}');
    if (totalInvested > 0) {
      final overallReturn =
          ((totalCurrent - totalInvested) / totalInvested * 100);
      buffer.writeln(
          'Overall Return: ${overallReturn.toStringAsFixed(1)}%');
    }
    buffer.writeln('\nAsset Allocation:');
    for (final entry in alloc.entries) {
      final pct = totalCurrent > 0
          ? (entry.value / totalCurrent * 100).toStringAsFixed(1)
          : '0';
      buffer.writeln('  ${entry.key}: $pct%');
    }
    return buffer.toString();
  }

  String _buildGoalsSummary(List<Goal> goals) {
    if (goals.isEmpty) return 'No savings goals set.';

    final buffer = StringBuffer('Savings Goals:\n');
    for (final g in goals) {
      final target = g.targetAmount ?? 0.0;
      buffer.writeln('- ${g.title}: ₹${g.currentAmount.toStringAsFixed(0)} / '
          '₹${target.toStringAsFixed(0)} '
          '(${(g.progressPercent * 100).toStringAsFixed(0)}%)');
      if (g.deadline != null) {
        buffer.writeln(
            '  Deadline: ${g.deadline!.toIso8601String().split('T').first}');
      }
    }
    return buffer.toString();
  }
}
