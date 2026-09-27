# Architecture Context

## Product summary
Micro-Savings Goal Tracker is a Flutter mobile app focused on helping users save toward large goals by recording everyday micro-savings and setbacks.

The app emphasizes:
- one active goal at a time
- immediate progress feedback
- transaction-based net progress calculation
- offline-first local persistence
- elegant, lightweight graphing and summary UI

## Core principle
The app should treat transactions as the primary source of truth.
Goal totals should be derived from transaction history instead of being treated as an independent, manually maintained value.

## Storage architecture
- Use Hive as the local offline database
- Store boxes for:
  - goals
  - transactions
  - categories
- Keep app functionality fully offline-first

## State architecture
- Use Riverpod for reactive state access and derived values
- Keep all provider reads reactive to the data layer
- Use providers such as:
  - hiveInitializerProvider
  - goalsProvider
  - transactionsProvider
  - activeGoalProvider
  - recentTransactionsProvider
  - homeDashboardProvider
- Use repository functions to centralize persistence/sync logic

## Data model rules
- Goal stores target and summary metadata
- Transaction stores each user event with signed net effect
- Category stores quick-add presets and display metadata
- Goal current amount must be recalculated or synchronized after any save or setback change

## UI flow
- First launch: onboarding and goal creation
- Home dashboard: hero progress card, quick actions, recent activity
- Add transaction sheet: save vs setback toggle, amount, category, optional note
- Analytics tab: trend and category breakdown
- History tab: grouped chronological list with delete support
- Settings: preferences and goal updates

## Safety and correctness rules
- Do not store duplicated totals without a sync mechanism
- Do not let widgets maintain stale local copies of computed totals
- Delete operations must recalculate the associated goal after mutation
- All validation must use actual test or analyzer output rather than assumptions

## Review and handoff expectations
- Separate work by file ownership and interface contract
- Do not parallelize tightly coupled tasks without agreed interfaces
- Review all diffs independently and confirm final behavior with evidence
