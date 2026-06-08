# Deep Research Report

**Question:** How do real-world AI/algorithmic trading bots for stocks and crypto actually work in 2025–2026, and how do I build one? (Architecture, strategies, backtesting, execution, risk, live deployment; what practitioners say works vs. fails; realistic win rates; common pitfalls; tools people actually use.)

**Method:** 5 search angles → 22 sources fetched → 94 falsifiable claims extracted → top 25 verified by a 3-vote adversarial panel (2/3 needed to kill a claim) → **19 confirmed, 6 refuted** → merged and ranked.

---

## Executive summary

Real-world trading bots decompose into four modular, event-driven components: a **Data Handler** (market feeds, cleaning), a **Signal Generator** (strategy logic — momentum, mean-reversion, statistical arbitrage, market-making, or ML/deep-RL), a **Portfolio/Risk Manager**, and an **Execution Engine** that routes orders via broker APIs. The practitioner tooling is well-established: Backtrader, backtesting.py, vectorbt, zipline, and QuantConnect/Lean for general backtesting; Freqtrade and Jesse for crypto; Hummingbot for market-making.

The single most corroborated finding is that **the hard part is not building the bot but avoiding overfitting.** Rigorous walk-forward validation of microstructure signals delivered only ~0.55% annualized (Sharpe 0.33, not statistically significant); backtest Sharpe ratios have near-zero predictive power for live returns (Quantopian, n=888); and 89–95% of retail traders lose money, with under 1% of day traders profitable after fees. What separates the rare profitable bot from the losing majority is **process discipline**: strict information-set discipline (only data available up to each point in time), walk-forward/out-of-sample testing that flags >30–50% Sharpe decay, minimal free parameters (2–4 stable, ~one per 200–500 trades), realistic liquidity-scaled slippage and fee modeling, and honesty (any bot promising passive income, set-and-forget, or guaranteed 90%+ win rate is lying).

---

## Verified findings

### 1. Overfitting is the dominant failure mode of ML/data-driven bots — `high confidence` · vote 3–0
Models learn spurious historical patterns and fail out-of-sample and in live deployment. This is driven by multiple-testing / data-snooping across many strategies and parameters, which inflates apparent statistical significance. Confirmed across multiple primary academic sources, including deep-RL crypto bots whose reported backtest profits are often false positives.

> *Evidence:* arXiv 2602.00080 (GT-Score): ML systems "learn spurious patterns in historical prices and fail out of sample and in deployment… a multiple-testing/data-snooping problem that inflates apparent statistical significance." arXiv 2209.05559 (FinRL group): DRL methods "optimistically reported increased profits in backtesting, which may suffer from the false positive issue due to overfitting." Grounded in Bailey & López de Prado, Harvey & Liu 2016.
> *Sources:* arxiv.org/pdf/2602.00080 · arxiv.org/pdf/2209.05559

### 2. Impressive backtests fail live due to lookahead bias + in-sample optimization; the fix is information-set discipline + walk-forward — `high confidence` · vote 3–0
Features, signals, and execution decisions must use **only data available up to each point in time**. Overfitting is *detectable*: formulate it as a hypothesis test, estimate the probability of overfitting, and reject overfitted agents.

> *Evidence:* arXiv 2512.12924v1 (Texas Tech, Dec 2025) enforces "strict information set discipline… preventing lookahead bias"; cites McLean & Pontiff (97 predictors decline 26% out-of-sample, 58% post-publication) and >90% of academic strategies failing live. arXiv 2209.05559 formulates "the detection of backtest overfitting as a hypothesis test… and reject the overfitted agents."
> *Sources:* arxiv.org/html/2512.12924v1 · arxiv.org/pdf/2209.05559

### 3. Rigorous validation returns far below marketing claims; backtest Sharpe barely predicts live returns — `high confidence` · vote 3–0
Daily microstructure signals across 100 US equities (252-day train / 63-day test, 34 out-of-sample periods) yielded only **0.55% annualized, Sharpe 0.33, not statistically significant (p=0.34)** — versus commonly claimed 15–30% that "likely reflect data mining." Backtest Sharpe ratios have **essentially no predictive power** for live returns.

> *Evidence:* arXiv 2512.12924v1: "mean quarterly return of 0.14% (0.55% annualized) with Sharpe ratio 0.33… not statistically significant (p-value 0.34)." Quantopian study (Wiecki et al., *Journal of Investing* 2016, n=888): backtest Sharpe R² < 0.025 vs out-of-sample — "near-zero predictive power for live returns."
> *Sources:* arxiv.org/html/2512.12924v1 · tv-hub.org/guide/is-automated-trading-profitable

### 4. Anti-overfitting can be partially engineered into the objective (GT-Score) — `high confidence` · vote 3–0
The GT-Score nearly doubled the train-to-validation generalization ratio (0.365 vs 0.185 baseline, a 98% improvement) across 50 S&P 500 stocks (2010–2024, 9 walk-forward splits). **Caveat:** this is a *relative retention* improvement, not a deployability/profitability claim — the ratio stays below 1.0, so overfitting persists, and transaction costs were excluded from headline results.

