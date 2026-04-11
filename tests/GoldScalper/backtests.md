# GoldScalper Backtest Results

Symbol: XAUUSD | Timeframe: M5 | Initial Deposit: $1,000.00 | Leverage: 1:500

## Summary

| Run | History Quality | Bars | Ticks | Total Trades | Net Profit | Profit Factor | Win Rate | Max DD | Notes |
|-----|----------------|------|-------|-------------|-----------|---------------|----------|--------|-------|
| 1 | 98% | 18998 | 36,107,423 | 0 | $0.00 | - | - | - | SL/TP too small (old POINT defaults) |
| 2 | 100% | 17344 | 33,644,220 | 0 | $0.00 | - | - | - | Same issue, 0 trades |
| 3 | 100% | 17344 | 33,644,220 | 0 | $0.00 | - | - | - | Same issue, 0 trades |
| 4 | 100% | 17344 | 33,644,220 | 0 | $0.00 | - | - | - | Same issue, 0 trades |
| 5 | 100% | 17344 | 33,644,220 | 0 | $0.00 | - | - | - | Signals fired but "invalid stops" |
| 6 | 100% | 17344 | 33,644,220 | 216 | +$17.33 | 1.30 | 48.15% | 0.82% | Tight stops, small profit |
| 7 | 100% | 17344 | 33,644,220 | 216 | -$17.88 | 0.96 | 61.57% | 7.15% | Good WR but trailing cuts profit |
| 8 | 100% | 17344 | 33,644,220 | 202 | -$93.96 | 0.93 | 48.51% | 29.10% | v2.00 ATR mode, SL too wide |
| 9 | 100% | 17344 | 33,644,220 | 216 | -$9.77 | 0.98 | 44.44% | 12.80% | ATR 0.5/1.5, near breakeven |

---

## Run 1 (v1.0 - Old POINT defaults)

| Metric | Value |
|--------|-------|
| History Quality | 98% |
| Bars | 18,998 |
| Ticks | 36,107,423 |
| Total Net Profit | $0.00 |
| Gross Profit | $0.00 |
| Gross Loss | $0.00 |
| Profit Factor | 0.00 |
| Recovery Factor | 0.00 |
| Sharpe Ratio | 0.00 |
| Expected Payoff | 0.00 |
| AHPR | 0.0000 (0.00%) |
| GHPR | 0.0000 (0.00%) |
| Balance Drawdown Absolute | $0.00 |
| Balance Drawdown Maximal | $0.00 (0.00%) |
| Balance Drawdown Relative | 0.00% ($0.00) |
| Equity Drawdown Absolute | $0.00 |
| Equity Drawdown Maximal | $0.00 (0.00%) |
| Equity Drawdown Relative | 0.00% ($0.00) |
| Margin Level | - |
| Z-Score | 0.00 (0.00%) |
| Total Trades | 0 |
| Total Deals | 0 |
| Short Trades (won %) | 0 (0.00%) |
| Long Trades (won %) | 0 (0.00%) |
| Profit Trades (% of total) | 0 (0.00%) |
| Loss Trades (% of total) | 0 (0.00%) |

**Problem:** SL=50, TP=100, MaxSpread=30 (old POINT defaults before fix). Values too small for XAUUSD POINT=0.001.

---

## Run 2

| Metric | Value |
|--------|-------|
| History Quality | 100% |
| Bars | 17,344 |
| Ticks | 33,644,220 |
| Total Net Profit | $0.00 |
| Profit Factor | 0.00 |
| Total Trades | 0 |
| Total Deals | 0 |
| Balance Drawdown Maximal | $0.00 (0.00%) |
| Equity Drawdown Maximal | $0.00 (0.00%) |

**Problem:** Same as Run 1 - SL/TP parameters too small, no trades executed.

---

## Run 3

