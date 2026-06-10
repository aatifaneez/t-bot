<#
  tbot.ps1 — convenience wrapper for running t-bot with the native Python venv.

  The Freqtrade venv lives OUTSIDE the repo (and OneDrive) to avoid sync churn:
      C:\Users\silve\venvs\t-bot

  Usage (from the repo root):
      .\scripts\tbot.ps1 version                # show freqtrade version
      .\scripts\tbot.ps1 download               # download 1y of 1h candles
      .\scripts\tbot.ps1 backtest               # backtest MomentumStrategy
      .\scripts\tbot.ps1 paper                  # START live PAPER trading + web dashboard
      .\scripts\tbot.ps1 stop                   # stop a running bot (frees port 8080)
      .\scripts\tbot.ps1 trade                  # paper trading WITHOUT the dashboard
      .\scripts\tbot.ps1 raw <any freqtrade args...>

  `paper` is the recommended way to run: it loads both config.json (strategy/exchange)
  and config.private.json (web dashboard + market orders), so you get the FreqUI
  dashboard at http://127.0.0.1:8080. Run it in a terminal you keep OPEN — closing the
  window (or Ctrl+C) stops the bot.

  Everything runs in DRY-RUN (paper) mode — no real orders, no API keys, no real money.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$ErrorActionPreference = "Stop"
$Venv = "C:\Users\silve\venvs\t-bot"
$FT = Join-Path $Venv "Scripts\freqtrade.exe"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Config = Join-Path $RepoRoot "user_data\config.json"
$Private = Join-Path $RepoRoot "user_data\config.private.json"
$PrivateExample = Join-Path $RepoRoot "user_data\config.private.example.json"
$UserDir = Join-Path $RepoRoot "user_data"
$DbUrl = "sqlite:///$UserDir\tradesv3.dryrun.sqlite"

if (-not (Test-Path $FT)) {
    Write-Error "Freqtrade not found at $FT. Install it first: `n  & '$Venv\Scripts\python.exe' -m pip install freqtrade"
    exit 1
}

function Ensure-PrivateConfig {
    if (-not (Test-Path $Private)) {
        if (Test-Path $PrivateExample) {
            Copy-Item $PrivateExample $Private
            Write-Host "Created user_data\config.private.json from the example template."
            Write-Host "IMPORTANT: edit it and change jwt_secret_key / ws_token / password before exposing the UI." -ForegroundColor Yellow
        } else {
            Write-Error "Missing $Private and no example template found."
            exit 1
        }
    }
}

switch ($Command) {
    "version"  { & $FT --version }
    "download" { & $FT download-data --config $Config --userdir $UserDir --timeframe 1h --days 365 }
    "backtest" { & $FT backtesting --config $Config --userdir $UserDir --strategy MomentumStrategy --timeframe 1h }
    "trade"    { & $FT trade --config $Config --userdir $UserDir --strategy MomentumStrategy --db-url $DbUrl }
    "paper"    {
        Ensure-PrivateConfig
        Write-Host "Starting PAPER trading with dashboard -> http://127.0.0.1:8080" -ForegroundColor Green
        Write-Host "Keep this window open; press Ctrl+C to stop." -ForegroundColor Green
        & $FT trade --config $Config --config $Private --userdir $UserDir --strategy MomentumStrategy --db-url $DbUrl
    }
    "stop"     {
        $conns = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
        if ($conns) { $conns | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }; Write-Host "Stopped bot on port 8080." }
        else { Write-Host "No bot listening on port 8080." }
    }
    "raw"      { & $FT @Rest }
    default    { Write-Host "Unknown command '$Command'. Use: version | download | backtest | paper | stop | trade | raw" }
}
