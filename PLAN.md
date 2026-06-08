# Executable Build Plan — Realistic Trading Bot

The goal of this plan is **not** "get rich." It is: build a bot that is *honestly tested*, *cannot blow up your account*, and gives you a real shot at a small edge — while you learn enough to know whether you actually have one. Treat the first run as **education with a hard capital cap**.

See [RESEARCH.md](RESEARCH.md) for the evidence behind every choice below.

---

## Guiding principles (the part that actually matters)

1. **Win rate is not the goal — expectancy is.** `Expectancy = (Win% × AvgWin) − (Loss% × AvgLoss)`. A 40% win rate with 3:1 winners beats a 90% win rate that gives back everything on the tail.
2. **Your backtest number is nearly worthless on its own.** It has near-zero predictive power for live returns. The validation process is the product.
3. **Assume any edge you find is overfitting until walk-forward proves otherwise.** Repeatedly killing your own strategies in Stage 3 is the system *working*, not failing.
4. **Survive first.** Hard risk limits and tiny capital keep you in the game long enough to keep testing. The rare winners are the ones who didn't blow up.

---

## Recommended tech stack

| Layer | Choice | Why |
|-------|--------|-----|
| Language | **Python 3.11+** | Ecosystem standard |
| Framework | **Freqtrade** (start here) or custom `ccxt` + `vectorbt` + `pandas` | Freqtrade = data + backtest + dry-run + live in one config, fastest honest path |
| Crypto exchange | Binance / Kraken / Coinbase via **ccxt** | Free data, dry-run first |
| Stocks (later) | **Alpaca** (free paper API) → **Interactive Brokers** | Free paper trading, then production |
| Data | Exchange OHLCV (crypto, free); Alpaca/IBKR (stocks) | — |
| Infra | Local first → small cloud VM near the exchange for live | Lower latency, always-on |
| Notifications | Telegram / email | Every fill + every error |

**Why start with crypto:** free data and APIs, 24/7 markets, Freqtrade dry-run built in, and **no Pattern-Day-Trader rule**. Port to stocks once the process is proven.

---

## Stage 0 — Setup & data *(week 1)*
- [ ] Install Freqtrade in a virtualenv; verify it runs.
- [ ] Download 2–3 years of historical OHLCV for ~10 liquid pairs.
- [ ] **Reserve the most recent 6–12 months as out-of-sample and do not look at it** until Stage 3. (This single discipline prevents the most common form of self-deception.)

## Stage 1 — Pick ONE simple strategy *(week 1–2)*
- [ ] Choose **one** economically-motivated hypothesis. Good starters:
  - **Momentum / trend** — e.g. moving-average crossover + ATR trailing stop. Low win rate, positive expectancy.
  - **Mean-reversion** — e.g. Bollinger/RSI on range-bound majors.
- [ ] **No machine learning yet.** ML massively increases overfitting risk; earn it later.
- [ ] Keep it to **2–4 parameters** (≈ one free parameter per 200–500 expected trades).

## Stage 2 — Backtest honestly *(week 2–3)*
- [ ] Run Freqtrade backtesting with **realistic fees** and **liquidity-scaled slippage** (crypto tiers: ~0.05–0.1% BTC/ETH, 0.1% top-10, 0.3–0.5% top-100, 1–3% beyond).
- [ ] Verify **no lookahead bias**: every signal uses only data available *at that bar*.
- [ ] Record **Sharpe, max drawdown, expectancy** as headline metrics — *not* win rate.

## Stage 3 — Walk-forward validation *(week 3–4)* — the make-or-break gate
- [ ] Run walk-forward: rolling **6-month train / 1-month test** windows.
- [ ] Finally test on the reserved out-of-sample window.
- [ ] **Kill criteria** — abandon the strategy and return to Stage 1 with a *different* hypothesis if:
  - Out-of-sample Sharpe drops **>30–50%** vs in-sample, OR
  - A **10% parameter tweak flips** profitability, OR
  - Out-of-sample isn't clearly profitable after costs.
- [ ] Expect to loop here several times. That is normal and correct.

## Stage 4 — Paper trade live *(4–8 weeks minimum)*
- [ ] Run Freqtrade **dry-run** against live market data.
- [ ] This catches what backtests can't: real spreads, latency, partial fills, API errors, downtime.
- [ ] Compare live-paper results to backtest. **Large divergence = a bug or a hidden bias** — fix before proceeding.

## Stage 5 — Risk management layer *(before any real money)*
Enforce in code, not in discipline:
- [ ] Per-trade risk **≤ 1%** of capital; size positions off ATR / stop distance.
- [ ] **Daily loss limit / kill-switch** that flattens positions and halts the bot.
- [ ] Max concurrent positions and max total exposure caps.
- [ ] Alerting on every fill and every error.
- [ ] Graceful handling of exchange downtime / API errors / reconnects.

## Stage 6 — Live, tiny *(ongoing)*
- [ ] Fund with capital you would be **fine losing entirely** (e.g. $100–500).
- [ ] Run for months. Judge on **realized expectancy and drawdown vs. paper**.
- [ ] Scale **only** if: live tracks paper *and* paper tracked backtest.
- [ ] **Re-validate periodically** — edges decay; markets are non-stationary.

---

## Crypto vs. stocks — differences that matter

| | Crypto | Stocks |
|---|---|---|
| Data / API | Free, abundant (ccxt) | Often paid; Alpaca free tier is decent |
| Hours | 24/7 — bot must be always-on & resilient | Market hours + halts |
| Fees | ~0.1%/side typical; funding on perps | Often $0 commission, but spread/regulatory fees |
| Rules | Largely unregulated; custody/exchange risk | **PDT rule**: <$25k = max 3 day-trades / 5 days |
| Slippage | Wide on alts, tight on majors | Tight on large-caps, wide on small-caps |
| Custody risk | You hold keys / trust the exchange | Broker-held, SIPC-style protections |

---

## Honest expectation-setting

Given the verified research, the **most likely outcome of your first bot is that Stage 3 kills your strategy repeatedly** — and that is the process working as designed. Fewer than 1% of active retail traders are consistently profitable after fees, and backtest performance barely predicts live results. Plan for the value being **a rigorous, repeatable process** (and a real understanding of market microstructure), with profit as a low-probability upside. The people who eventually find a small edge are the ones who survived long enough — by not blowing up — to keep testing.

---

## Suggested repository structure (when you start coding)

```
t-bot/
├── README.md
├── RESEARCH.md
├── PLAN.md
├── config/              # Freqtrade configs (dry-run, live)
├── strategies/          # one Python class per strategy hypothesis
├── data/                # downloaded OHLCV (gitignored)
├── backtests/           # results, walk-forward reports
├── notebooks/           # exploration, analysis
└── risk/                # position sizing, kill-switch, limits
```

---

*Informational and educational only. Not financial advice. Trading involves substantial risk of loss.*