| Metric | Value |
|--------|-------|
| History Quality | 100% |
| Bars | 17,344 |
| Ticks | 33,644,220 |
| Total Net Profit | $0.00 |
| Profit Factor | 0.00 |
| Total Trades | 0 |
| Total Deals | 0 |
| Balance Drawdown Maximal | $0.00 (0.00%) |
| Equity Drawdown Maximal | $0.00 (0.00%) |

**Problem:** Same as Run 1-2.

---

## Run 4

| Metric | Value |
|--------|-------|
| History Quality | 100% |
| Bars | 17,344 |
| Ticks | 33,644,220 |
| Total Net Profit | $0.00 |
| Profit Factor | 0.00 |
| Total Trades | 0 |
| Total Deals | 0 |
| Balance Drawdown Maximal | $0.00 (0.00%) |
| Equity Drawdown Maximal | $0.00 (0.00%) |

**Problem:** Same as Run 1-3.

---

## Run 5

| Metric | Value |
|--------|-------|
| History Quality | 100% |
| Bars | 17,344 |
| Ticks | 33,644,220 |
| Total Net Profit | $0.00 |
| Profit Factor | 0.00 |
| Total Trades | 0 |
| Total Deals | 0 |
| Balance Drawdown Maximal | $0.00 (0.00%) |
| Equity Drawdown Maximal | $0.00 (0.00%) |

**Problem:** Signals fired but all orders failed with "invalid stops". SL/TP values still too small (e.g. SL: 4742.717, TP: 4742.867 = $0.15 difference).

---

## Run 6 (Tight Stops - Small Profit)

| Metric | Value |
|--------|-------|
| History Quality | 100% |
| Bars | 17,344 |
| Ticks | 33,644,220 |
| **Total Net Profit** | **+$17.33** |
| Gross Profit | $74.46 |
| Gross Loss | -$57.13 |
| **Profit Factor** | **1.30** |
| Recovery Factor | 2.08 |
| **Sharpe Ratio** | **32.54** |
| Expected Payoff | $0.08 |
| AHPR | 1.0001 (0.01%) |
| GHPR | 1.0001 (0.01%) |
| LR Correlation | 0.81 |
| LR Standard Error | 3.59 |
| Balance Drawdown Absolute | $1.27 |
| Balance Drawdown Maximal | $7.77 (0.76%) |
| Balance Drawdown Relative | 0.76% ($7.77) |
| Equity Drawdown Absolute | $1.39 |
| **Equity Drawdown Maximal** | **$8.33 (0.82%)** |
| Equity Drawdown Relative | 0.82% ($8.33) |
| Margin Level | 9094.12% |
| Z-Score | -2.37 (98.22%) |
| OnTester Result | 0 |
| **Total Trades** | **216** |
| Total Deals | 432 |
| **Short Trades (won %)** | **77 (51.95%)** |
| **Long Trades (won %)** | **139 (45.04%)** |
| **Profit Trades (% of total)** | **104 (48.15%)** |
| **Loss Trades (% of total)** | **112 (51.85%)** |
| Largest profit trade | $1.09 |
| Largest loss trade | -$0.57 |
| Average profit trade | $0.72 |
| Average loss trade | -$0.51 |
| Maximum consecutive wins ($) | 7 ($6.30) |
| Maximum consecutive losses ($) | 7 (-$3.68) |
| Maximal consecutive profit (count) | $6.30 (7) |
| Maximal consecutive loss (count) | -$3.68 (7) |
| Average consecutive wins | 2 |
| Average consecutive losses | 2 |

**Settings:** SL=$0.50 (500 pts), TP=$1.00 (1000 pts). Tight stops with R:R=1:2.
**Analysis:** Marginally profitable. Low drawdown (0.82%). Avg win ($0.72) > Avg loss ($0.51) but win rate below 50%.

---

## Run 7 (Wide Stops - Net Loss)

