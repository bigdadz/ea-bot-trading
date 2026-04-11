# ATR-Based Dynamic SL/TP/Trailing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace fixed SL/TP/Trailing values with ATR-based dynamic calculation so the EA adapts to market volatility automatically.

**Architecture:** Add ATR indicator to SignalManager, compute dynamic SL/TP in the main EA before passing to TradeManager (unchanged), and pass ATR to TrailingManager for dynamic break-even/trailing. RiskManager's CalculateLot needs to accept dynamic SL instead of reading InpStopLoss directly.

**Tech Stack:** MQL5, MetaTrader 5 Standard Library (Trade/Trade.mqh, Trade/PositionInfo.mqh)

**Note:** MQL5 has no unit test framework. Verification is done by compilation in MetaEditor (F7) and backtesting in Strategy Tester. Code changes should be syntactically verified by review.

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `Include/GoldScalper/Defines.mqh` | Modify | Add ENUM_SLTP_MODE + 9 new input parameters |
| `Include/GoldScalper/SignalManager.mqh` | Modify | Add ATR indicator handle + GetATR() method |
| `Include/GoldScalper/TrailingManager.mqh` | Modify | Accept ATR parameter, compute dynamic BE/trailing |
| `Include/GoldScalper/RiskManager.mqh` | Modify | Accept slPoints parameter in CalculateLot() |
| `Include/GoldScalper/Dashboard.mqh` | Modify | Add ATR + dynamic SL/TP display |
| `Experts/GoldScalper/GoldScalper.mq5` | Modify | Orchestrate ATR flow, compute dynamic SL/TP |

Files NOT touched: `TradeManager.mqh`, `TimeFilter.mqh`, `NewsFilter.mqh`

---

### Task 1: Add ENUM and Input Parameters to Defines.mqh

**Files:**
- Modify: `Include/GoldScalper/Defines.mqh`

- [ ] **Step 1: Add ENUM_SLTP_MODE after existing enums (after line 38)**

After the `ENUM_SIGNAL` enum block, add:

```mql5
enum ENUM_SLTP_MODE
{
   SLTP_FIXED = 0,  // Fixed Points
   SLTP_ATR   = 1   // ATR-Based
};
```

- [ ] **Step 2: Add ATR and SL/TP Mode inputs to Signal Settings group**

After `InpRsiLower` (line 48) and before `InpTakeProfit` (line 49), add:

```mql5
input int              InpAtrPeriod        = 14;       // ATR Period
input ENUM_SLTP_MODE   InpSlTpMode         = SLTP_ATR; // SL/TP Mode (Fixed or ATR)
input double           InpAtrSlMultiplier  = 1.5;      // ATR x ? = Stop Loss
input double           InpAtrTpMultiplier  = 3.0;      // ATR x ? = Take Profit
```

- [ ] **Step 3: Add ATR multiplier inputs to Break Even group**

After `InpBreakEvenProfit` (line 71), add:

```mql5
input double InpAtrBeMultiplier       = 1.5;    // ATR x ? = BE Trigger (ATR mode)
input double InpAtrBeProfitMultiplier = 0.3;    // ATR x ? = BE Profit Lock (ATR mode)
```

- [ ] **Step 4: Add ATR multiplier inputs to Trailing Stop group**

After `InpTrailingStop` (line 78), add:

```mql5
input double InpAtrTrailStartMultiplier = 2.0;  // ATR x ? = Trail Start (ATR mode)
input double InpAtrTrailStopMultiplier  = 1.0;  // ATR x ? = Trail Distance (ATR mode)
input double InpAtrTrailStepMultiplier  = 0.5;  // ATR x ? = Trail Step (ATR mode)
```

- [ ] **Step 5: Commit**

```bash
git add Include/GoldScalper/Defines.mqh
git commit -m "feat: add ATR-based SL/TP input parameters and ENUM_SLTP_MODE"
```

---

### Task 2: Add ATR Indicator to SignalManager.mqh

**Files:**
- Modify: `Include/GoldScalper/SignalManager.mqh`

- [ ] **Step 1: Add ATR handle and buffer to private members (after line 17)**

After `int m_rsiHandle;` add:

```mql5
   int    m_atrHandle;          // ATR on M5
```

