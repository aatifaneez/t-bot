<#
  tbot.ps1 — convenience wrapper for running t-bot with the native Python venv.

  The Freqtrade venv lives OUTSIDE the repo (and OneDrive) to avoid sync churn:
      C:\Users\silve\venvs\t-bot

  Usage (from the repo root):
      .\scripts\tbot.ps1 version                # show freqtrade version
      .\scripts\tbot.ps1 download               # download 1y of 1h candles
      .\scripts\tbot.ps1 backtest               # backtest MomentumStrategy
      .\scripts\tbot.ps1 trade                  # START live PAPER trading (dry-run)
      .\scripts\tbot.ps1 raw <any freqtrade args...>

  Everything runs in DRY-RUN (paper) mode per user_data/config.json — no real orders.
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
$UserDir = Join-Path $RepoRoot "user_data"

if (-not (Test-Path $FT)) {
    Write-Error "Freqtrade not found at $FT. Install it first: `n  & '$Venv\Scripts\python.exe' -m pip install freqtrade"
    exit 1
}

switch ($Command) {
    "version"  { & $FT --version }
    "download" { & $FT download-data --config $Config --userdir $UserDir --timeframe 1h --days 365 }
    "backtest" { & $FT backtesting --config $Config --userdir $UserDir --strategy MomentumStrategy --timeframe 1h }
    "trade"    { & $FT trade --config $Config --userdir $UserDir --strategy MomentumStrategy --db-url "sqlite:///$UserDir\tradesv3.dryrun.sqlite" }
    "raw"      { & $FT @Rest }
    default    { Write-Host "Unknown command '$Command'. Use: version | download | backtest | trade | raw" }
}