| Metric | Value |
|--------|-------|
| History Quality | 100% |
| Bars | 17,344 |
| Ticks | 33,644,220 |
| **Total Net Profit** | **-$17.88** |
| Gross Profit | $399.06 |
| Gross Loss | -$416.94 |
| **Profit Factor** | **0.96** |
| Recovery Factor | -0.25 |
| **Sharpe Ratio** | **-3.37** |
| Expected Payoff | -$0.08 |
| AHPR | 0.9999 (-0.01%) |
| GHPR | 0.9999 (-0.01%) |
| LR Correlation | 0.09 |
| LR Standard Error | 18.89 |
| Balance Drawdown Absolute | $63.26 |
| Balance Drawdown Maximal | $65.46 (6.41%) |
| Balance Drawdown Relative | 6.42% ($64.23) |
| Equity Drawdown Absolute | $68.09 |
| **Equity Drawdown Maximal** | **$71.72 (7.15%)** |
| Equity Drawdown Relative | 7.15% ($71.72) |
| Margin Level | 8359.84% |
| Z-Score | 1.63 (89.69%) |
| OnTester Result | 0 |
| **Total Trades** | **216** |
| Total Deals | 432 |
| **Short Trades (won %)** | **77 (61.04%)** |
| **Long Trades (won %)** | **139 (61.87%)** |
| **Profit Trades (% of total)** | **133 (61.57%)** |
| **Loss Trades (% of total)** | **83 (38.43%)** |
| Largest profit trade | $10.05 |
| Largest loss trade | -$5.10 |
| Average profit trade | $3.00 |
| Average loss trade | -$5.02 |
| Maximum consecutive wins ($) | 8 ($23.74) |
| Maximum consecutive losses ($) | 5 (-$25.14) |
| Maximal consecutive profit (count) | $50.24 (6) |
| Maximal consecutive loss (count) | -$25.14 (5) |
| Average consecutive wins | 2 |
| Average consecutive losses | 1 |

**Settings:** SL=$5.00 (5000 pts), TP=$10.00 (10000 pts). Standard R:R=1:2.
**Analysis:** Good win rate (61.57%) but net loss. Trailing/BE cuts winners short: avg win=$3.00 (from $10 TP) while avg loss=$5.02 (full SL). Actual R:R=0.6:1 instead of intended 2:1. This led to implementing ATR-based dynamic SL/TP/Trailing (v2.00).

---

## Run 8 (v2.00 - ATR Mode)

| Metric | Value |
|--------|-------|
| History Quality | 100% |
| Bars | 17,344 |
| Ticks | 33,644,220 |
| Period | M5 (2026.01.10 - 2026.04.10) |
| Version | v2.00 (ATR-Based) |
| InpSlTpMode | 1 (ATR-Based) |
| ATR Period | 14 |
| ATR SL Multiplier | 1.5 |
| ATR TP Multiplier | 3.0 |
| ATR BE Trigger Multiplier | 1.5 |
| ATR BE Profit Multiplier | 0.3 |
| ATR Trail Start Multiplier | 2.0 |
| ATR Trail Stop Multiplier | 1.0 |
| ATR Trail Step Multiplier | 0.5 |
| **Total Net Profit** | **-$93.96** |
| Gross Profit | $1,211.07 |
| Gross Loss | -$1,305.03 |
| **Profit Factor** | **0.93** |
| Recovery Factor | -0.26 |
| **Sharpe Ratio** | **-2.88** |
| Expected Payoff | -$0.47 |
| AHPR | 0.9996 (-0.04%) |
| GHPR | 0.9995 (-0.05%) |
| LR Correlation | 0.01 |
| LR Standard Error | 83.44 |
| Balance Drawdown Absolute | $112.33 |
| Balance Drawdown Maximal | $328.61 (27.02%) |
| Balance Drawdown Relative | 27.02% ($328.61) |
| Equity Drawdown Absolute | $119.95 |
| **Equity Drawdown Maximal** | **$361.28 (29.10%)** |
| Equity Drawdown Relative | 29.10% ($361.28) |
| Margin Level | 3649.76% |
| Z-Score | -0.48 (36.88%) |
| OnTester Result | 0 |
| **Total Trades** | **202** |
| Total Deals | 404 |
| **Short Trades (won %)** | **73 (49.32%)** |
| **Long Trades (won %)** | **129 (48.06%)** |
| **Profit Trades (% of total)** | **98 (48.51%)** |
| **Loss Trades (% of total)** | **104 (51.49%)** |
| Largest profit trade | $97.71 |
| Largest loss trade | -$45.09 |
| Average profit trade | $12.36 |
| Average loss trade | -$12.55 |
| Maximum consecutive wins ($) | 8 ($103.70) |
| Maximum consecutive losses ($) | 6 (-$39.38) |
| Maximal consecutive profit (count) | $232.60 (4) |
| Maximal consecutive loss (count) | -$88.09 (5) |
| Average consecutive wins | 2 |
| Average consecutive losses | 2 |
| Min position holding time | 0:01:31 |
| Max position holding time | 2:51:27 |
| Avg position holding time | 0:36:40 |
| Correlation (Profits, MFE) | 0.737 |
| Correlation (Profits, MAE) | 0.422 |
| Correlation (MFE, MAE) | -0.141 |

