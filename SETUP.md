# SETUP — environment, known issues, and baseline results

This documents how the bot was actually brought up on a **Windows 11** machine, the
gotchas we hit, and the first (honest) backtest result.

## Environment
- **OS:** Windows 11
- **Runtime:** native Python **3.12.10** venv at `C:\Users\silve\venvs\t-bot`
  (kept outside OneDrive to avoid sync churn).
- **Freqtrade:** 2026.5.1 · **ccxt:** 4.5.56 · **TA-Lib:** 0.6.8 (wheel, no compile needed).
- Driver script: `scripts\tbot.ps1`.

> Docker was the original plan but Docker Desktop crashed on startup on this machine,
> so we use the native venv instead. The `docker-compose.yml` is kept for portability.

## Known issues & fixes (important)

### 1. System Python 3.14 is too new
Freqtrade supports Python 3.10–3.13. The machine's default `python` is 3.14, which
fails to install Freqtrade. Fix: install Python 3.12 and build a dedicated venv.

### 2. `aiohttp` async DNS failure on Windows (`Could not contact DNS servers`)
Symptom: every exchange call failed with
`ExchangeNotAvailable ... ClientConnectorDNSError ... OSError: Could not contact DNS servers`,
**even though** `curl`/sync requests and `ccxt` **sync** calls worked fine.

Root cause: `aiohttp` was using the async **c-ares** resolver (via the optional
`aiodns` package), which couldn't read DNS config on this host. ccxt's async path
(which Freqtrade uses) therefore failed while the OS resolver worked.

**Fix:** remove the optional async resolver so aiohttp falls back to the OS resolver:
```powershell
& "C:\Users\silve\venvs\t-bot\Scripts\python.exe" -m pip uninstall -y aiodns pycares
```
After this, async market loading and data downloads work.

### 3. Exchange choice: Binance vs Kraken
- **Binance** supports fast bulk OHLCV history download and works from this host
  (the earlier "ExchangeNotAvailable" was the aiodns bug above, **not** geo-blocking).
- **Kraken** does *not* support bulk candle history download (`download-data` errors with
  "use `--dl-trades` instead", which is very slow). If you must use Kraken, expect slow
  trade-based downloads.
- Current config uses **Binance**, USDT pairs.

## Baseline backtest (honest result)

First run of `MomentumStrategy` (EMA crossover + RSI), 1h, 8 pairs, ~1 year
(2025-06-11 → 2026-06-09), $1000 sim wallet, max 3 open trades:

| Metric | Value |
|--------|-------|
| Trades | 642 |
| Total profit | **−41.7%** |
| Win rate | 37.7% |
| Sharpe (daily) | **−2.37** |
| Sortino | −3.19 |
| Max drawdown | 47.7% |

**Interpretation:** this naive momentum strategy **loses money** and **fails the
Stage 3 backtest gate** (see PLAN.md). This is the expected, normal outcome — most
simple strategies do not have an edge. It must **NOT** be traded with real money.
It is fine to paper-trade (dry-run) purely to validate the live infrastructure.

### Next steps to actually find an edge
1. Try a different, economically-motivated hypothesis (e.g. mean-reversion on majors).
2. Add a regime filter (e.g. only take momentum trades when above a long-term MA).
3. Walk-forward validate any candidate; reject if out-of-sample Sharpe collapses.
4. Only after a candidate survives backtest + walk-forward + weeks of paper trading
   should real capital (tiny) be considered.

*Informational and educational only. Not financial advice.*
