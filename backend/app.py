import json
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from llama_cpp import Llama

app = FastAPI(title="Finance AI Parser")

# Load Qwen2.5-1.5B-Instruct Q4_K_M (fits easily in 16GB RAM)
llm = Llama.from_pretrained(
    repo_id="Qwen/Qwen2.5-1.5B-Instruct-GGUF",
    filename="qwen2.5-1.5b-instruct-q4_k_m.gguf",
    n_ctx=8192,
    n_threads=2,
    verbose=False,
)

HOLDINGS_PROMPT = """You are a financial document parser for Indian investments.
Extract ALL holdings from the document text.
Output valid JSON only with key "holdings" as a list of objects:
- name: string (scheme name, stock name, or asset title)
- assetType: string (equity | mutualFund | fixedDeposit | gold | ppf | bond | other)
- quantity: number (units or shares held)
- avgBuyPrice: number (average cost per unit in INR)
- currentPrice: number (current NAV or market price in INR, 0 if unknown)
- symbol: string or null (NSE ticker symbol, e.g. TCS, RELIANCE)
- isin: string or null (ISIN code, e.g. INE467B01029)
- folioNumber: string or null (mutual fund folio number)
- amcName: string or null (AMC name e.g. HDFC Mutual Fund)
- investedValue: number (total cost)
- currentValue: number (total market value, 0 if unknown)
Only extract explicitly stated data. Never hallucinate values."""

TRANSACTIONS_PROMPT = """You are a bank statement parser for Indian bank accounts.
Extract ALL transactions from the document text.
Output valid JSON only with key "transactions" as a list of objects:
- date: string (YYYY-MM-DD format)
- narration: string (clean description/counterparty name)
- type: string (CREDIT or DEBIT)
- amount: number (positive float in INR)
- category: string (inferred category like Groceries, Salary, Food, Utilities, Investment)
Only extract explicitly stated transactions."""

INSIGHTS_PROMPT = """You are a SEBI-registered investment advisor AI for Indian investors.
Analyze the portfolio and savings goals.
Output valid JSON only with key "insights" as a list of objects:
- title: string (short headline, e.g. "⚠️ High Equity Concentration")
- body: string (2-3 sentences in simple Hinglish/English explaining the advice)
- severity: string (info | suggestion | warning | critical)
- category: string (diversification | risk | performance | goal_alignment | tax)

Rules:
- Flag if >40% allocation is in a single stock or sector
- Flag negative returns >10%
- Suggest SIP if goal deadline is >2 years away
- Warn about FD returns vs inflation (~5-6% CPI)
- Never give buy/sell orders — only educational suggestions
- Always include a disclaimer that this is educational and not SEBI-registered financial advice."""


class ParseRequest(BaseModel):
    text: str
    task: str  # extract_holdings | extract_transactions | generate_insights
    context: str = ""


@app.post("/parse")
def parse_document(req: ParseRequest):
    prompts = {
        "extract_holdings": HOLDINGS_PROMPT,
        "extract_transactions": TRANSACTIONS_PROMPT,
        "generate_insights": INSIGHTS_PROMPT,
    }

    if req.task not in prompts:
        raise HTTPException(status_code=400, detail=f"Unknown task: {req.task}")

    user_content = f"{req.context}\n\n{req.text}" if req.context else req.text

    try:
        response = llm.create_chat_completion(
            messages=[
                {"role": "system", "content": prompts[req.task]},
                {"role": "user", "content": user_content},
            ],
            response_format={"type": "json_object"},
            temperature=0.1,
            max_tokens=2048,
        )

        return {"result": response["choices"][0]["message"]["content"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
def health():
    return {"status": "ok", "model": "Qwen2.5-1.5B-Instruct"}