After `double m_rsi[];` add:

```mql5
   double m_atr[];
```

- [ ] **Step 2: Add public AtrValue member and GetATR method declaration**

After `bool TrendUp;` (line 33) add:

```mql5
   double AtrValue;
```

After the `ENUM_SIGNAL CheckSignal();` declaration (line 38) add:

```mql5
   double      GetATR();
```

- [ ] **Step 3: Create ATR handle in Init() method**

After the RSI handle creation (line 49):
```mql5
   m_rsiHandle          = iRSI(m_symbol, PERIOD_M5, InpRsiPeriod, PRICE_CLOSE);
```

Add:
```mql5
   m_atrHandle          = iATR(m_symbol, PERIOD_M5, InpAtrPeriod);
```

Update the INVALID_HANDLE check (line 51-54) to include ATR:

Replace:
```mql5
   if(m_emaFastHandle == INVALID_HANDLE || m_emaSlowHandle == INVALID_HANDLE ||
      m_emaTrendFastHandle == INVALID_HANDLE || m_emaTrendSlowHandle == INVALID_HANDLE ||
      m_rsiHandle == INVALID_HANDLE)
```

With:
```mql5
   if(m_emaFastHandle == INVALID_HANDLE || m_emaSlowHandle == INVALID_HANDLE ||
      m_emaTrendFastHandle == INVALID_HANDLE || m_emaTrendSlowHandle == INVALID_HANDLE ||
      m_rsiHandle == INVALID_HANDLE || m_atrHandle == INVALID_HANDLE)
```

After `ArraySetAsSeries(m_rsi, true);` (line 63) add:

```mql5
   ArraySetAsSeries(m_atr, true);
```

- [ ] **Step 4: Release ATR handle in Deinit()**

After `if(m_rsiHandle != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);` (line 75) add:

```mql5
   if(m_atrHandle != INVALID_HANDLE)          IndicatorRelease(m_atrHandle);
```

- [ ] **Step 5: Implement GetATR() method**

Add before `#endif` at the end of the file:

```mql5
//+------------------------------------------------------------------+
double CSignalManager::GetATR()
{
   if(CopyBuffer(m_atrHandle, 0, 1, 1, m_atr) < 1)
   {
      AtrValue = 0;
      return 0;
   }
   AtrValue = m_atr[0];  // ATR of last completed bar
   return AtrValue;
}
```

Note: Uses bar index 1 (last completed bar) to avoid unstable values from the forming bar.

- [ ] **Step 6: Commit**

```bash
git add Include/GoldScalper/SignalManager.mqh
git commit -m "feat: add ATR indicator handle and GetATR() to SignalManager"
```

---

### Task 3: Modify TrailingManager to Accept ATR

**Files:**
- Modify: `Include/GoldScalper/TrailingManager.mqh`

- [ ] **Step 1: Change ManageOrders signature to accept ATR**

Replace the declaration (line 30):
```mql5
   void ManageOrders();
```

With:
```mql5
   void ManageOrders(double atrValue = 0);
```

- [ ] **Step 2: Modify ApplyBreakEven to use dynamic values**

Replace the entire `ApplyBreakEven` method (lines 63-93) with:

```mql5
void CTrailingManager::ApplyBreakEven(ulong ticket, ENUM_POSITION_TYPE type, double openPrice)
{
   if(!InpUseBreakEven || IsBreakEvenApplied(ticket))
      return;

   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   double bid   = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double ask   = SymbolInfoDouble(m_symbol, SYMBOL_ASK);

   // Use ATR-based or fixed BE parameters
   double beTrigger = m_lastATR > 0
      ? m_lastATR * InpAtrBeMultiplier / point
      : InpBreakEvenTrigger;
   double beProfit = m_lastATR > 0
      ? m_lastATR * InpAtrBeProfitMultiplier / point
      : InpBreakEvenProfit;

   if(type == POSITION_TYPE_BUY)
   {
      if((bid - openPrice) >= beTrigger * point)
      {
         double newSL = NormalizeDouble(openPrice + beProfit * point, digits);
         double tp    = PositionGetDouble(POSITION_TP);
         if(m_trade.PositionModify(ticket, newSL, tp))
            MarkBreakEvenApplied(ticket);
      }
   }
   else if(type == POSITION_TYPE_SELL)
   {
      if((openPrice - ask) >= beTrigger * point)
      {
         double newSL = NormalizeDouble(openPrice - beProfit * point, digits);
         double tp    = PositionGetDouble(POSITION_TP);
         if(m_trade.PositionModify(ticket, newSL, tp))
            MarkBreakEvenApplied(ticket);
      }
   }
}
```

