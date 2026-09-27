String? resolveTransactionGoalId({
  required String? selectedGoalId,
  String? activeGoalId,
  bool defaultToActiveGoal = false,
}) {
  if (selectedGoalId != null) {
    return selectedGoalId;
  }

  if (defaultToActiveGoal) {
    return activeGoalId;
  }

  return null;
}
