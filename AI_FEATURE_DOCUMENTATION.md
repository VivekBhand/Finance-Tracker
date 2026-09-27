# Technical Documentation: AI Architecture & Implementation

This document details the complete technical implementation of the AI features for the **Smart Finance Tracker**.

---

## 1. On-Device PII Sanitization Engine (`lib/services/pii_sanitizer.dart`)

The `PiiSanitizer` class performs regex replacement directly on the client device before any string is transmitted to the cloud API.

### Regex Specifications:
* **PAN Card:** `[A-Z]{5}[0-9]{4}[A-Z]` $\to$ `[PAN_REDACTED]`
* **Aadhaar:** `\b\d{4}\s?\d{4}\s?\d{4}\b` $\to$ `[AADHAAR_REDACTED]`
* **Account Number:** `\b\d{9,18}\b` $\to$ `[ACCT_REDACTED]`
* **Indian Mobile:** `(?:\+91|0)?[6-9]\d{9}` $\to$ `[PHONE_REDACTED]`
* **Email:** `[\w.+-]+@[\w-]+\.[\w.]+` $\to$ `[EMAIL_REDACTED]`
* **IFSC Code:** `[A-Z]{4}0[A-Z0-9]{6}` $\to$ `[IFSC_REDACTED]`

---

## 2. Document Parsing Pipeline (`lib/services/document_parser.dart`)

Handles file selection, format detection, and PDF/CSV parsing:
1. `extractFromDigitalPdf`: Uses `syncfusion_flutter_pdf` to extract vector text from PDF files. Accepts an optional password for password-protected bank/CAS statements.
2. `extractFromCsv`: Decodes UTF-8 bytes from bank CSV exports.
3. Passes extracted string through `PiiSanitizer.sanitize()`.

---

## 3. Keyless Market Data Service (`lib/services/nse_market_service.dart`)

Provides real-time asset pricing without requiring user API keys:
1. **NSE Equities:** Initial GET to `https://www.nseindia.com` to capture session cookie (`nsit`), followed by GET to `https://www.nseindia.com/api/quote-equity?symbol={SYMBOL}` with `User-Agent` and `Referer` headers.
2. **Mutual Funds:** GET to `https://api.mfapi.in/mf/{schemeCode}/latest` to extract current NAV.

---

## 4. Hybrid Insight Generator (`lib/services/insight_generator.dart`)

Generates static cards for the Portfolio screen:

### Rule-Based Engine (100% Offline):
- **Concentration Risk:** Any asset holding > 40% of net portfolio value $\to$ `warning` card.
- **Underperformance:** Asset return < -10% from purchase cost $\to$ `warning` card.
- **FD vs Inflation:** Fixed Deposit return < 6% $\to$ `suggestion` card.
- **Goal Pace:** Daily savings needed to meet active goal deadline $\to$ `info` / `critical` card.

### AI Engine (Hugging Face Backend):
- Transmits anonymized portfolio summary & goals summary to the HF Space `/parse` endpoint with task `generate_insights`.
- Parses returned JSON array into `AiInsight` models.

---

## 5. Hugging Face Space FastAPI Backend (`backend/`)

A Dockerized FastAPI application running **`Qwen/Qwen2.5-1.5B-Instruct-GGUF`** via `llama-cpp-python`:
- **`backend/app.py`**: FastAPI server exposing `/parse` (POST) and `/health` (GET).
- **`backend/Dockerfile`**: Slim Python 3.11 container with `llama-cpp-python` compilation.
- **`backend/requirements.txt`**: Package constraints.
- **`backend/README.md`**: 1-click deployment guide to Hugging Face Spaces free tier (2 vCPU, 16 GB RAM).
