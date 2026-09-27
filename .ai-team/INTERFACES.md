# Interface Contracts

## Shared contracts required before parallel implementation

### Contract 1: Goal model contract
- Fields: id, title, targetAmount, currentAmount, deadline, iconPath
- Goal progress must be computed as clamped ratio of currentAmount / targetAmount
- currentAmount should reflect net transaction effect

### Contract 2: Transaction model contract
- Fields: id, goalId, amount, type, categoryId, note, timestamp
- type values: saving, setback
- signedAmount returns positive value for saving and negative value for setback

### Contract 3: Repository contract
Required operations:
- addGoal
- deleteGoal
- syncGoalAmount(goalId)
- readGoals
- addTransaction
- deleteTransaction
- recalculate progress from transaction list

### Contract 4: Provider contract
Required providers:
- hiveInitializerProvider
- goalsProvider
- transactionsProvider
- activeGoalProvider
- recentTransactionsProvider
- homeDashboardProvider

Behavior requirements:
- UI reads only from providers
- providers react to data mutations
- data changes must trigger immediate rebuilds of dependent widgets

### Contract 5: UI contract
- Home screen must watch activeGoalProvider and transaction-driven providers
- Dashboard must update immediately when a save/setback/delete occurs
- The visual progress ring must animate based on recomputed net goal progress

### Contract 6: Multi-goal selection contract
- The app must support multiple goals concurrently in storage and runtime state
- The active goal is identified by a selected goal id, not by the first goal in a list only
- Goal-related reads and writes must use the selected goal and not hard-code a single goal assumption
- Goal creation, deletion, and switching must maintain transaction integrity for all remaining goals

### Contract 7: Currency configuration contract
- There must be a central app currency preference stored locally and exposed through a provider or settings repository
- Amount formatting must use the configured currency code and consistent decimal behavior across dashboard, history, and analytics
- Default currency must be deterministic for first-run installs and remain stable if not changed

### Contract 8: Category analytics contract
- Category metadata must support analytics and quick-add tasks without UI-side assumptions
- Category totals must be derived from transaction records and grouped by category id/name
- Analytics must aggregate category totals across date and goal filters, not from cached UI widgets

### Contract 9: Trend and time-filter contract
- Analytics must expose day-wise totals for the selected goal/date window
- History must expose filtered transaction reads for defined periods (week, month, all, custom range)
- Filters must apply at the query/provider layer, not mutate the underlying transaction list

## Merge and review boundaries
- No shared file edits without contract agreement
- Changes must preserve the repository instructions and avoid destructive actions
- Findings require verification and evidence before accepting the fix
- Multi-goal, currency, and analytics changes must remain compatible with the transaction-first architecture
