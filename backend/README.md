# Finance AI Parser Backend (Hugging Face Space)

A lightweight, zero-cost FastAPI backend running **Qwen2.5-1.5B-Instruct-GGUF** for financial document extraction and portfolio insight generation.

## 🚀 How to Deploy to Hugging Face Spaces (Free)

1. Log in to [Hugging Face](https://huggingface.co/) and click **New Space**.
2. Set Space Name: `finance-ai` (or any name you prefer).
3. Select License: **MIT**.
4. Select SDK: **Docker** → **Blank**.
5. Select Hardware: **CPU Basic · 2 vCPU · 16 GB RAM · Free**.
6. Clone your Space repository or upload the following files:
   - `app.py`
   - `requirements.txt`
   - `Dockerfile`
7. Click **Commit** — Hugging Face will automatically build and start the Docker container.
8. Once built, your Space endpoint is live at:
   `https://<your-hf-username>-finance-ai.hf.space`

## 📡 API Endpoints

### `GET /health`
Returns system status.
```json
{
  "status": "ok",
  "model": "Qwen2.5-1.5B-Instruct"
}
```

### `POST /parse`
Extract structured JSON from text.

#### Request Body:
```json
{
  "text": "Sanitized document text here...",
  "task": "extract_holdings",
  "context": ""
}
```

Tasks available:
- `extract_holdings`: Parses mutual funds, stocks, FDs, gold, bonds.
- `extract_transactions`: Parses bank statement debit/credit logs.
- `generate_insights`: Analyzes portfolio and goals to produce advisory cards.
