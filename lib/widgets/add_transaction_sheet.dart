import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/goal.dart';
import '../models/transaction.dart';
import '../providers/app_providers.dart';
import '../utils/transaction_goal_policy.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final bool isSaving;
  final Transaction? initialTransaction;

  const AddTransactionSheet({
    super.key,
    required this.isSaving,
    this.initialTransaction,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late bool _isSaving;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _goalSearchController = TextEditingController();
  final _goalNameController = TextEditingController();
  final _goalTargetController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedGoalId;
  String? _selectedGoalIcon;
  bool _customCategoryOpen = false;

  final List<String> _goalIcons = ['🎯', '💻', '🚗', '✈️', '🏠', '📱', '🎓', '💼', '🎁', '💰', '🧳', '🏖️'];

  Future<void> _createGoalFromName(String title, {String? targetAmountText}) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;
    if (_selectedGoalIcon == null || _selectedGoalIcon!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an icon for the new goal.')),
      );
      return;
    }

    final targetText = targetAmountText?.trim() ?? '';
    final parsedTarget = targetText.isEmpty ? null : double.tryParse(targetText);

    final newGoal = Goal(
      id: const Uuid().v4(),
      title: trimmedTitle,
      targetAmount: parsedTarget,
      iconPath: _selectedGoalIcon!,
    );

    await ref.read(goalsProvider.notifier).addGoal(newGoal);
    await ref.read(activeGoalIdProvider.notifier).setActiveGoal(newGoal.id);

    if (!mounted) return;
    setState(() {
      _selectedGoalId = newGoal.id;
      _selectedGoalIcon = null;
      _goalNameController.clear();
      _goalTargetController.clear();
    });
  }

  void _openGoalPickerDialog() {
    final goals = ref.read(goalsProvider);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredGoals = goals.where((goal) {
              final query = _goalSearchController.text.trim().toLowerCase();
              if (query.isEmpty) return true;
              return goal.title.toLowerCase().contains(query);
            }).toList();

            final draftTitle = _goalSearchController.text.trim();
            final canCreate = draftTitle.isNotEmpty;

            return AlertDialog(
              title: const Text('Find or add goal'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _goalSearchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search goals',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    if (filteredGoals.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('No matching goals yet.'),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredGoals.length,
                          itemBuilder: (context, index) {
                            final goal = filteredGoals[index];
                            return ListTile(
                              leading: Text(goal.iconPath ?? '🎯', style: const TextStyle(fontSize: 22)),
                              title: Text(goal.title),
                              trailing: Text(
                                '${goal.targetAmount != null ? goal.targetAmount!.toStringAsFixed(0) : 'No target'} goal',
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedGoalId = goal.id;
                                });
                                Navigator.of(dialogContext).pop();
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _goalNameController,
                      decoration: InputDecoration(
                        hintText: 'New goal name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _goalTargetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Target amount (optional)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Choose icon for new goal', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _goalIcons.map((icon) {
                        final isSelected = _selectedGoalIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            _selectedGoalIcon = icon;
                            setDialogState(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(icon, style: const TextStyle(fontSize: 22)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    if (canCreate || _goalNameController.text.trim().isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final name = (_goalNameController.text.trim().isNotEmpty
                                ? _goalNameController.text
                                : draftTitle)
                                .trim();
                            _createGoalFromName(name, targetAmountText: _goalTargetController.text);
                            Navigator.of(dialogContext).pop();
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text(
                            'Create ${(_goalNameController.text.trim().isNotEmpty ? _goalNameController.text.trim() : draftTitle).trim()}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _goalSearchController.clear();
      _selectedGoalIcon = null;
    });
  }

  @override
  void initState() {
    super.initState();
    final activeGoal = ref.read(activeGoalProvider);
    final initialTransaction = widget.initialTransaction;

    _isSaving = initialTransaction?.type == TransactionType.setback ? false : (widget.isSaving || initialTransaction == null);
    _selectedCategoryId = initialTransaction?.categoryId;
    _amountController.text = initialTransaction?.amount.toString() ?? '';
    _noteController.text = initialTransaction?.note ?? '';
    _selectedGoalId = initialTransaction != null
        ? initialTransaction.goalId
        : resolveTransactionGoalId(
            selectedGoalId: null,
            activeGoalId: activeGoal?.id,
            defaultToActiveGoal: _isSaving,
          );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _isSaving ? const Color(0xFF1BAA6A) : const Color(0xFFE26767);
    final bgColor = _isSaving ? const Color(0xFFEAF9F0) : const Color(0xFFFDECEC);

    final categoriesBox = ref.watch(categoriesBoxProvider);
    final allCategories = categoriesBox.values.toList();
    final goals = ref.watch(goalsProvider);
    final activeGoal = ref.read(activeGoalProvider);
    final goalOptions = [
      const DropdownMenuItem<String?>(value: null, child: Text('Overall savings')),
      ...goals.map((goal) => DropdownMenuItem<String?>(value: goal.id, child: Text(goal.title))),
      const DropdownMenuItem<String?>(value: '__new_goal__', child: Text('Add new goal...')),
    ];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final activeGoal = ref.read(activeGoalProvider);
                          setState(() {
                            _isSaving = true;
                            _selectedGoalId = resolveTransactionGoalId(
                              selectedGoalId: null,
                              activeGoalId: activeGoal?.id,
                              defaultToActiveGoal: true,
                            );
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isSaving ? const Color(0xFF1BAA6A) : Colors.grey.shade100,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'I Saved',
                            style: TextStyle(
                              color: _isSaving ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final activeGoal = ref.read(activeGoalProvider);
                          setState(() {
                            _isSaving = false;
                            _selectedGoalId = resolveTransactionGoalId(
                              selectedGoalId: null,
                              activeGoalId: activeGoal?.id,
                              defaultToActiveGoal: false,
                            );
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isSaving ? const Color(0xFFE26767) : Colors.grey.shade100,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'I Spent',
                            style: TextStyle(
                              color: !_isSaving ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (goals.isNotEmpty || activeGoal == null)
                  DropdownButtonFormField<String?>(
                    value: _selectedGoalId,
                    decoration: InputDecoration(
                      labelText: 'Goal',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    items: goalOptions,
                    onChanged: (value) {
                      if (value == '__new_goal__') {
                        _openGoalPickerDialog();
                        return;
                      }
                      setState(() => _selectedGoalId = value);
                    },
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: themeColor),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: themeColor),
                    border: InputBorder.none,
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: allCategories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == allCategories.length) {
                        return GestureDetector(
                          onTap: () => setState(() => _customCategoryOpen = !_customCategoryOpen),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.add, size: 28, color: Color(0xFF1E1E2D)),
                            ),
                          ),
                        );
                      }

                      final cat = allCategories[index];
                      final isSelected = _selectedCategoryId == cat.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = cat.id;
                            _customCategoryOpen = false;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? bgColor : Colors.white,
                            border: Border.all(
                              color: isSelected ? themeColor : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cat.icon),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  cat.name,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (_customCategoryOpen)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customCategoryController,
                          decoration: InputDecoration(
                            hintText: 'Custom category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final name = _customCategoryController.text.trim();
                          if (name.isEmpty) return;
                          final newId = 'custom-${DateTime.now().millisecondsSinceEpoch}';
                          final box = ref.read(categoriesBoxProvider);
                          final category = Category(
                            id: newId,
                            name: name,
                            icon: '✨',
                            colorHex: _isSaving ? '0xFF1BAA6A' : '0xFFE26767',
                            defaultAmount: 0,
                            isSetback: !_isSaving,
                          );
                          box.put(newId, category);
                          setState(() {
                            _selectedCategoryId = newId;
                            _customCategoryController.clear();
                            _customCategoryOpen = false;
                          });
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Note (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final amountText = _amountController.text.trim();
                    if (amountText.isEmpty) return;
                    final amount = double.tryParse(amountText);
                    if (amount == null || amount <= 0) return;
                    if (_selectedCategoryId == null) return;

                    final transaction = Transaction(
                      id: widget.initialTransaction?.id ?? const Uuid().v4(),
                      goalId: _selectedGoalId,
                      amount: amount,
                      type: _isSaving ? TransactionType.saving : TransactionType.setback,
                      categoryId: _selectedCategoryId!,
                      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
                      timestamp: widget.initialTransaction?.timestamp ?? DateTime.now(),
                    );

                    if (widget.initialTransaction != null) {
                      ref.read(transactionsProvider.notifier).updateTransaction(transaction);
                    } else {
                      ref.read(transactionsProvider.notifier).addTransaction(transaction);
                    }

                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