**Settings:** v2.00 ATR mode. SL=ATR(14)*1.5, TP=ATR(14)*3.0. Dynamic trailing/BE from ATR multipliers.

**Observed ATR range:** $8-$13 (from log). Dynamic SL=$12-$20, TP=$24-$40.

**Analysis:**
- R:R balanced: avg win $12.36 vs avg loss $12.55 (ratio ~0.99:1) -- ATR trailing no longer cuts profit early
- But win rate dropped to 48.51% (from 61.57% in Run 7) -- not enough edge with balanced R:R
- Drawdown exploded to 29.10% (from 7.15% in Run 7) -- SL too wide for $1,000 account
- ATR(14) on XAUUSD M5 produces $8-$13 values, making SL=$12-$20 per trade -- swing trading, not scalping
- Largest win $97.71 shows big moves are captured, but losses also large ($45.09 max)

**Key finding:** ATR multiplier 1.5 is too high. ATR(14) on XAUUSD M5 already captures large volatility. Need lower multipliers (e.g., SL=ATR*0.5, TP=ATR*1.0) or shorter ATR period to keep SL in scalping range ($3-$5).

| Comparison | Run 6 (Fixed tight) | Run 7 (Fixed wide) | Run 8 (ATR 1.5/3.0) | Run 9 (ATR 0.5/1.5) |
|------------|--------------------|--------------------|---------------------|---------------------|
| Total Trades | 216 | 216 | 202 | 216 |
| Net Profit | +$17.33 | -$17.88 | -$93.96 | **-$9.77** |
| Profit Factor | 1.30 | 0.96 | 0.93 | **0.98** |
| Win Rate | 48.15% | 61.57% | 48.51% | 44.44% |
| Avg Win | $0.72 | $3.00 | $12.36 | **$5.24** |
| Avg Loss | $0.51 | $5.02 | $12.55 | **$4.27** |
| R:R (actual) | 1.41:1 | 0.60:1 | 0.98:1 | **1.23:1** |
| Max DD | 0.82% | 7.15% | 29.10% | **12.80%** |
| SL range | $0.50 | $5.00 | $12-$20 | **$4-$7** |
| Avg hold time | - | - | 0:36:40 | **0:06:52** |

---

## Run 9 (v2.00 - ATR Mode, Reduced Multipliers)

