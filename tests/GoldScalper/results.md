# GoldScalper Optimization Results

Symbol: XAUUSD | Timeframe: M5 | Deposit: $1,000 | Leverage: 1:500 | Period: 2026.01.10 - 2026.04.10

## Summary

| Run | Net Profit | PF | WR | R:R | Max DD | Trades | Sharpe | What Changed |
|-----|-----------|-----|------|------|--------|--------|--------|-------------|
| 1 | $0.00 | - | - | - | - | 0 | - | v1.0 old POINT defaults (SL=50, TP=100) |
| 2 | $0.00 | - | - | - | - | 0 | - | Same issue |
| 3 | $0.00 | - | - | - | - | 0 | - | Same issue |
| 4 | $0.00 | - | - | - | - | 0 | - | Same issue |
| 5 | $0.00 | - | - | - | - | 0 | - | "invalid stops" — SL/TP still too small |
| 6 | +$17.33 | 1.30 | 48.15% | 1.41:1 | 0.82% | 216 | 32.54 | v1.0 Fixed SL=$0.50, TP=$1.00 |
| 7 | -$17.88 | 0.96 | 61.57% | 0.60:1 | 7.15% | 216 | -3.37 | v1.0 Fixed SL=$5, TP=$10 — trailing cuts profit |
| 8 | -$93.96 | 0.93 | 48.51% | 0.98:1 | 29.10% | 202 | -2.88 | v2.0 ATR mode SL=1.5, TP=3.0 — SL too wide |
| 9 | -$9.77 | 0.98 | 44.44% | 1.23:1 | 12.80% | 216 | -1.31 | Reduced: SL=0.5, TP=1.5 — near breakeven |
| **10** | **+$27.59** | **1.05** | **44.44%** | **1.32:1** | **8.97%** | **216** | **4.27** | **TP=1.0, Trail start=0.7 — first good ATR run** |
| 11 | +$11.38 | 1.02 | 43.52% | 1.33:1 | 10.35% | 216 | 1.71 | +SL cap $8, trail=0.4, BE=0.8 — worse |
| 12 | +$3.78 | 1.01 | 43.52% | 1.31:1 | 10.12% | 216 | 0.60 | SL cap $8 only — cap hurts |
| 13 | -$8.03 | 0.98 | 42.76% | 1.31:1 | 10.07% | 145 | -1.87 | +ADX≥20 — over-filtered (71 trades removed) |
| **14** | **+$45.39** | **1.10** | **44.55%** | **1.37:1** | **6.90%** | **202** | **7.66** | **ADX≥15 — best run** |

## Optimization Journey

### Phase 1: POINT Value Fix (Run 1-5)

**Problem:** XAUUSD on Exness uses `SYMBOL_POINT=0.001` (3-digit pricing). Original defaults had SL=50, TP=100 points — equivalent to $0.05 and $0.10, far below spread ($0.196).

**Fix:** Adjust all point-based defaults. SL=5000 ($5), TP=10000 ($10), MaxSpread=300.

**Lesson:** Always verify POINT value from OnInit log before trusting default parameters.

### Phase 2: Trailing Problem Discovery (Run 6-7)

**Run 6** (tight stops SL=$0.50, TP=$1.00): Profitable (+$17.33) but gains too small per trade.

**Run 7** (wide stops SL=$5, TP=$10): Good win rate (61.57%) but NET LOSS (-$17.88). Root cause: trailing/BE parameters cut winners short. Average win=$3.00 (from $10 TP) while average loss=$5.02 (full SL). Actual R:R=0.60:1 instead of intended 2:1.

**Lesson:** Fixed trailing parameters don't adapt to market volatility. Led to ATR-based design.

### Phase 3: ATR Mode — Finding Right Multipliers (Run 8-10)

**Run 8** (SL=ATR*1.5, TP=ATR*3.0): ATR(14) on M5 XAUUSD = $8-$13, so SL=$12-$20. Way too wide for scalping. Loss -$93.96, DD 29.10%.

**Run 9** (SL=ATR*0.5, TP=ATR*1.5): SL in scalping range ($4-$7). Near breakeven (-$9.77). R:R improved to 1.23:1. But TP too far — avg win $5.24 vs TP $12-$20 means trailing exits most trades before TP.

**Run 10** (SL=ATR*0.5, TP=ATR*1.0, Trail start=ATR*0.7): First profitable ATR run (+$27.59). TP reachable, trailing starts before TP to protect partial profits.

**Lesson:** ATR(14) on XAUUSD M5 is large ($8-$13). Use fractional multipliers (0.3-1.0), not whole numbers.

### Phase 4: Risk Management Tuning (Run 11-12)

**Run 11** (+SL cap $8, trail dist 0.3→0.4, BE trigger 0.7→0.8): Worse (+$11.38). Wider trail lost profit, delayed BE lost protection.

**Run 12** (SL cap $8 only, revert trail/BE): Still worse (+$3.78). Cap converted 2 would-be-winners into losses when ATR was high and wider SL was correct.

**Lesson:** Max SL cap is counterproductive — it prevents trades from surviving volatile moves that would have been winners. Trail distance ATR*0.3 and BE trigger ATR*0.7 are optimal.

### Phase 5: Signal Quality — ADX Filter (Run 13-14)

**Run 13** (ADX≥20): Over-filtered — removed 71 trades (33%) but removed more winners than losers. Win rate dropped.

**Run 14** (ADX≥15): Sweet spot — removed only 14 trades, mostly losers. Best result: +$45.39, PF=1.10, DD=6.90%.

