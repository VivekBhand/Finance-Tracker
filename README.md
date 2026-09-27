# Micro-Savings Goal Tracker 🎯

A local-first Flutter app for tracking everyday savings, spending, and goals without the clutter of a traditional finance dashboard.

This version is built around a simple principle: your transaction history is the real source of truth. Every saving, spend, and goal reallocation updates the app in real time, while keeping the experience fast and lightweight.

## What this app does

- Tracks multiple savings goals at once
- Supports an overall savings view alongside goal-specific progress
- Lets goals be open-ended or include a target amount when needed
- Uses INR as the default currency experience
- Allows custom categories and quick category actions
- Exposes time-filtered history and daily/category analytics
- Lets users create new goals directly while adding a transaction
- Supports editing and reassigning previous transactions to a different goal

## Core experience

The app is intentionally designed around a goal-first but flexible workflow:

1. Create one or more goals with an icon and optional target.
2. Add daily saves or spends from the dashboard.
3. Choose whether the entry belongs to overall savings or a specific goal.
4. Review progress, history, and analytics by category and time period.
5. Edit older transactions when priorities or goal assignments change.

## Feature highlights

- Multi-goal tracking with progress percentages and visual indicators
- Goal cards for current progress, completion state, and open goals
- Overall savings overview at the top of the dashboard
- Quick-save / quick-spend actions with a polished bottom-sheet entry flow
- Goal search-and-create workflow directly from the transaction modal
- Custom categories for personal finance habits
- Time-range filters in the history screen
- Daily and category summaries for financial trends

## Tech stack

- Flutter
- Riverpod
- Hive
- fl_chart

## Architecture note

> Transactions remain the source of truth.
>
> Goal totals are derived from transaction records instead of duplicated state, which keeps the app accurate when entries are edited, reassigned, deleted, or moved between goals.

## Getting started

### Prerequisites

- Flutter SDK installed and configured on your machine

### Install and run

```bash
flutter pub get
flutter run
```

For a browser target you can use:

```bash
flutter run -d chrome
```

## Usage flow

1. Open the app and create a goal or goals.
2. Tap Save or Spend from the dashboard.
3. Choose a goal or mark the entry as overall savings.
4. Review the dashboard summary, goal cards, and recent activity.
5. Open history to filter and edit transaction entries.
6. Use analytics to monitor category and day-wise progress.

## Project goals

This app is meant to feel lightweight and useful for everyday money tracking, especially for people who want to:

- save in small, realistic steps
- organize money by goals without overcomplicating the flow
- keep everything local and private
- revisit historical entries without losing context

## Notes

The repository is designed for local-first personal finance tracking and does not depend on remote services or backend infrastructure.