- [ ] **Step 3: Modify ApplyTrailingStop to use dynamic values**

Replace the entire `ApplyTrailingStop` method (lines 96-134) with:

```mql5
void CTrailingManager::ApplyTrailingStop(ulong ticket, ENUM_POSITION_TYPE type, double openPrice, double currentSL)
{
   if(!InpUseTrailingStop)
      return;

   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   double bid   = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double ask   = SymbolInfoDouble(m_symbol, SYMBOL_ASK);

   // Use ATR-based or fixed trailing parameters
   double trailStart = m_lastATR > 0
      ? m_lastATR * InpAtrTrailStartMultiplier / point
      : InpTrailingStart;
   double trailStop = m_lastATR > 0
      ? m_lastATR * InpAtrTrailStopMultiplier / point
      : InpTrailingStop;
   double trailStep = m_lastATR > 0
      ? m_lastATR * InpAtrTrailStepMultiplier / point
      : InpTrailingStep;

   if(type == POSITION_TYPE_BUY)
   {
      double profit = bid - openPrice;
      if(profit >= trailStart * point)
      {
         double newSL = NormalizeDouble(bid - trailStop * point, digits);
         // Only move SL up, never down. Must move at least trailStep.
         if(newSL > currentSL + trailStep * point)
         {
            double tp = PositionGetDouble(POSITION_TP);
            m_trade.PositionModify(ticket, newSL, tp);
         }
      }
   }
   else if(type == POSITION_TYPE_SELL)
   {
      double profit = openPrice - ask;
      if(profit >= trailStart * point)
      {
         double newSL = NormalizeDouble(ask + trailStop * point, digits);
         // Only move SL down, never up.
         if(currentSL == 0 || newSL < currentSL - trailStep * point)
         {
            double tp = PositionGetDouble(POSITION_TP);
            m_trade.PositionModify(ticket, newSL, tp);
         }
      }
   }
}
```

- [ ] **Step 4: Add m_lastATR member and update ManageOrders**

Add private member after `int m_beCount;` (line 21):

```mql5
   double m_lastATR;             // Current ATR value (0 = use fixed params)
```

Initialize in Init() after `ArrayResize(m_beApplied, 0);` (line 39):

```mql5
   m_lastATR = 0;
```

Replace the ManageOrders implementation (lines 137-162) with:

```mql5
void CTrailingManager::ManageOrders(double atrValue)
{
   m_lastATR = (InpSlTpMode == SLTP_ATR) ? atrValue : 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() != m_symbol || m_position.Magic() != EA_MAGIC)
            continue;

         ulong              ticket    = m_position.Ticket();
         ENUM_POSITION_TYPE type      = m_position.PositionType();
         double             openPrice = m_position.PriceOpen();
         double             currentSL = m_position.StopLoss();

         // Step 1: Break Even first
         ApplyBreakEven(ticket, type, openPrice);

         // Refresh SL after potential BE modification
         if(m_position.SelectByIndex(i))
            currentSL = m_position.StopLoss();

         // Step 2: Trailing Stop (can override BE SL when price moves further)
         ApplyTrailingStop(ticket, type, openPrice, currentSL);
      }
   }
}
```

- [ ] **Step 5: Commit**

```bash
git add Include/GoldScalper/TrailingManager.mqh
git commit -m "feat: add ATR-based dynamic break-even and trailing stop"
```

---

### Task 4: Modify RiskManager to Accept Dynamic SL

**Files:**
- Modify: `Include/GoldScalper/RiskManager.mqh`

- [ ] **Step 1: Change CalculateLot signature**

Replace the declaration (line 28):
```mql5
   double CalculateLot();
```

With:
```mql5
   double CalculateLot(int slPoints);
```

- [ ] **Step 2: Update CalculateLot implementation to use parameter**

Replace the implementation (lines 69-103) with:

