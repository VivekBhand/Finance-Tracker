import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/app_providers.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final bool isSaving;

  const AddTransactionSheet({super.key, required this.isSaving});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late bool _isSaving;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customCategoryController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedGoalId;
  bool _customCategoryOpen = false;

  @override
  void initState() {
    super.initState();
    _isSaving = widget.isSaving;
    final activeGoal = ref.read(activeGoalProvider);
    _selectedGoalId = activeGoal?.id;
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
    ];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                    onTap: () => setState(() => _isSaving = true),
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
                    onTap: () => setState(() => _isSaving = false),
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
                ),
                items: goalOptions,
                onChanged: (value) => setState(() => _selectedGoalId = value),
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

                ref.read(transactionsProvider.notifier).addTransaction(
                  Transaction(
                    id: const Uuid().v4(),
                    goalId: _selectedGoalId,
                    amount: amount,
                    type: _isSaving ? TransactionType.saving : TransactionType.setback,
                    categoryId: _selectedCategoryId!,
                    note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
                  ),
                );

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
    );
  }
}
