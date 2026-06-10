# RUNBOOK — running t-bot (paper trading first)

There are two ways to run this bot. Pick ONE.

- **Option A — Native Python venv (current setup).** Python 3.12 venv at
  `C:\Users\silve\venvs\t-bot`, driven by `scripts\tbot.ps1`. Use this since Docker
  Desktop was crashing on this machine.
- **Option B — Docker** (the official Freqtrade image): no local Python/TA-Lib needed,
  but requires Docker Desktop to be working. See the Docker section below.

> **Current mode: DRY-RUN (paper trading).** `dry_run: true` in `user_data/config.json`.
> No real orders are sent and no API keys are required. It trades a simulated
> $1000 wallet against **live** Binance market data.

---

## Option A — Native Python venv (recommended here)

A helper script wraps the venv so you don't have to remember paths.

```powershell
# from the repo root
.\scripts\tbot.ps1 version     # confirm freqtrade is installed
.\scripts\tbot.ps1 download    # download ~1 year of 1h candles
.\scripts\tbot.ps1 backtest    # backtest MomentumStrategy (check Sharpe/drawdown/expectancy)
.\scripts\tbot.ps1 paper       # START live PAPER trading + web dashboard  <-- recommended
.\scripts\tbot.ps1 stop        # stop a running bot (frees port 8080)
```

### Watching it live (FreqUI dashboard)
`paper` enables the web dashboard. Open **http://127.0.0.1:8080** in your browser and
log in with the username/password from `user_data/config.private.json`. There you can
see open/closed trades, live P&L, charts, and use **Force enter / Force exit** buttons.

The first run of `paper` auto-creates `config.private.json` from
`config.private.example.json`. **Edit it and set your own `jwt_secret_key`, `ws_token`,
`username`, and `password`** (the real file is gitignored, so secrets never get committed).

### IMPORTANT: keep the bot alive
The bot only runs while its process is alive. Launch `paper` in a **terminal window you
keep open** — closing it (or `Ctrl+C`) stops the bot, and nothing trades while it's down.
For an overnight/multi-day paper test, leave that window running. (Background/agent-started
processes get cleaned up and will NOT keep running.)

To stop paper trading: `Ctrl+C` in the window, or `.\scripts\tbot.ps1 stop`.
Logs stream to the console; the dry-run trade DB is `user_data\tradesv3.dryrun.sqlite`.

If you ever need a raw freqtrade command:
```powershell
.\scripts\tbot.ps1 raw <any freqtrade args...>
```

---

## Option B — Docker

## Prerequisites
- Docker Desktop running.
- (Region note) If Binance market data is blocked where you are, change
  `exchange.name` in `user_data/config.json` to `kraken` or `coinbase` and adjust
  the `pair_whitelist` (e.g. `BTC/USD` instead of `BTC/USDT`).

## 1. Pull the image
```bash
docker compose pull
```

## 2. (Recommended) Download data + backtest before paper trading
The plan says validate before trusting it. Download history and run a backtest:
```bash
# download ~1 year of 1h candles for the whitelisted pairs
docker compose run --rm freqtrade download-data --timeframe 1h --days 365 --config /freqtrade/user_data/config.json

# backtest the strategy over that data
docker compose run --rm freqtrade backtesting --strategy MomentumStrategy --timeframe 1h --config /freqtrade/user_data/config.json
```
Read the output: focus on **profit, max drawdown, expectancy, Sharpe** — not win rate.

## 3. Start live paper trading (dry-run)
```bash
docker compose up -d
```
- Logs: `docker compose logs -f` (or see `user_data/logs/freqtrade.log`)
- Stop: `docker compose down`

## 4. Web UI (optional)
The REST API / FreqUI is exposed at <http://127.0.0.1:8080> (localhost only).
**Before exposing it, change** `jwt_secret_key`, `ws_token`, and `password` in the
`api_server` block of `config.json`.

## 5. Walk-forward validation (the make-or-break gate, see PLAN.md Stage 3)
```bash
docker compose run --rm freqtrade backtesting \
  --strategy MomentumStrategy --timeframe 1h \
  --timerange 20240101-20241231 \
  --config /freqtrade/user_data/config.json
```
Re-run across rolling windows and compare in-sample vs out-of-sample Sharpe.
If out-of-sample Sharpe drops >30–50%, the edge is likely overfit — go back to the
strategy and try a different hypothesis.

## Safety checklist before EVER going live with real money
- [ ] Backtested with realistic fees + slippage
- [ ] Survived walk-forward (out-of-sample Sharpe holds up)
- [ ] Paper-traded for several weeks; live-paper matches backtest
- [ ] Hard risk limits in place (per-trade ≤1%, daily loss kill-switch)
- [ ] API keys stored in a gitignored file, **withdrawal permission disabled**
- [ ] Start with capital you can afford to lose entirely

*Informational and educational only. Not financial advice.*