> *Evidence:* arXiv 2602.00080 (also MDPI *J. Risk and Financial Management*, Jan 2026): "98% improvement in generalization ratio… strategies retain nearly twice as much of their training performance" — but the paper explicitly states this is "not a claim of deployability."
> *Sources:* arxiv.org/pdf/2602.00080

### 5. Canonical bot architecture = four modular components — `high confidence` · vote 3–0
**Data Handler** (feeds/cleans/structures tick or candle data) → **Signal Generator** (strategy logic and buy/sell triggers) → **Portfolio Manager** (exposure/allocation, often subsuming risk) → **Execution Engine** (sends/verifies orders via broker APIs). The canonical event-driven design.

> *Evidence:* etnasoft guide lists the four components verbatim; maps onto QuantStart's widely-cited reference architecture (DataHandler, Strategy, Portfolio, ExecutionHandler). *Caveat:* some designs break Risk Management and Monitoring into separate modules.
> *Sources:* etnasoft.com/programming-your-first-algo-trading-bot-a-step-by-step-guide/

### 6. The practitioner tooling is well-known and well-organized — `high confidence` · vote 3–0
- **General-purpose, event-driven (Python):** Backtrader, backtesting.py, zipline, QuantConnect/Lean.
- **Crypto-focused:** **Freqtrade** (free/open-source, GPLv3, founded 2017; strategies as Python classes using pandas/TA-Lib; built-in backtesting with historical download; ML hyperoptimization / FreqAI; free dry-run paper trading) and **Jesse** (advanced crypto strategy research).
- The ecosystem spans backtest+live, ML/RL frameworks, alpha generation, analytics, data sources, and broker APIs.

> *Evidence:* `awesome-systematic-trading` README organizes tooling into these categories; confirmed against primary repos (mementum/backtrader, freqtrade.io, jesse-ai/jesse). Freqtrade docs confirm historical download + backtest, Hyperopt for buy/sell/ROI/stop-loss, FreqAI, and dry-run using real market data.
> *Sources:* github.com/wangzhe3224/awesome-systematic-trading · gainium.io/compare/freqtrade-vs-hummingbot

### 7. Hummingbot is the purpose-built open-source market-making bot — `high confidence` · vote 2–1
Founded 2019, Apache 2.0, Python. Strategies: Pure Market Making, Avellaneda & Stoikov, custom MM, and cross-exchange market making (XEMM) arbitrage. Supports 40–50+ exchanges across CEX and DEX via Gateway middleware (broadest among open-source bots); $34B+ volume generated.

> *Evidence:* hummingbot.org brands itself "the open source framework for crypto market makers"; Pure Market Making, Avellaneda & Stoikov, and XEMM are documented official strategies. *Soft spot:* the "largest coverage" superlative — CCXT connects to 100+ exchanges but is a library, not a bot.
> *Sources:* gainium.io/compare/freqtrade-vs-hummingbot

### 8. Realistic profitability expectations are sobering — `high confidence` · vote 3–0
**89–95% of retail traders lose money within a year**; fewer than **1% of day traders** consistently profit after fees. Any bot promising passive income, set-and-forget, or guaranteed 90%+ win rate is dishonest. A high win rate is **not** the right metric — trend-following profits with low win rates.

> *Evidence:* tv-hub: "89–95% of retail traders lose money within a year," "<1% of day traders consistently earn profits after all fees" — corroborated by peer-reviewed Barber/Lee/Liu/Odean (Taiwan, ~0.22–0.9% profitable), Chague et al. (Brazil, 97% lost), and ESMA/NCA (74–89% of CFD accounts lose). powertrading: "Any bot promising passive income, set and forget, or 90%+ win rate guaranteed is lying."
> *Sources:* tv-hub.org/guide/is-automated-trading-profitable · powertrading.group/options-trading-blog/trading-bots-2026-what-works

### 9. Concrete overfitting-detection and robustness heuristics — `medium confidence` · vote 3–0 / 2–1
- Walk-forward analysis (e.g. 6-month train / 1-month test).
- Flag overfitting when **out-of-sample Sharpe drops >30–50%** from in-sample (or OOS decay > 50%).
- A usable strategy targets **Sharpe > 1.0** (>2.0 excellent).
- Keep free parameters minimal: **2–4 stable, ~one per 200–500 trades**. 5–10+ parameters, or a profitability flip from a 10% tweak, are red flags.

> *Evidence:* paybis: "Sharpe ratio drops by more than 30–50% from in-sample to out-of-sample signals overfitting… above 1.0 for a decent strategy, above 2.0 for excellent." Corroborated by arXiv 2105.01380 (OOS Sharpe ~0.57× in-sample). blofin: "5–10+ free parameters… OOS decay exceeding 50%… One free parameter per 200–500 trades."
> *Sources:* paybis.com/blog/how-to-backtest-crypto-bot/ · blofin.com/en/academy/education/automation-risk-in-crypto-bot · arxiv.org/pdf/2105.01380

