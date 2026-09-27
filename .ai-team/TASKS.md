# Shared Task Ledger

## Team and roles
- Developer A: GitHub Copilot
- Developer B: Google Antigravity
- Repository: Finance Tracker
- Workflow rule: no app logic changes before interface agreement and task ledger approval

## Repository status snapshot
- Repo state at initialization: project root exists but is not a valid Git repository for branch/worktree creation
- This means the worktree-and-branch instruction cannot yet be executed until a valid Git repository is available
- Do not overwrite user changes or create destructive actions

## Required task reporting format
For every subtask, include:
- changed files
- summary
- commands executed
- test results
- known limitations
- branch or commit identifier

## Global review rules
- Independent review of actual diffs required
- Check correctness, maintainability, security, performance, regression risk, and test coverage
- Findings must include severity and evidence
- Maximum of two correction cycles per finding before escalation
- No success claim without valid verification output
- No merge, push, deploy, or destructive action without explicit human approval

## Main task decomposition

### Task 1: Establish repo workflow and collaboration contract
- Owner: Developer A
- Scope: create the shared task ledger, architecture context, and interface contracts
- Dependencies: repo inspection and guidance review
- Output: .ai-team/TASKS.md, .ai-team/ARCHITECTURE.md, .ai-team/INTERFACES.md
- Verification: file creation and review, no app code modifications

