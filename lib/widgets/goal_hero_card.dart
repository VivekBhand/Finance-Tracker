import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class GoalHeroCard extends ConsumerWidget {
  const GoalHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(activeGoalProvider);

    if (goal == null) {
      final overallTotal = ref.watch(transactionsProvider).where((t) => t.goalId == null).fold<double>(0, (sum, item) => sum + item.signedAmount);
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall savings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              '₹${overallTotal.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'No goal selected yet — track overall progress or create a goal anytime.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final hasTarget = goal.targetAmount != null && goal.targetAmount! > 0;
    final progress = hasTarget ? (goal.currentAmount / goal.targetAmount!).clamp(0.0, 1.0) : 0.0;
    final percentage = hasTarget ? (progress * 100).round() : 0;
    final isComplete = goal.isCompleted;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactLayout = constraints.maxWidth < 460;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: useCompactLayout
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 150,
                        height: 150,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 14,
                                  backgroundColor: const Color(0xFFEAF9F0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF2ECF8F),
                                  ),
                                  strokeCap: StrokeCap.round,
                                ),
                                Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Column(
                                      key: ValueKey('${goal.currentAmount}-${goal.targetAmount ?? 'open'}'),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '₹${goal.currentAmount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E1E2D),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          hasTarget ? 'of ₹${goal.targetAmount!.toStringAsFixed(0)}' : 'target pending',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      goal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E2D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!hasTarget)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F6FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Open goal',
                          style: TextStyle(
                            color: Color(0xFF5967FF),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else if (isComplete)
                      AnimatedScale(
                        duration: const Duration(milliseconds: 400),
                        scale: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CC),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.emoji_events_rounded, size: 14, color: Color(0xFFF1B31C)),
                              SizedBox(width: 6),
                              Text(
                                'Goal complete!',
                                style: TextStyle(
                                  color: Color(0xFFF1B31C),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF9F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$percentage% complete',
                          style: const TextStyle(
                            color: Color(0xFF1BAA6A),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetricChip(
                          label: 'Saved',
                          value: '₹${goal.currentAmount.toStringAsFixed(0)}',
                        ),
                        _MetricChip(
                          label: hasTarget ? 'Left' : 'Status',
                          value: hasTarget
                              ? '₹${(goal.targetAmount! - goal.currentAmount).clamp(0.0, double.infinity).toStringAsFixed(0)}'
                              : 'Open',
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: value,
                                strokeWidth: 16,
                                backgroundColor: const Color(0xFFEAF9F0),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2ECF8F),
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                              Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Column(
                                    key: ValueKey('${goal.currentAmount}-${goal.targetAmount ?? 'open'}'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '₹${goal.currentAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E1E2D),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        hasTarget ? 'of ₹${goal.targetAmount!.toStringAsFixed(0)}' : 'target pending',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            goal.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1E2D),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (!hasTarget)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F6FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Open goal',
                                style: TextStyle(
                                  color: Color(0xFF5967FF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          else if (isComplete)
                            AnimatedScale(
                              duration: const Duration(milliseconds: 400),
                              scale: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3CC),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.emoji_events_rounded, size: 14, color: Color(0xFFF1B31C)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Goal complete!',
                                      style: TextStyle(
                                        color: Color(0xFFF1B31C),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF9F0),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$percentage% complete',
                                style: const TextStyle(
                                  color: Color(0xFF1BAA6A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _MetricChip(
                                label: 'Saved',
                                value: '₹${goal.currentAmount.toStringAsFixed(0)}',
                              ),
                              _MetricChip(
                                label: hasTarget ? 'Left' : 'Status',
                                value: hasTarget
                                    ? '₹${(goal.targetAmount! - goal.currentAmount).clamp(0.0, double.infinity).toStringAsFixed(0)}'
                                    : 'Open',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1E2D),
            ),
          ),
        ],
      ),
    );
  }
}
