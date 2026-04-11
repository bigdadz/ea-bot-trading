# CLAUDE.md

## Project Overview

GoldScalper EA — MQL5 Expert Advisor for scalping XAUUSD (Gold) on MetaTrader 5. Uses multi-timeframe EMA crossover + RSI filter with full risk management, trailing stop, news/time filters, and on-chart dashboard.

## Tech Stack

- **Language:** MQL5 (MetaTrader 5)
- **Standard Library:** `Trade/Trade.mqh`, `Trade/PositionInfo.mqh`
- **APIs:** MQL5 Economic Calendar (`CalendarValueHistory`)
- **Account Type:** Hedging

## Architecture

Modular design: one orchestrator EA file + 8 independent include modules. All communication flows through the main EA — no cross-dependencies between modules.

```
Experts/GoldScalper/GoldScalper.mq5    # Main EA orchestrator (OnInit/OnTick/OnDeinit)
Include/GoldScalper/
├── Defines.mqh          # Enums, constants, all 36 input parameters
├── SignalManager.mqh    # EMA crossover + RSI signal detection (M5/M15)
├── TradeManager.mqh     # Order execution via CTrade (open/close/count)
├── RiskManager.mqh      # Lot calculation (fixed/percent) + daily drawdown
├── TrailingManager.mqh  # Break even + trailing stop management
├── TimeFilter.mqh       # Trading hours restriction
├── NewsFilter.mqh       # Economic calendar news filter (USD)
└── Dashboard.mqh        # On-chart OBJ_LABEL display
```

## Key Conventions

- **XAUUSD Point Values:** Exness uses `SYMBOL_POINT=0.001` (3-digit pricing). All point-based parameters must account for this: 1000 points = $1.00. A $5 SL = 5000 points. Spread of 196 pts = $0.196.
- **MQL5 only:** Do not use `#property strict` (MQL4 only). Use string literals in `#property copyright`, not macros.
- **Include paths:** Use angle brackets `#include <GoldScalper/...>` (references MQL5 Include directory)
- **Header guards:** `#ifndef FILENAME_MQH` pattern in all `.mqh` files
- **Input parameters:** All centralized in `Defines.mqh`, prefixed with `Inp` (e.g., `InpStopLoss`)
- **Class naming:** `C` prefix (e.g., `CSignalManager`, `CTradeManager`)
- **Magic number:** `EA_MAGIC = 202604110` — filters EA's own orders from other EAs
- **Commit style:** `feat:` / `fix:` / `docs:` prefix with descriptive message

## OnTick Execution Flow

1. Time Filter → block if outside trading hours
2. News Filter → block if near USD news events
3. Daily Drawdown → block if loss limit exceeded
4. Trailing/Break Even management (always runs)
5. Signal detection → lot sizing → open trade
6. Dashboard update

## Deployment

1. Copy `Experts/GoldScalper/` to `MQL5/Experts/` in MT5 data folder
2. Copy `Include/GoldScalper/` to `MQL5/Include/`
3. Compile in MetaEditor (F7)
4. Attach to XAUUSD M5 chart

## Gotchas

- **Strategy Tester caches inputs** — Changing defaults in code doesn't auto-update Strategy Tester. User must right-click Inputs tab → Reset.
- **Economic Calendar unavailable in backtest** — `CalendarValueHistory` returns 0 events in Strategy Tester. News filter effectively disabled during backtesting.
- **Spread on XAUUSD** — Typical spread is 150-300 points ($0.15-$0.30). MaxSpread=300 covers normal conditions. SL/TP must exceed spread to avoid "invalid stops".
- **Debug logging** — Use new-bar detection (`IsNewBar()`) to log once per M5 bar, not every tick. Toggle via `InpDebugMode`.

## Design Docs

- Spec: `docs/superpowers/specs/2026-04-11-gold-scalper-design.md`
- Plan: `docs/superpowers/plans/2026-04-11-gold-scalper.md`
