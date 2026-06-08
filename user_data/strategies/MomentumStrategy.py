# pragma pylint: disable=missing-docstring, invalid-name, too-few-public-methods
"""
MomentumStrategy — a deliberately simple trend/momentum strategy for t-bot.

Hypothesis (economically motivated, not data-mined):
    In a trending market, when short-term momentum overtakes long-term momentum
    (fast EMA crosses above slow EMA) and the asset is NOT already overbought,
    the trend tends to continue for a while. We ride it and exit when momentum
    rolls over (fast EMA crosses back below slow EMA) or a stop is hit.

Design notes (see PLAN.md / RESEARCH.md):
    * Only a handful of free parameters (EMA fast, EMA slow, RSI filter) to limit
      overfitting risk. One free parameter per ~200-500 trades is the target.
    * Indicators use only PAST data (no lookahead): every value on bar t is
      computed from candles <= t, and Freqtrade evaluates signals on closed candles.
    * This is a STARTING POINT to validate the pipeline (paper trading), NOT a
      proven edge. It must survive backtest + walk-forward before any real money.
"""

from datetime import datetime
from pandas import DataFrame

import talib.abstract as ta
import freqtrade.vendor.qtpylib.indicators as qtpylib
from freqtrade.strategy import IStrategy, IntParameter


class MomentumStrategy(IStrategy):
    INTERFACE_VERSION = 3

    # ----- Core config -----
    timeframe = "1h"
    can_short = False
    process_only_new_candles = True
    use_exit_signal = True
    exit_profit_only = False
    ignore_roi_if_entry_signal = False
    startup_candle_count: int = 60  # enough history for the slow EMA + RSI

    # ----- Risk / exit defaults (overridable, kept conservative) -----
    # Staged take-profit: the longer we hold, the lower the profit we accept.
    minimal_roi = {
        "0": 0.10,    # take 10% immediately if we get it
        "240": 0.05,  # after 4h, accept 5%
        "720": 0.02,  # after 12h, accept 2%
        "1440": 0.0   # after 24h, exit at break-even+
    }

    # Hard stop-loss: cap the loss on any single trade.
    stoploss = -0.08

    # Trailing stop to lock in gains once a trade moves our way.
    trailing_stop = True
    trailing_stop_positive = 0.02
    trailing_stop_positive_offset = 0.04
    trailing_only_offset_is_reached = True

    # ----- Tunable parameters (few, stable) -----
    ema_fast = IntParameter(8, 20, default=12, space="buy", optimize=True)
    ema_slow = IntParameter(21, 50, default=26, space="buy", optimize=True)
    buy_rsi_max = IntParameter(55, 80, default=70, space="buy", optimize=True)

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        # Momentum: fast & slow EMAs (use the .value so hyperopt can tune them)
        dataframe["ema_fast"] = ta.EMA(dataframe, timeperiod=int(self.ema_fast.value))
        dataframe["ema_slow"] = ta.EMA(dataframe, timeperiod=int(self.ema_slow.value))

        # Overbought/oversold filter
        dataframe["rsi"] = ta.RSI(dataframe, timeperiod=14)

        # Volatility (informational / future ATR-based sizing)
        dataframe["atr"] = ta.ATR(dataframe, timeperiod=14)

        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe.loc[
            (
                # fast EMA crosses ABOVE slow EMA -> momentum turning up
                (qtpylib.crossed_above(dataframe["ema_fast"], dataframe["ema_slow"]))
                # not already overbought
                & (dataframe["rsi"] < int(self.buy_rsi_max.value))
                # there is actual volume (avoid dead/illiquid candles)
                & (dataframe["volume"] > 0)
            ),
            ["enter_long", "enter_tag"],
        ] = (1, "ema_cross_up")

        return dataframe

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe.loc[
            (
                # fast EMA crosses BELOW slow EMA -> momentum rolling over
                (qtpylib.crossed_below(dataframe["ema_fast"], dataframe["ema_slow"]))
                & (dataframe["volume"] > 0)
            ),
            ["exit_long", "exit_tag"],
        ] = (1, "ema_cross_down")

        return dataframe

    def custom_stoploss(
        self,
        pair: str,
        trade,
        current_time: datetime,
        current_rate: float,
        current_profit: float,
        after_fill: bool,
        **kwargs,
    ) -> float:
        # Keep the static stoploss; placeholder for future ATR-based stops.
        return self.stoploss