### Task 2: Foundation and architecture setup
- Owner: Developer B
- Scope: data model and storage foundation, Hive initialization, repository sync logic
- Dependencies: interface agreement with Developer A
- Files: lib/models/*.dart, lib/repositories/*.dart, lib/providers/app_providers.dart
- Verification: flutter analyze, flutter test, adapter generation if required

### Task 3: UI and state integration
- Owner: Developer A
- Scope: onboarding, dashboard, screens, widgets, provider integration
- Dependencies: agreed interfaces from Task 2
- Files: lib/app.dart, lib/main.dart, future screen/widget files
- Verification: flutter analyze, widget tests if present, smoke test or targeted run

### Task 4: History, analytics, and settings flows
- Owner: Developer A and Developer B (split by contract)
- Scope: detailed feature screens and persistence-driven analytics
- Dependencies: Task 2 and Task 3 interfaces
- Files: screen and analytics files, provider updates, repository extensions
- Verification: targeted widget tests and logic tests

### Task 5: Review and correction cycle
- Owner: both agents, evaluated independently
- Scope: actual diff review, bug findings, risk assessment, regression validation
- Dependencies: completed implementation tasks
- Verification: test reruns and evidence-based review comments

## File ownership map
- Developer A owns UI-oriented files and screen contracts
- Developer B owns model/repository/data-layer files and persistence contracts
- Shared contract files must be agreed before any parallel implementation

## Current status
- Task 1 in progress: workflow docs being established
- No app code modifications yet
- Git worktree creation remains blocked until a valid Git repository is present
- AGY delegation remains manual-only until an actual configured execution mechanism is available

## Notes
- preserve all current files and decisions
- do not overwrite user changes
- ensure every task includes validation evidence before completion

## Feature request plan: multiple goals, currency, richer categories, analytics, and time filters

### Requested scope
- Support multiple goals in a single app instance, not just a single active goal
- Add user-facing currency configuration and formatting for savings totals and history labels
- Expand category taxonomy beyond the current limited preset set
- Show category-based stats in analytics, not just aggregate totals
- Add day-wise savings trend support in analytics
- Add time-period filters for history entries

### Task ownership summary
- Developer A (Copilot): UI, analytics screens, history filters, dashboard interactions, onboarding and goal selection flows
- Developer B (Antigravity): persistence model, repository queries, provider contracts, analytics aggregation logic, currency/config persistence and migration safety

### Dependency map
- Task 1 (multi-goal model + list storage): must land before any UI can surface goal switching
- Task 2 (currency configuration): must be available before analytics/history formatting is finalized
- Task 3 (category taxonomy): required for both quick-add presets and category analytics
- Task 4 (analytics aggregation): depends on Task 1, Task 2, and Task 3
- Task 5 (history filter UI): depends on transaction query layer and analytics contract
- Task 6 (integration + regression review): depends on all above tasks

### Sequential vs concurrent work
Concurrent after interface agreement:
- Developer B: multi-goal persistence contract + repository query methods + category schema changes
- Developer A: dashboard goal selection UI + onboarding/goal creation updates
- Developer B: currency config storage + formatting helpers
- Developer A: analytics UI shell and history filter UX

Sequential / must wait for shared contracts:
- analytics breakdown rendering must wait for repository and provider aggregation outputs
- history filters must wait for filtered transaction query layer
- final app integration must wait for all revised contracts and tests

### Proposed task breakdown

#### Task F1 — Multi-goal model and repository contract
- Owner: Developer B
- Scope: support multiple goals, goal selection state, and repository methods for list reads, creation, deletion, and goal-by-id queries
- Files: lib/models/goal.dart, lib/repositories/goal_repository.dart, lib/providers/app_providers.dart
- Deliverables:
  - goal list state no longer assumes a single active goal
  - repository API exposes readGoals, getGoal, addGoal, deleteGoal, and goal-scoped transaction totals
  - selection state or provider contract for activeGoalId
- Acceptance criteria:
  - multiple goals can coexist without stale single-goal assumptions
  - deleting one goal does not corrupt remaining goals or their transaction totals
  - navigation and widgets can read activeGoalId and current goal data without hard-coded single-goal logic
- Tests:
  - multiple-goal creation and retrieval
  - deletion leaves unrelated goals intact
  - per-goal transaction aggregation stays correct

#### Task F2 — Currency configuration and formatting
- Owner: Developer B
- Scope: persist user currency preference and centralize formatting for amounts and analytics labels
- Files: lib/models/*.dart, lib/repositories/*.dart, lib/providers/app_providers.dart, any settings model if added
- Deliverables:
  - currency preference stored locally with default fallback
  - formatting helper used across dashboard/history/analytics
- Acceptance criteria:
  - all totals display according to the configured currency code
  - defaults remain deterministic for first-run users
  - formatting is consistent across screens and remains locale-safe
- Tests:
  - default currency initialization
  - currency switching updates formatted labels
  - zero/negative values format correctly

#### Task F3 — Expanded category taxonomy and quick-add presets
- Owner: Developer B
- Scope: broaden the preset set and make category metadata richer enough for category analytics
- Files: lib/models/category.dart, lib/providers/app_providers.dart, any category-related UI or presets
- Deliverables:
  - category metadata includes taxonomic fields needed for analysis and quick-add UI
  - seed data expands beyond current limited set
- Acceptance criteria:
  - quick-add chips show a wider and realistic category model
  - categories are stable and keyed by id
  - category analytics can aggregate by name/type without UI guessing
- Tests:
  - category seed loads only once and remains idempotent
  - category lookup by id works reliably
  - categories with isSetback and default amounts remain correctly typed

#### Task F4 — Analytics aggregation: category stats and day-wise trends
- Owner: Developer B, with Developer A review
- Scope: derive analytics totals from transactions instead of ad hoc widget logic
- Files: lib/repositories/goal_repository.dart, lib/providers/app_providers.dart, lib/screens/analytics_screen.dart
- Deliverables:
  - category breakdown provider or repository aggregation
  - daily savings trend provider for chosen date window
  - reusable analytics data contract for screen rendering
- Acceptance criteria:
  - analytics totals match raw transaction records
  - category bars reflect transaction sums by category for the selected goal/date range
  - daily trend uses date buckets and shows actual savings behavior
- Tests:
  - category totals sum correctly
  - daily trend buckets aggregate by date
  - selection filters produce the expected subset

#### Task F5 — History time-period filters and filtered transaction queries
- Owner: Developer A
- Scope: add date range or period filters to history and ensure filtered queries follow the repository contract
- Files: lib/screens/history_screen.dart, lib/providers/app_providers.dart, lib/repositories/goal_repository.dart
- Deliverables:
  - UI filter chips or selector for relevant periods (e.g. week, month, all, custom range)
  - filtered transactions provider derived from repository query layer
- Acceptance criteria:
  - history view responds correctly to period selection
  - filters do not mutate the underlying data set
  - selected period is reflected in visible totals and entries
- Tests:
  - week/month/all filtering returns the expected transaction subsets
  - custom date ranges are inclusive/exclusive as specified

#### Task F6 — Goal switcher and dashboard integration
- Owner: Developer A
- Scope: replace single-goal assumptions with a visible goal selector and multi-goal dashboard behavior
- Files: lib/screens/home_screen.dart, lib/widgets/goal_hero_card.dart, lib/app.dart, lib/screens/main_shell.dart, lib/screens/onboarding_screen.dart
- Deliverables:
  - goal list or selector in dashboard/onboarding flow
  - active goal changes update hero card and transaction edits
- Acceptance criteria:
  - user can switch between multiple goals without stale totals
  - the hero card reflects the selected goal only
  - save/spend actions attach to the active goal
- Tests:
  - selected goal state updates after switching
  - quick-add transactions route to the active goal

#### Task F7 — Integration, regression check, and review cycle
- Owner: both agents
- Scope: run targeted tests, verify analytics flows, and reconcile any contract drift
- Files: all modified files
- Deliverables:
  - final code review notes with severity and evidence
  - test results for data and UI flows
- Acceptance criteria:
  - no contradicting provider contracts
  - no stale single-goal assumptions remain in screens or widgets
  - relevant tests pass after integration
- Tests:
  - full flutter analyze
  - targeted flutter test suite for repository/provider behavior
  - UI smoke tests for goal switching and history filters

### File ownership map
- Developer A owns UI screens and widgets: lib/app.dart, lib/screens/*.dart, lib/widgets/*.dart
- Developer B owns data contracts and repository logic: lib/models/*.dart, lib/repositories/*.dart, lib/providers/*.dart
- Shared review contracts: .ai-team/TASKS.md, .ai-team/INTERFACES.md, .ai-team/ARCHITECTURE.md

### Reciprocal review assignments
- Developer A reviews Developer B work on data contracts, repository logic, and analytics providers
- Developer B reviews Developer A work on dashboard goal-switching, UI state flows, history filters, and analytics rendering
- Both review the final integration and test evidence before signoff

### Required completion tests
- flutter analyze
- flutter test
- targeted tests for multi-goal goal selection and transaction sums
- targeted tests for category aggregation and day-wise totals
- targeted tests for time-period history filters
- UI smoke checks for onboarding and dashboard workflows

### Handoff note for Antigravity
No direct AGY execution tool is configured in this workspace. The exact handoff prompt for Antigravity is:

"Please implement the persistence, repository, and provider work for the multi-goal / currency / category / analytics feature set in this Flutter app, using the contracts and sequencing defined in .ai-team/TASKS.md and .ai-team/INTERFACES.md. Start with the data model and repository changes only, keep the current single-active-goal architecture from being duplicated in the repository, and preserve transaction-as-source-of-truth semantics. Do not change the app UI before the repository and provider contracts are complete. Verify with flutter analyze and targeted flutter tests before reporting completion."

### Current status of the plan
- Planning complete; no application logic changes yet
- Waiting for approval before implementation begins
