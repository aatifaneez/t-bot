# t-bot

Research and an executable build plan for a realistic AI / algorithmic trading bot (crypto + stocks).

This repository is the output of a deep, multi-source, **adversarially fact-checked** research pass into how real trading bots actually work in 2025–2026, plus a step-by-step plan for building one honestly.

> **Read this first.** The most corroborated finding in the entire research (verified by primary academic sources) is blunt: **the hard part is not building the bot — it's not overfitting it.** 89–95% of retail traders lose money within a year, fewer than 1% of day traders are consistently profitable after fees, and backtest performance has *near-zero* predictive power for live returns. A high win rate is not even the right metric. Any bot promising "passive income," "set-and-forget," or "90%+ win rate" is lying. Treat your first bot as **education with a hard capital cap**, not an income plan.

## Contents

| File | What's in it |
|------|--------------|
| [RESEARCH.md](RESEARCH.md) | Full deep-research report: verified findings (with citations), refuted claims, caveats, sources, and methodology. |
| [PLAN.md](PLAN.md) | The executable, stage-by-stage build plan — tech stack, strategy selection, backtesting methodology, paper trading, risk management, live deployment, and crypto-vs-stocks differences. |

## The 60-second summary

- **Architecture** of every real bot = 4 modules: Data Handler → Signal Generator → Portfolio/Risk Manager → Execution Engine (event-driven).
- **Tools people actually use:** Freqtrade & Jesse (crypto), Backtrader / backtesting.py / vectorbt / QuantConnect-Lean (general), Hummingbot (market-making), ccxt / Alpaca / Interactive Brokers (connectivity).
- **What separates the rare winner from the losing majority** is *process discipline*, not a magic signal: strict information-set discipline (no lookahead), walk-forward / out-of-sample validation, minimal free parameters, realistic fee + slippage modeling, and honesty about expectations.
- **Recommended path:** start with crypto (free data/APIs, 24/7, Freqtrade dry-run), pick ONE simple strategy, backtest honestly, validate walk-forward, paper-trade for weeks, add hard risk limits, then go live tiny.

## Research methodology

Generated via a fan-out research harness: the question was decomposed into 5 search angles, searched in parallel across the web (incl. arXiv, practitioner blogs, GitHub, forums), top sources fetched and reduced to falsifiable claims, each top claim verified by a 3-vote adversarial panel (a claim needed 2/3 to be killed). 22 sources → 94 claims → 25 verified → 19 confirmed, 6 refuted.

---

*This repository is informational and educational. Nothing here is financial advice. Trading involves substantial risk of loss.*
