# Smart AI Finance Tracker 🎯🤖

A local-first, privacy-guaranteed Flutter app for tracking micro-savings, managing portfolio wealth, ingesting financial statements via AI, and receiving static investment insight cards — at **$0 infrastructure cost**.

---

## 🌟 What's New: AI & Smart Portfolio Features

- **🤖 Self-Hosted Free AI Backend**: Powered by **Qwen2.5-1.5B-Instruct** running on a free Hugging Face Space (FastAPI + Docker). No user API keys or registration required.
- **🛡️ On-Device PII Protection**: Redacts sensitive personal information (PAN, Aadhaar, Bank Account #s, Phone Numbers, Emails, IFSC) on your device *before* any text leaves your phone.
- **📄 Document Ingestion Engine**: Parses CAMS/KFintech CAS PDFs and Bank CSV statement exports with password decryption support.
- **📈 Keyless Indian Market Data**: Fetches live NSE stock prices (`nseindia.com`) and AMFI mutual fund NAVs (`api.mfapi.in`) for free without any API keys.
- **💡 Hybrid Static AI Insights**: Displays color-coded cards on your portfolio dashboard for concentration risk (>40%), underperforming assets (>10% loss), FD vs inflation warnings, and goal daily savings pace.
- **💼 Total Net Worth Dashboard**: Tracks your micro-savings goals alongside equities, mutual funds, FDs, gold, PPF, and bonds.

---

## Core Experience & Feature Highlights

- **Multi-goal tracking** with progress percentages and visual progress rings
- **Overall savings overview** alongside goal-specific tracking
- **Quick-save / quick-spend actions** with customized categories
- **Interactive Analytics** featuring `fl_chart` donut and daily savings bar charts
- **Chronological History Ledger** with swipe-to-delete and instant goal recalculation
- **Portfolio & Net Worth View** with live gain/loss badges (`+14.2%` green / `-11.5%` red)
- **Document Upload** view with live PII sanitization preview

---

## 🏗️ Tech Stack

- **Frontend**: Flutter 3.29, Riverpod, Hive NoSQL, `fl_chart`, `syncfusion_flutter_pdf`, `csv`, `dio`
- **Backend (Optional AI)**: Python 3.11, FastAPI, `llama-cpp-python`, Docker, Hugging Face Spaces (CPU Basic)
- **Market Feeds**: NSE India Direct API (Cookie handshake), AMFI API (`mfapi.in`)

---

## 🔒 Architecture Note: Source of Truth & Privacy

> **Transactions & Holdings are the Source of Truth.**
> 
> Goal totals and net worth values are dynamically derived from raw transaction logs and holding records. 
> 
> **Privacy Guarantee**: All PDF/CSV text extraction and regex PII redaction occur 100% on-device. Your unredacted financial documents never touch any server.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.

### Install & Run
```bash
flutter pub get
flutter run
```

For web target:
```bash
flutter run -d chrome
```

---

## 🤖 Deploying Your Own Free AI Backend (Hugging Face)

The app connects to a free, public Hugging Face Space by default. To host your own private endpoint:
1. Go to [huggingface.co/spaces](https://huggingface.co/spaces) $\to$ **New Space**.
2. Select **Docker SDK** $\to$ **CPU Basic (Free 16 GB RAM)**.
3. Upload the contents of the `backend/` folder (`app.py`, `Dockerfile`, `requirements.txt`).
4. Paste your Space URL (`https://<username>-finance-ai.hf.space`) into the app's **Settings** screen.

---

## 🧪 Verification & Tests

- **Static Analysis**: `flutter analyze` $\to$ **0 issues**
- **Unit Tests**: `flutter test` $\to$ **12/12 passed**
- **Git Branch**: `feature/ai`