```mql5
double CRiskManager::CalculateLot(int slPoints)
{
   double lotSize = InpFixedLot;

   if(InpLotMode == LOT_PERCENT)
   {
      double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
      double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize  = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      double point     = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

      if(tickValue <= 0 || slPoints <= 0 || tickSize <= 0)
         return InpFixedLot;

      double riskMoney = balance * InpRiskPercent / 100.0;
      double slMoney   = slPoints * point / tickSize * tickValue;

      if(slMoney > 0)
         lotSize = riskMoney / slMoney;
   }

   // Clamp to broker limits
   double minLot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);

   lotSize = MathMax(minLot, lotSize);
   lotSize = MathMin(maxLot, lotSize);

   if(lotStep > 0)
      lotSize = MathFloor(lotSize / lotStep) * lotStep;

   lotSize = NormalizeDouble(lotSize, 2);

   return lotSize;
}
```

The only change is: `InpStopLoss` → `slPoints` parameter throughout.

- [ ] **Step 3: Commit**

```bash
git add Include/GoldScalper/RiskManager.mqh
git commit -m "feat: CalculateLot accepts dynamic SL for ATR-based lot sizing"
```

---

### Task 5: Update Dashboard to Show ATR Info

**Files:**
- Modify: `Include/GoldScalper/Dashboard.mqh`

- [ ] **Step 1: Add ATR fields to SDashboardData struct**

After `bool inTimeWindow;` (line 32) add:

```mql5
   double      atrValue;
   int         dynamicSL;
   int         dynamicTP;
```

- [ ] **Step 2: Add ATR display row in Update() method**

After the spread display block (lines 136-139, ending with `y += m_lineHeight;`) add:

```mql5
   // ATR & Dynamic SL/TP
   if(InpSlTpMode == SLTP_ATR)
   {
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      CreateLabel("atr", x, y,
         StringFormat("ATR: $%.2f  |  SL: $%.2f (%d pts)  |  TP: $%.2f (%d pts)",
            data.atrValue,
            data.dynamicSL * point, data.dynamicSL,
            data.dynamicTP * point, data.dynamicTP),
         clrCyan);
   }
   else
   {
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      CreateLabel("atr", x, y,
         StringFormat("Mode: Fixed  |  SL: $%.2f (%d pts)  |  TP: $%.2f (%d pts)",
            InpStopLoss * point, InpStopLoss,
            InpTakeProfit * point, InpTakeProfit),
         clrWhite);
   }
   y += m_lineHeight;
```

- [ ] **Step 3: Commit**

```bash
git add Include/GoldScalper/Dashboard.mqh
git commit -m "feat: display ATR and dynamic SL/TP on dashboard"
```

---

### Task 6: Wire Everything in GoldScalper.mq5

**Files:**
- Modify: `Experts/GoldScalper/GoldScalper.mq5`

- [ ] **Step 1: Update OnInit() logging to show ATR mode**

Replace the Print block (lines 63-66):

```mql5
   Print(EA_NAME, " v", EA_VERSION, " initialized on ", _Symbol);
   Print(EA_NAME, ": SL=", InpStopLoss, " pts ($", DoubleToString(InpStopLoss * SymbolInfoDouble(_Symbol, SYMBOL_POINT), 2),
         ") | TP=", InpTakeProfit, " pts ($", DoubleToString(InpTakeProfit * SymbolInfoDouble(_Symbol, SYMBOL_POINT), 2),
         ") | MaxSpread=", InpMaxSpread, " pts | POINT=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_POINT), _Digits));
```

With:

```mql5
   Print(EA_NAME, " v", EA_VERSION, " initialized on ", _Symbol);
   if(InpSlTpMode == SLTP_ATR)
      Print(EA_NAME, ": Mode=ATR | SL=ATR*", DoubleToString(InpAtrSlMultiplier, 1),
            " | TP=ATR*", DoubleToString(InpAtrTpMultiplier, 1),
            " | ATR Period=", InpAtrPeriod,
            " | POINT=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_POINT), _Digits));
   else
      Print(EA_NAME, ": Mode=Fixed | SL=", InpStopLoss, " pts ($", DoubleToString(InpStopLoss * SymbolInfoDouble(_Symbol, SYMBOL_POINT), 2),
            ") | TP=", InpTakeProfit, " pts ($", DoubleToString(InpTakeProfit * SymbolInfoDouble(_Symbol, SYMBOL_POINT), 2),
            ") | POINT=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_POINT), _Digits));
```