**Lesson:** ADX≥20 is standard for forex but too aggressive for XAUUSD M5. ADX≥15 filters only truly sideways conditions.

## Optimal Parameters (Run 14)

```
=== Signal Settings ===
InpEmaFastPeriod       = 9        // EMA Fast (M5)
InpEmaSlowPeriod       = 21       // EMA Slow (M5)
InpEmaTrendFast        = 50       // EMA Trend Fast (M15)
InpEmaTrendSlow        = 200      // EMA Trend Slow (M15)
InpRsiPeriod           = 14       // RSI Period
InpRsiUpper            = 70       // RSI Upper
InpRsiLower            = 30       // RSI Lower
InpUseAdxFilter        = true     // ADX Filter ON
InpAdxPeriod           = 14       // ADX Period
InpAdxMinLevel         = 15       // ADX Min (skip if below)
InpAtrPeriod           = 14       // ATR Period
InpSlTpMode            = SLTP_ATR // ATR Mode
InpAtrSlMultiplier     = 0.5      // SL = ATR * 0.5
InpAtrTpMultiplier     = 1.0      // TP = ATR * 1.0
InpMaxSlPoints         = 0        // No SL cap
InpTakeProfit          = 10000    // Fixed TP (unused in ATR mode)
InpStopLoss            = 5000     // Fixed SL (unused in ATR mode)
InpCloseOnOpposite     = true

=== Risk Management ===
InpLotMode             = LOT_FIXED
InpFixedLot            = 0.01
InpRiskPercent         = 1.0
InpMaxOpenOrders       = 3
InpMaxSpread           = 300

=== Daily Drawdown ===
InpUseDailyDrawdown    = true
InpMaxDailyDDPercent   = 3.0
InpDDAction            = DD_STOP

=== Break Even ===
InpUseBreakEven        = true
InpBreakEvenTrigger    = 3000     // Fixed (unused in ATR mode)
InpBreakEvenProfit     = 500      // Fixed (unused in ATR mode)
InpAtrBeMultiplier     = 0.7      // BE trigger = ATR * 0.7
InpAtrBeProfitMultiplier = 0.1    // BE lock = ATR * 0.1

=== Trailing Stop ===
InpUseTrailingStop     = true
InpTrailingStart       = 4000     // Fixed (unused in ATR mode)
InpTrailingStep        = 1000     // Fixed (unused in ATR mode)
InpTrailingStop        = 3000     // Fixed (unused in ATR mode)
InpAtrTrailStartMultiplier = 0.7  // Trail start = ATR * 0.7
InpAtrTrailStopMultiplier  = 0.3  // Trail distance = ATR * 0.3
InpAtrTrailStepMultiplier  = 0.2  // Trail step = ATR * 0.2

=== Time Filter ===
InpUseTimeFilter       = true
InpTradeStartHour      = 8
InpTradeStartMinute    = 0
InpTradeEndHour        = 20
InpTradeEndMinute      = 0
InpCloseOutsideTime    = false

=== News Filter ===
InpUseNewsFilter       = true
InpNewsMinsBefore      = 30
InpNewsMinsAfter       = 15
InpNewsImpact          = NEWS_HIGH
InpCloseBeforeNews     = false

=== Debug ===
InpDebugMode           = true
```

## Parameter Change Log

| Parameter | Run 8 | Run 9 | Run 10 | Run 11 | Run 12 | Run 13 | Run 14 |
|-----------|-------|-------|--------|--------|--------|--------|--------|
| SL mult | 1.5 | **0.5** | 0.5 | 0.5 | 0.5 | 0.5 | 0.5 |
| TP mult | 3.0 | **1.5** | **1.0** | 1.0 | 1.0 | 1.0 | 1.0 |
| Max SL cap | - | - | - | **8000** | **8000** | **0** | 0 |
| BE trigger | 1.5 | **0.7** | 0.7 | **0.8** | **0.7** | 0.7 | 0.7 |
| BE profit | 0.3 | **0.1** | 0.1 | 0.1 | 0.1 | 0.1 | 0.1 |
| Trail start | 2.0 | **1.0** | **0.7** | 0.7 | 0.7 | 0.7 | 0.7 |
| Trail dist | 1.0 | **0.3** | 0.3 | **0.4** | **0.3** | 0.3 | 0.3 |
| Trail step | 0.5 | **0.2** | 0.2 | 0.2 | 0.2 | 0.2 | 0.2 |
| ADX filter | - | - | - | - | - | **≥20** | **≥15** |
| **Result** | **-$93.96** | **-$9.77** | **+$27.59** | **+$11.38** | **+$3.78** | **-$8.03** | **+$45.39** |

Bold = changed from previous run.

## Key Insights

1. **ATR multipliers must be fractional** — ATR(14) on XAUUSD M5 is $8-$13, not $1-$3 like forex pairs
2. **TP must be reachable** — If avg win << TP, trailing exits most trades; lower TP increases hit rate
3. **Trail start should equal or precede TP** — Trail start=0.7 with TP=1.0 protects partial profits
4. **Trail distance ATR*0.3 is optimal** — Tighter (0.3) locks profit; wider (0.4) lets winners reverse
5. **Max SL cap is counterproductive** — Prevents trades from surviving high-ATR moves that recover
6. **ADX threshold 15 not 20** — XAUUSD M5 has lower ADX range than forex; 20 over-filters
7. **BE trigger ATR*0.7 is optimal** — Earlier (0.7) protects; later (0.8) loses protection too often
