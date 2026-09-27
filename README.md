# Micro-Savings Goal Tracker 🎯

A local-first, highly reactive Flutter application designed to help you reach your big financial goals through everyday micro-decisions.

Traditional budgeting apps focus on monthly bills. This app focuses entirely on the *micro-choices* you make throughout the day. Skipped a $5 coffee? Add it as a **Save**. Gave in to a $10 impulse snack? Log it as a **Setback**. 

By tracking these small daily choices, you build accountability and actually see how your everyday habits affect your long-term goals.

## ✨ Features
* **Multi-Goal Tracking:** Manage multiple savings goals simultaneously (e.g., "MacBook Pro", "Japan Trip", "Emergency Fund").
* **Gamified Micro-Savings:** Quickly log "+" Saves and "-" Setbacks using one-tap customizable category chips.
* **Reactive Dashboard:** A beautiful hero progress ring that updates instantly as you log transactions, showing exact amounts and percentage to completion.
* **Offline-First Persistence:** Built on **Hive NoSQL**. Your data never leaves your device and requires zero internet connection.
* **Analytics & Insights:** Interactive donut charts (`fl_chart`) break down your savings and spending habits by category.
* **Full History Ledger:** Chronological transaction history with swipe-to-delete functionality that instantly recalculates your net goal progress.

## 🏗️ Architecture & Tech Stack
* **Framework:** Flutter (Channel stable, 3.29+)
* **State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
* **Local Storage:** [Hive](https://pub.dev/packages/hive) (Explicit manual `TypeAdapter`s for stability)
* **Charting:** [fl_chart](https://pub.dev/packages/fl_chart)

### Core State Philosophy
> **"Transactions are the Source of Truth"**
> The app never relies on stale cached goal totals. The current amount saved for any goal is dynamically calculated on the fly from the raw transaction logs. When a transaction is deleted, the repository cascades the recalculation flawlessly.

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.

### Installation
1. Clone the repository.
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application (Web, Android, iOS, or Windows Desktop):
   ```bash
   flutter run -d chrome
   ```

## 📸 Usage Workflow
1. **Onboarding:** Set up your very first target (e.g., $1,500).
2. **Dashboard:** Tap **+ Save** or **- Spend** to open the transaction entry sheet.
3. **Analytics:** Navigate to the middle tab to see your visual breakdown.
4. **Settings:** Switch between active goals or adjust your global currency preference.