- [ ] **Step 2: Add ATR retrieval and dynamic SL/TP calculation in OnTick()**

After the trailing manager call (line 127):
```mql5
   //--- 4. Manage existing orders (trailing + break even) - always runs
   g_trailingMgr.ManageOrders();
```

Replace with:

```mql5
   //--- 4. Get ATR value
   double atrValue = g_signalMgr.GetATR();

   //--- 5. Manage existing orders (trailing + break even) - always runs
   g_trailingMgr.ManageOrders(atrValue);
```

- [ ] **Step 3: Replace fixed SL/TP with dynamic calculation in trade entry block**

Replace the trade execution block (lines 147-159):

```mql5
      // Check order limit, spread, and stops validity
      bool spreadOK = g_tradeMgr.IsSpreadOK();
      bool orderLimitOK = (g_tradeMgr.CountOpenOrders() < InpMaxOpenOrders);
      bool stopsOK = g_tradeMgr.ValidateStops(InpStopLoss, InpTakeProfit);

      if(orderLimitOK && spreadOK && stopsOK)
      {
         double lotSize = g_riskMgr.CalculateLot();

         if(signal == SIGNAL_BUY)
            g_tradeMgr.OpenBuy(lotSize, InpStopLoss, InpTakeProfit);
         else if(signal == SIGNAL_SELL)
            g_tradeMgr.OpenSell(lotSize, InpStopLoss, InpTakeProfit);
      }
```

With:

```mql5
      // Calculate SL/TP (dynamic or fixed)
      int slPoints, tpPoints;
      if(InpSlTpMode == SLTP_ATR && atrValue > 0)
      {
         double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         slPoints = (int)(atrValue * InpAtrSlMultiplier / point);
         tpPoints = (int)(atrValue * InpAtrTpMultiplier / point);
      }
      else
      {
         slPoints = InpStopLoss;
         tpPoints = InpTakeProfit;
      }

      // Check order limit, spread, and stops validity
      bool spreadOK = g_tradeMgr.IsSpreadOK();
      bool orderLimitOK = (g_tradeMgr.CountOpenOrders() < InpMaxOpenOrders);
      bool stopsOK = g_tradeMgr.ValidateStops(slPoints, tpPoints);

      if(orderLimitOK && spreadOK && stopsOK)
      {
         double lotSize = g_riskMgr.CalculateLot(slPoints);

         if(signal == SIGNAL_BUY)
            g_tradeMgr.OpenBuy(lotSize, slPoints, tpPoints);
         else if(signal == SIGNAL_SELL)
            g_tradeMgr.OpenSell(lotSize, slPoints, tpPoints);
      }
```

- [ ] **Step 4: Update debug logging to include ATR info**

In the debug logging block (lines 169-188), after the Spread print (line 186-187):

```mql5
      Print(EA_NAME, ": Spread=", SymbolInfoInteger(_Symbol, SYMBOL_SPREAD),
            " | Orders=", g_tradeMgr.CountOpenOrders());
```

Add after it:

```mql5
      if(InpSlTpMode == SLTP_ATR)
      {
         double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         int dbgSL = (atrValue > 0) ? (int)(atrValue * InpAtrSlMultiplier / point) : 0;
         int dbgTP = (atrValue > 0) ? (int)(atrValue * InpAtrTpMultiplier / point) : 0;
         Print(EA_NAME, ": ATR=$", DoubleToString(atrValue, 2),
               " | Dynamic SL=", dbgSL, " pts ($", DoubleToString(dbgSL * point, 2),
               ") | TP=", dbgTP, " pts ($", DoubleToString(dbgTP * point, 2), ")");
      }
```

- [ ] **Step 5: Update UpdateDashboard() to pass ATR data**

In `UpdateDashboard()` (lines 210-237), after `data.inTimeWindow = g_timeFilter.InTimeWindow;` (line 234) add:

```mql5
   data.atrValue  = g_signalMgr.AtrValue;
   if(InpSlTpMode == SLTP_ATR && g_signalMgr.AtrValue > 0)
   {
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      data.dynamicSL = (int)(g_signalMgr.AtrValue * InpAtrSlMultiplier / point);
      data.dynamicTP = (int)(g_signalMgr.AtrValue * InpAtrTpMultiplier / point);
   }
   else
   {
      data.dynamicSL = InpStopLoss;
      data.dynamicTP = InpTakeProfit;
   }
```

- [ ] **Step 6: Commit**

```bash
git add Experts/GoldScalper/GoldScalper.mq5
git commit -m "feat: wire ATR-based dynamic SL/TP/Trailing in main EA orchestrator"
```

---

### Task 7: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update Architecture section**

In the Architecture section, update the `Defines.mqh` description:

```
├── Defines.mqh          # Enums, constants, all 45 input parameters (was 36)
```

- [ ] **Step 2: Add ATR mode to Key Conventions**

Add under Key Conventions:

```
- **ATR Mode (default):** SL/TP/Trailing calculated from ATR(14) x multipliers. Adapts to volatility automatically. Switch to `SLTP_FIXED` to use fixed point values.
```

- [ ] **Step 3: Add ATR gotcha to Gotchas section**

Add:

```
- **ATR in backtest** — ATR calculates from historical data and works correctly in Strategy Tester (unlike NewsFilter). First ~14 bars may have unstable ATR values as the indicator warms up.
- **RiskManager uses dynamic SL** — In ATR mode, lot sizing is based on the ATR-calculated SL, not InpStopLoss. This ensures risk percentage is accurate regardless of mode.
```

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with ATR mode documentation"
```

---

### Task 8: Final Verification

- [ ] **Step 1: Review all modified files for syntax errors**

Verify these files have no issues:
- `Include/GoldScalper/Defines.mqh` — 9 new inputs, ENUM_SLTP_MODE
- `Include/GoldScalper/SignalManager.mqh` — ATR handle, GetATR(), AtrValue
- `Include/GoldScalper/TrailingManager.mqh` — ManageOrders(atrValue), m_lastATR, dynamic BE/trailing
- `Include/GoldScalper/RiskManager.mqh` — CalculateLot(slPoints)
- `Include/GoldScalper/Dashboard.mqh` — ATR display row, SDashboardData fields
- `Experts/GoldScalper/GoldScalper.mq5` — ATR flow, dynamic SL/TP calc, debug logging

- [ ] **Step 2: Verify method signatures match across files**

Check consistency:
- `g_signalMgr.GetATR()` returns `double` → used in GoldScalper.mq5 as `double atrValue`
- `g_trailingMgr.ManageOrders(atrValue)` → TrailingManager accepts `double atrValue = 0`
- `g_riskMgr.CalculateLot(slPoints)` → RiskManager accepts `int slPoints`
- `g_tradeMgr.OpenBuy(lotSize, slPoints, tpPoints)` → TradeManager signature unchanged `(double, int, int)`
- `g_tradeMgr.ValidateStops(slPoints, tpPoints)` → TradeManager signature unchanged `(int, int)`
- `SDashboardData` has `atrValue`, `dynamicSL`, `dynamicTP` fields
- `InpSlTpMode` accessible in all files via `#include "Defines.mqh"`

- [ ] **Step 3: Copy to MT5 and compile**

```
1. Copy Include/GoldScalper/ to MQL5/Include/GoldScalper/
2. Copy Experts/GoldScalper/ to MQL5/Experts/GoldScalper/
3. Open MetaEditor → Compile (F7)
4. Fix any compilation errors
```

- [ ] **Step 4: Backtest with ATR mode**

```
1. Strategy Tester: XAUUSD M5, Every Tick, 2026.01.01-2026.04.10
2. Right-click Inputs → Reset (important: load new defaults)
3. Verify InpSlTpMode = ATR-Based
4. Run backtest
5. Check: trades execute, no "invalid stops", ATR values in log
6. Compare results with Run 6 and Run 7
```

- [ ] **Step 5: Backtest with Fixed mode (backward compatibility)**

```
1. Change InpSlTpMode to "Fixed Points"
2. Run same backtest period
3. Verify results match previous Run 7 exactly (same 216 trades)
```