### 10. Backtests must model realistic, liquidity-scaled slippage — `medium confidence` · vote 2–1
Crypto rough heuristics (small orders relative to daily volume): **~0.05–0.1%** for BTC/ETH under $50k, **0.1%** for top-10 coins, **0.3–0.5%** for top-100, **1–3%** outside the top 100. Slippage is heavily order-size dependent.

> *Evidence:* paybis: "BTC/ETH: 0.05–0.1% penalty per trade… Top 10: 0.1%… Top 100: 0.3–0.5%… Outside top 100: 1–3%." Corroborated by Kraken/Sei-type sources and BacktestMe (altcoin spreads 10–50× wider).
> *Sources:* paybis.com/blog/how-to-backtest-crypto-bot/

---

## Refuted claims (failed verification — treat skeptically)

These plausible-sounding, commonly-repeated numbers were **killed** by the adversarial panel:

| Claim | Vote |
|-------|------|
| "Live trading runs 30–50% below backtest, over-optimized strategies lose up to 80%." | 1–2 ✗ |
| "Underestimating fees is the **main** reason most crypto bots fail; backtests need ~100 trades for significance." | 0–3 ✗ |
| "Average retail crypto slippage is 0.1–0.6% per trade, exceeding 1.5% in volatility." | 1–2 ✗ |
| "Ignoring the six common biases overstates performance by 3–5×." | 0–3 ✗ |
| "~95% of bots marketed as 'AI'/'ML' are marketing gimmicks." | 0–3 ✗ |
| "Recommended build is a fixed 5-step pipeline (define → setup → data → backtest → connect API)." | 1–2 ✗ |

---

## Caveats

Source quality is **bimodal**. The strongest, unanimously verified findings (overfitting as the dominant failure mode, lookahead-bias discipline, near-zero predictive power of backtest Sharpe, the GT-Score result, sobering retail loss rates) rest on **primary academic preprints / peer-reviewed work** (arXiv 2512.12924, 2209.05559, 2602.00080, 2105.01380; Quantopian/*Journal of Investing*; Barber/Odean; ESMA).

The practical build heuristics (specific slippage tiers, the 30–50% Sharpe-decay rule, parameter-count rules of thumb) come from **vendor/marketing-adjacent blogs** (paybis, blofin, gainium) and should be treated as approximate rules of thumb — two were 2–1 split votes.

**Tooling facts are time-sensitive:** Backtrader development has slowed since ~2020, while Freqtrade / Hummingbot / Jesse remain actively maintained into 2026.

**Critically:** the verified corpus contains **NO evidence that any specific strategy reliably profits**. The verified profitability evidence points the opposite direction. The edge, if any, is in process discipline — not in a signal.

---

## Open questions (not resolved by the verified corpus)

1. What strategy categories do current X/Twitter and r/algotrading practitioners report as actually profitable in 2025–2026? (The corpus covered architecture, tooling, and overfitting rigorously but surfaced little attributable live-profitability testimony beyond loss statistics.)
2. Concrete stocks-vs-crypto execution differences in practice (Alpaca/IBKR vs ccxt connectivity, market hours, pattern-day-trader rules, funding rates, custody/regulatory risk)?
3. Realistic capital floor, latency, and infrastructure for market-making/HFT-adjacent strategies (Hummingbot/Avellaneda-Stoikov) to be net-profitable after fees/rebates, vs. retail-feasible lower-frequency strategies?
4. How well does the GT-Score / hypothesis-test overfitting-rejection methodology hold up under independent replication **with transaction costs included**, given the original papers disclaim deployability?

---

## Sources

**Primary (academic):**
- arXiv 2512.12924v1 — walk-forward microstructure validation (Texas Tech, Dec 2025)
- arXiv 2209.05559 — backtest overfitting as hypothesis test (FinRL group)
- arXiv 2602.00080 — GT-Score generalization (also MDPI *JRFM*, Jan 2026)
- arXiv 2105.01380 — out-of-sample Sharpe decay
- Wiecki et al., *Journal of Investing* 2016 (Quantopian, n=888)
- Barber/Lee/Liu/Odean (Taiwan); Chague et al. (Brazil); ESMA/NCA (CFD accounts)

**Secondary / practitioner:**
- github.com/wangzhe3224/awesome-systematic-trading
- freqtrade.io · jesse-ai/jesse · hummingbot.org · mementum/backtrader
- tv-hub.org/guide/is-automated-trading-profitable
- powertrading.group/options-trading-blog/trading-bots-2026-what-works
- paybis.com/blog/how-to-backtest-crypto-bot/
- blofin.com/en/academy/education/automation-risk-in-crypto-bot
- gainium.io/compare/freqtrade-vs-hummingbot
- etnasoft.com/programming-your-first-algo-trading-bot-a-step-by-step-guide/
- autotradelab.com (backtrader vs nautilus vs vectorbt vs zipline)
- alexbobes.com (freqtrade alternatives; "brutal truth about algorithmic trading")

**Methodology stats:** 5 angles · 22 sources fetched · 94 claims extracted · 25 verified · 19 confirmed · 6 killed · 104 agent calls.

---

*Informational and educational only. Not financial advice.*