| Metric | Value |
|--------|-------|
| History Quality | 100% |
| Bars | 17,344 |
| Ticks | 33,644,220 |
| Period | M5 (2026.01.10 - 2026.04.10) |
| Version | v2.00 (ATR-Based) |
| InpSlTpMode | 1 (ATR-Based) |
| ATR Period | 14 |
| ATR SL Multiplier | **0.5** |
| ATR TP Multiplier | **1.5** |
| ATR BE Trigger Multiplier | **0.7** |
| ATR BE Profit Multiplier | **0.1** |
| ATR Trail Start Multiplier | **1.0** |
| ATR Trail Stop Multiplier | **0.3** |
| ATR Trail Step Multiplier | **0.2** |
| **Total Net Profit** | **-$9.77** |
| Gross Profit | $502.75 |
| Gross Loss | -$512.52 |
| **Profit Factor** | **0.98** |
| Recovery Factor | -0.07 |
| **Sharpe Ratio** | **-1.31** |
| Expected Payoff | -$0.05 |
| AHPR | 1.0000 (-0.00%) |
| GHPR | 1.0000 (-0.00%) |
| LR Correlation | -0.43 |
| LR Standard Error | 19.68 |
| Balance Drawdown Absolute | $55.65 |
| Balance Drawdown Maximal | $117.83 (11.09%) |
| Balance Drawdown Relative | 11.09% ($117.83) |
| Equity Drawdown Absolute | $59.16 |
| **Equity Drawdown Maximal** | **$138.05 (12.80%)** |
| Equity Drawdown Relative | 12.80% ($138.05) |
| Margin Level | 8862.74% |
| Z-Score | 1.77 (92.33%) |
| OnTester Result | 0 |
| **Total Trades** | **216** |
| Total Deals | 432 |
| **Short Trades (won %)** | **77 (45.45%)** |
| **Long Trades (won %)** | **139 (43.88%)** |
| **Profit Trades (% of total)** | **96 (44.44%)** |
| **Loss Trades (% of total)** | **120 (55.56%)** |
| Largest profit trade | $36.25 |
| Largest loss trade | -$13.19 |
| Average profit trade | $5.24 |
| Average loss trade | -$4.27 |
| Maximum consecutive wins ($) | 5 ($14.10) |
| Maximum consecutive losses ($) | 9 (-$31.98) |
| Maximal consecutive profit (count) | $60.33 (4) |
| Maximal consecutive loss (count) | -$50.67 (8) |
| Average consecutive wins | 2 |
| Average consecutive losses | 2 |
| Min position holding time | 0:00:05 |
| Max position holding time | 0:38:40 |
| Avg position holding time | 0:06:52 |
| Correlation (Profits, MFE) | 0.809 |
| Correlation (Profits, MAE) | 0.482 |
| Correlation (MFE, MAE) | 0.001 |

**Settings:** ATR mode with reduced multipliers: SL=ATR*0.5, TP=ATR*1.5 (R:R=1:3). Trail start=ATR*1.0, trail distance=ATR*0.3.

**Observed ATR range:** $8-$13. Dynamic SL=$4-$7, TP=$12-$20.

**Analysis:**
- **Best ATR run so far.** Near breakeven at -$9.77 (vs -$93.96 in Run 8)
- R:R favorable at **1.23:1** — avg win $5.24 > avg loss $4.27
- SL now in scalping range ($4-$7) — avg hold time 6:52 confirms true scalping
- Win rate dropped to 44.44% — with R:R 1.23:1, needs ~45% to be profitable
- Expected payoff -$0.05 per trade — almost zero edge, needs slight improvement
- Max drawdown 12.80% — much better than Run 8 (29.10%)
- Largest win $36.25 shows big moves still captured
- 9 consecutive losses observed — streak risk with tight SL

**Key insight:** R:R is now correct. The gap to profitability is ~1% win rate. Possible improvements:
1. Lower TP multiplier to 1.0 (R:R=1:2, should increase win rate)
2. Widen trailing distance (ATR*0.5 instead of 0.3) to let winners run longer
3. Tighten SL multiplier to 0.4 to reduce loss per trade
