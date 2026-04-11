# GoldScalper EA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete MQL5 Expert Advisor for scalping XAUUSD using multi-timeframe EMA crossover + RSI filter, with full risk management, trailing stop, news/time filters, and on-chart dashboard.

**Architecture:** Modular design with one orchestrator EA file (`GoldScalper.mq5`) and 8 include files, each handling a single responsibility. All input parameters centralized in `Defines.mqh`. Managers communicate through the orchestrator — no cross-dependencies between modules.

**Tech Stack:** MQL5 (MetaTrader 5), MQL5 Standard Library (`Trade/Trade.mqh`, `Trade/PositionInfo.mqh`), built-in Economic Calendar API.

**Design spec:** `docs/superpowers/specs/2026-04-11-gold-scalper-design.md`

---

## File Map

| File | Responsibility |
|---|---|
| `Include/GoldScalper/Defines.mqh` | Enums, constants, all `input` parameters |
| `Include/GoldScalper/SignalManager.mqh` | EMA crossover + RSI signal detection on M5/M15 |
| `Include/GoldScalper/TradeManager.mqh` | Open/close/count positions using CTrade |
| `Include/GoldScalper/RiskManager.mqh` | Lot calculation (fixed/percent), daily drawdown tracking |
| `Include/GoldScalper/TrailingManager.mqh` | Break even + trailing stop management |
| `Include/GoldScalper/TimeFilter.mqh` | Trading hours filter |
| `Include/GoldScalper/NewsFilter.mqh` | Economic calendar news filter |
| `Include/GoldScalper/Dashboard.mqh` | On-chart OBJ_LABEL dashboard display |
| `Experts/GoldScalper/GoldScalper.mq5` | Main EA: OnInit/OnDeinit/OnTick orchestrator |

---

### Task 1: Defines — Enums, Constants, Input Parameters

**Files:**
- Create: `Include/GoldScalper/Defines.mqh`

- [ ] **Step 1: Create `Include/GoldScalper/Defines.mqh`**

```mql5
//+------------------------------------------------------------------+
//|                                                      Defines.mqh |
//|                                                      GoldScalper |
//+------------------------------------------------------------------+
#ifndef DEFINES_MQH
#define DEFINES_MQH

//--- EA Identification
#define EA_NAME    "GoldScalper"
#define EA_VERSION "1.0"
#define EA_MAGIC   202604110

//--- Enums
enum ENUM_LOT_MODE
{
   LOT_FIXED   = 0,  // Fixed Lot
   LOT_PERCENT = 1   // Percent Risk
};

enum ENUM_DD_ACTION
{
   DD_STOP      = 0,  // Stop Trading
   DD_CLOSE_ALL = 1   // Close All & Stop
};

enum ENUM_NEWS_IMPACT
{
   NEWS_HIGH   = 0,  // High Impact Only
   NEWS_MEDIUM = 1,  // Medium & High
   NEWS_ALL    = 2   // All Impact
};

enum ENUM_SIGNAL
{
   SIGNAL_NONE = 0,
   SIGNAL_BUY  = 1,
   SIGNAL_SELL = 2
};

//--- Input Parameters: Signal
input group "=== Signal Settings ==="
input int    InpEmaFastPeriod       = 9;       // EMA Fast Period (M5)
input int    InpEmaSlowPeriod       = 21;      // EMA Slow Period (M5)
input int    InpEmaTrendFast        = 50;      // EMA Trend Fast (M15)
input int    InpEmaTrendSlow        = 200;     // EMA Trend Slow (M15)
input int    InpRsiPeriod           = 14;      // RSI Period
input int    InpRsiUpper            = 70;      // RSI Upper Limit
input int    InpRsiLower            = 30;      // RSI Lower Limit
input int    InpTakeProfit          = 100;     // Take Profit (points)
input int    InpStopLoss            = 50;      // Stop Loss (points)
input bool   InpCloseOnOpposite     = true;    // Close On Opposite Signal

//--- Input Parameters: Risk Management
input group "=== Risk Management ==="
input ENUM_LOT_MODE InpLotMode      = LOT_FIXED;  // Lot Mode
input double InpFixedLot            = 0.01;    // Fixed Lot Size
input double InpRiskPercent         = 1.0;     // Risk Percent per Trade
input int    InpMaxOpenOrders       = 3;       // Max Open Orders
input int    InpMaxSpread           = 30;      // Max Spread (points)

//--- Input Parameters: Daily Drawdown
input group "=== Daily Drawdown ==="
input bool   InpUseDailyDrawdown    = true;    // Use Daily Drawdown Limit
input double InpMaxDailyDDPercent   = 3.0;     // Max Daily Drawdown (%)
input ENUM_DD_ACTION InpDDAction    = DD_STOP; // Drawdown Action

//--- Input Parameters: Break Even
input group "=== Break Even ==="
input bool   InpUseBreakEven        = true;    // Use Break Even
input int    InpBreakEvenTrigger    = 30;      // Break Even Trigger (points)
input int    InpBreakEvenProfit     = 5;       // Break Even Lock Profit (points)

//--- Input Parameters: Trailing Stop
input group "=== Trailing Stop ==="
input bool   InpUseTrailingStop     = true;    // Use Trailing Stop
input int    InpTrailingStart       = 40;      // Trailing Start (points)
input int    InpTrailingStep        = 10;      // Trailing Step (points)
input int    InpTrailingStop        = 30;      // Trailing Distance (points)

//--- Input Parameters: Time Filter
input group "=== Time Filter ==="
input bool   InpUseTimeFilter       = true;    // Use Time Filter
input int    InpTradeStartHour      = 8;       // Trade Start Hour
input int    InpTradeStartMinute    = 0;       // Trade Start Minute
input int    InpTradeEndHour        = 20;      // Trade End Hour
input int    InpTradeEndMinute      = 0;       // Trade End Minute
input bool   InpCloseOutsideTime    = false;   // Close Orders Outside Time

//--- Input Parameters: News Filter
input group "=== News Filter ==="
input bool   InpUseNewsFilter       = true;    // Use News Filter
input int    InpNewsMinsBefore      = 30;      // Minutes Before News
input int    InpNewsMinsAfter       = 15;      // Minutes After News
input ENUM_NEWS_IMPACT InpNewsImpact = NEWS_HIGH; // News Impact Level
input bool   InpCloseBeforeNews     = false;   // Close Orders Before News

#endif
```

- [ ] **Step 2: Commit**

```bash
git add Include/GoldScalper/Defines.mqh
git commit -m "feat: add Defines.mqh with enums and input parameters"
```

---

### Task 2: SignalManager — EMA Crossover + RSI Detection

**Files:**
- Create: `Include/GoldScalper/SignalManager.mqh`

- [ ] **Step 1: Create `Include/GoldScalper/SignalManager.mqh`**

```mql5
//+------------------------------------------------------------------+
//|                                                SignalManager.mqh |
//|                                                      GoldScalper |
//+------------------------------------------------------------------+
#ifndef SIGNAL_MANAGER_MQH
#define SIGNAL_MANAGER_MQH

#include "Defines.mqh"

class CSignalManager
{
private:
   int    m_emaFastHandle;      // EMA fast on M5
   int    m_emaSlowHandle;      // EMA slow on M5
   int    m_emaTrendFastHandle; // EMA trend fast on M15
   int    m_emaTrendSlowHandle; // EMA trend slow on M15
   int    m_rsiHandle;          // RSI on M5
   string m_symbol;

   double m_emaFast[];
   double m_emaSlow[];
   double m_emaTrendFast[];
   double m_emaTrendSlow[];
   double m_rsi[];

public:
   // Public values for dashboard
   double EmaFastValue;
   double EmaSlowValue;
   double EmaTrendFastValue;
   double EmaTrendSlowValue;
   double RsiValue;
   bool   TrendUp;

   bool        Init(string symbol);
   void        Deinit();
   ENUM_SIGNAL CheckSignal();
};

//+------------------------------------------------------------------+
bool CSignalManager::Init(string symbol)
{
   m_symbol = symbol;

   m_emaFastHandle      = iMA(m_symbol, PERIOD_M5,  InpEmaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_emaSlowHandle      = iMA(m_symbol, PERIOD_M5,  InpEmaSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_emaTrendFastHandle = iMA(m_symbol, PERIOD_M15, InpEmaTrendFast,  0, MODE_EMA, PRICE_CLOSE);
   m_emaTrendSlowHandle = iMA(m_symbol, PERIOD_M15, InpEmaTrendSlow,  0, MODE_EMA, PRICE_CLOSE);
   m_rsiHandle          = iRSI(m_symbol, PERIOD_M5, InpRsiPeriod, PRICE_CLOSE);

   if(m_emaFastHandle == INVALID_HANDLE || m_emaSlowHandle == INVALID_HANDLE ||
      m_emaTrendFastHandle == INVALID_HANDLE || m_emaTrendSlowHandle == INVALID_HANDLE ||
      m_rsiHandle == INVALID_HANDLE)
   {
      Print(EA_NAME, ": Failed to create indicator handles");
      return false;
   }

   ArraySetAsSeries(m_emaFast, true);
   ArraySetAsSeries(m_emaSlow, true);
   ArraySetAsSeries(m_emaTrendFast, true);
   ArraySetAsSeries(m_emaTrendSlow, true);
   ArraySetAsSeries(m_rsi, true);

   return true;
}

//+------------------------------------------------------------------+
void CSignalManager::Deinit()
{
   if(m_emaFastHandle != INVALID_HANDLE)      IndicatorRelease(m_emaFastHandle);
   if(m_emaSlowHandle != INVALID_HANDLE)      IndicatorRelease(m_emaSlowHandle);
   if(m_emaTrendFastHandle != INVALID_HANDLE) IndicatorRelease(m_emaTrendFastHandle);
   if(m_emaTrendSlowHandle != INVALID_HANDLE) IndicatorRelease(m_emaTrendSlowHandle);
   if(m_rsiHandle != INVALID_HANDLE)          IndicatorRelease(m_rsiHandle);
}

//+------------------------------------------------------------------+
ENUM_SIGNAL CSignalManager::CheckSignal()
{
   // Need bars 0,1,2: bar 0 = current (forming), bar 1 = last closed, bar 2 = previous closed
   if(CopyBuffer(m_emaFastHandle, 0, 0, 3, m_emaFast) < 3)           return SIGNAL_NONE;
   if(CopyBuffer(m_emaSlowHandle, 0, 0, 3, m_emaSlow) < 3)           return SIGNAL_NONE;
   if(CopyBuffer(m_emaTrendFastHandle, 0, 0, 2, m_emaTrendFast) < 2) return SIGNAL_NONE;
   if(CopyBuffer(m_emaTrendSlowHandle, 0, 0, 2, m_emaTrendSlow) < 2) return SIGNAL_NONE;
   if(CopyBuffer(m_rsiHandle, 0, 0, 2, m_rsi) < 2)                   return SIGNAL_NONE;

   // Store values for dashboard
   EmaFastValue      = m_emaFast[0];
   EmaSlowValue      = m_emaSlow[0];
   EmaTrendFastValue = m_emaTrendFast[0];
   EmaTrendSlowValue = m_emaTrendSlow[0];
   RsiValue          = m_rsi[1]; // Use completed bar
   TrendUp           = (m_emaTrendFast[0] > m_emaTrendSlow[0]);

   // M15 trend filter
   bool isTrendUp   = (m_emaTrendFast[0] > m_emaTrendSlow[0]);
   bool isTrendDown = (m_emaTrendFast[0] < m_emaTrendSlow[0]);

   // M5 EMA crossover: bar[1] crossed bar[2] (completed bars only)
   bool goldenCross = (m_emaFast[1] > m_emaSlow[1]) && (m_emaFast[2] <= m_emaSlow[2]);
   bool deathCross  = (m_emaFast[1] < m_emaSlow[1]) && (m_emaFast[2] >= m_emaSlow[2]);

   // RSI filter on completed bar
   double rsiVal  = m_rsi[1];
   bool rsiInRange = (rsiVal > InpRsiLower && rsiVal < InpRsiUpper);

   // Buy: uptrend + golden cross + RSI in range
   if(isTrendUp && goldenCross && rsiInRange)
      return SIGNAL_BUY;

   // Sell: downtrend + death cross + RSI in range
   if(isTrendDown && deathCross && rsiInRange)
      return SIGNAL_SELL;

   return SIGNAL_NONE;
}

#endif
```

- [ ] **Step 2: Commit**

```bash
git add Include/GoldScalper/SignalManager.mqh
git commit -m "feat: add SignalManager with EMA crossover + RSI signal detection"
```

---

### Task 3: TradeManager — Order Execution

**Files:**
- Create: `Include/GoldScalper/TradeManager.mqh`

- [ ] **Step 1: Create `Include/GoldScalper/TradeManager.mqh`**

```mql5
//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                                                      GoldScalper |
//+------------------------------------------------------------------+
#ifndef TRADE_MANAGER_MQH
#define TRADE_MANAGER_MQH

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include "Defines.mqh"

class CTradeManager
{
private:
   CTrade        m_trade;
   CPositionInfo m_position;
   string        m_symbol;

public:
   bool Init(string symbol);
   bool OpenBuy(double lotSize, int slPoints, int tpPoints);
   bool OpenSell(double lotSize, int slPoints, int tpPoints);
   bool ClosePosition(ulong ticket);
   int  CloseAllBuy();
   int  CloseAllSell();
   int  CloseAll();
   int  CountOpenOrders();
   int  CountBuyOrders();
   int  CountSellOrders();
   bool IsSpreadOK();
};

//+------------------------------------------------------------------+
bool CTradeManager::Init(string symbol)
{
   m_symbol = symbol;
   m_trade.SetExpertMagicNumber(EA_MAGIC);
   m_trade.SetDeviationInPoints(10);
   m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   return true;
}

//+------------------------------------------------------------------+
bool CTradeManager::OpenBuy(double lotSize, int slPoints, int tpPoints)
{
   double ask   = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

   double slPrice = (slPoints > 0) ? NormalizeDouble(ask - slPoints * point, digits) : 0;
   double tpPrice = (tpPoints > 0) ? NormalizeDouble(ask + tpPoints * point, digits) : 0;

   if(!m_trade.Buy(lotSize, m_symbol, ask, slPrice, tpPrice, EA_NAME))
   {
      Print(EA_NAME, ": Buy failed - ", m_trade.ResultRetcodeDescription());
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
bool CTradeManager::OpenSell(double lotSize, int slPoints, int tpPoints)
{
   double bid   = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

   double slPrice = (slPoints > 0) ? NormalizeDouble(bid + slPoints * point, digits) : 0;
   double tpPrice = (tpPoints > 0) ? NormalizeDouble(bid - tpPoints * point, digits) : 0;

   if(!m_trade.Sell(lotSize, m_symbol, bid, slPrice, tpPrice, EA_NAME))
   {
      Print(EA_NAME, ": Sell failed - ", m_trade.ResultRetcodeDescription());
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(ulong ticket)
{
   if(!m_trade.PositionClose(ticket))
   {
      Print(EA_NAME, ": Close failed ticket ", ticket, " - ", m_trade.ResultRetcodeDescription());
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
int CTradeManager::CloseAllBuy()
{
   int closed = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == m_symbol &&
            m_position.Magic() == EA_MAGIC &&
            m_position.PositionType() == POSITION_TYPE_BUY)
         {
            if(ClosePosition(m_position.Ticket()))
               closed++;
         }
      }
   }
   return closed;
}

//+------------------------------------------------------------------+
int CTradeManager::CloseAllSell()
{
   int closed = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == m_symbol &&
            m_position.Magic() == EA_MAGIC &&
            m_position.PositionType() == POSITION_TYPE_SELL)
         {
            if(ClosePosition(m_position.Ticket()))
               closed++;
         }
      }
   }
   return closed;
}

//+------------------------------------------------------------------+
int CTradeManager::CloseAll()
{
   int closed = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == m_symbol && m_position.Magic() == EA_MAGIC)
         {
            if(ClosePosition(m_position.Ticket()))
               closed++;
         }
      }
   }
   return closed;
}

//+------------------------------------------------------------------+
int CTradeManager::CountOpenOrders()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == m_symbol && m_position.Magic() == EA_MAGIC)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
int CTradeManager::CountBuyOrders()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == m_symbol &&
            m_position.Magic() == EA_MAGIC &&
            m_position.PositionType() == POSITION_TYPE_BUY)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
int CTradeManager::CountSellOrders()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == m_symbol &&
            m_position.Magic() == EA_MAGIC &&
            m_position.PositionType() == POSITION_TYPE_SELL)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
bool CTradeManager::IsSpreadOK()
{
   long spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
   return (spread <= InpMaxSpread);
}

#endif
```

- [ ] **Step 2: Commit**

```bash
git add Include/GoldScalper/TradeManager.mqh
git commit -m "feat: add TradeManager for order execution and position management"
```

---

### Task 4: RiskManager — Lot Calculation & Daily Drawdown

**Files:**
- Create: `Include/GoldScalper/RiskManager.mqh`

- [ ] **Step 1: Create `Include/GoldScalper/RiskManager.mqh`**

```mql5
//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                                                      GoldScalper |
//+------------------------------------------------------------------+
#ifndef RISK_MANAGER_MQH
#define RISK_MANAGER_MQH

#include "Defines.mqh"

class CRiskManager
{
private:
   string m_symbol;
   double m_dailyStartBalance;
   int    m_currentDay;
   bool   m_dailyStopActive;

   void   CheckNewDay();

public:
   // Public values for dashboard
   double DailyDrawdownPercent;
   double DailyPL;
   double DailyPLPercent;
   bool   IsStopped;

   bool   Init(string symbol);
   double CalculateLot();
   bool   IsDailyDrawdownExceeded();
   void   UpdateDailyStats();
};

//+------------------------------------------------------------------+
bool CRiskManager::Init(string symbol)
{
   m_symbol = symbol;
   m_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   MqlDateTime dt;
   TimeCurrent(dt);
   m_currentDay = dt.day;

   m_dailyStopActive    = false;
   DailyDrawdownPercent = 0;
   DailyPL              = 0;
   DailyPLPercent       = 0;
   IsStopped            = false;

   return true;
}

//+------------------------------------------------------------------+
void CRiskManager::CheckNewDay()
{
   MqlDateTime dt;
   TimeCurrent(dt);

   if(dt.day != m_currentDay)
   {
      m_currentDay        = dt.day;
      m_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      m_dailyStopActive   = false;
      IsStopped           = false;
      Print(EA_NAME, ": New day - daily drawdown reset. Start balance: ", DoubleToString(m_dailyStartBalance, 2));
   }
}

//+------------------------------------------------------------------+
double CRiskManager::CalculateLot()
{
   double lotSize = InpFixedLot;

   if(InpLotMode == LOT_PERCENT)
   {
      double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
      double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize  = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      double point     = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

      if(tickValue <= 0 || InpStopLoss <= 0 || tickSize <= 0)
         return InpFixedLot;

      double riskMoney = balance * InpRiskPercent / 100.0;
      double slMoney   = InpStopLoss * point / tickSize * tickValue;

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

//+------------------------------------------------------------------+
void CRiskManager::UpdateDailyStats()
{
   CheckNewDay();

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   DailyPL = equity - m_dailyStartBalance;

   if(m_dailyStartBalance > 0)
   {
      DailyPLPercent       = DailyPL / m_dailyStartBalance * 100.0;
      DailyDrawdownPercent = (DailyPL < 0) ? MathAbs(DailyPLPercent) : 0;
   }
}

//+------------------------------------------------------------------+
bool CRiskManager::IsDailyDrawdownExceeded()
{
   if(!InpUseDailyDrawdown)
      return false;

   CheckNewDay();

   if(m_dailyStopActive)
      return true;

   double equity   = AccountInfoDouble(ACCOUNT_EQUITY);
   double drawdown = m_dailyStartBalance - equity;
   DailyDrawdownPercent = (m_dailyStartBalance > 0) ? (drawdown / m_dailyStartBalance * 100.0) : 0;

   if(DailyDrawdownPercent < 0)
      DailyDrawdownPercent = 0;

   if(DailyDrawdownPercent >= InpMaxDailyDDPercent)
   {
      m_dailyStopActive = true;
      IsStopped = true;
      Print(EA_NAME, ": Daily drawdown limit reached: ", DoubleToString(DailyDrawdownPercent, 2), "%");
      return true;
   }

   return false;
}

#endif
```

- [ ] **Step 2: Commit**

```bash
git add Include/GoldScalper/RiskManager.mqh
git commit -m "feat: add RiskManager with lot calculation and daily drawdown"
```

---

### Task 5: TrailingManager — Break Even & Trailing Stop

**Files:**
- Create: `Include/GoldScalper/TrailingManager.mqh`

- [ ] **Step 1: Create `Include/GoldScalper/TrailingManager.mqh`**

```mql5
//+------------------------------------------------------------------+
//|                                              TrailingManager.mqh |
//|                                                      GoldScalper |
//+------------------------------------------------------------------+
#ifndef TRAILING_MANAGER_MQH
#define TRAILING_MANAGER_MQH

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include "Defines.mqh"

class CTrailingManager
{
private:
   CTrade        m_trade;
   CPositionInfo m_position;
   string        m_symbol;

   // Track positions that already had break even applied
   ulong  m_beApplied[];
   int    m_beCount;

   bool IsBreakEvenApplied(ulong ticket);
   void MarkBreakEvenApplied(ulong ticket);
   void ApplyBreakEven(ulong ticket, ENUM_POSITION_TYPE type, double openPrice);
   void ApplyTrailingStop(ulong ticket, ENUM_POSITION_TYPE type, double openPrice, double currentSL);

public:
   bool Init(string symbol);
   void ManageOrders();
};

//+------------------------------------------------------------------+
bool CTrailingManager::Init(string symbol)
{
   m_symbol = symbol;
   m_trade.SetExpertMagicNumber(EA_MAGIC);
   m_beCount = 0;
   ArrayResize(m_beApplied, 0);
   return true;
}

//+------------------------------------------------------------------+
bool CTrailingManager::IsBreakEvenApplied(ulong ticket)
{
   for(int i = 0; i < m_beCount; i++)
   {
      if(m_beApplied[i] == ticket)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
void CTrailingManager::MarkBreakEvenApplied(ulong ticket)
{
   m_beCount++;
   ArrayResize(m_beApplied, m_beCount);
   m_beApplied[m_beCount - 1] = ticket;
}

//+------------------------------------------------------------------+
void CTrailingManager::ApplyBreakEven(ulong ticket, ENUM_POSITION_TYPE type, double openPrice)
{
   if(!InpUseBreakEven || IsBreakEvenApplied(ticket))
      return;

   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   double bid   = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double ask   = SymbolInfoDouble(m_symbol, SYMBOL_ASK);

   if(type == POSITION_TYPE_BUY)
   {
      if((bid - openPrice) >= InpBreakEvenTrigger * point)
      {
         double newSL = NormalizeDouble(openPrice + InpBreakEvenProfit * point, digits);
         double tp    = PositionGetDouble(POSITION_TP);
         if(m_trade.PositionModify(ticket, newSL, tp))
            MarkBreakEvenApplied(ticket);
      }
   }
   else if(type == POSITION_TYPE_SELL)
   {
      if((openPrice - ask) >= InpBreakEvenTrigger * point)
      {
         double newSL = NormalizeDouble(openPrice - InpBreakEvenProfit * point, digits);
         double tp    = PositionGetDouble(POSITION_TP);
         if(m_trade.PositionModify(ticket, newSL, tp))
            MarkBreakEvenApplied(ticket);
      }
   }
}

//+------------------------------------------------------------------+
void CTrailingManager::ApplyTrailingStop(ulong ticket, ENUM_POSITION_TYPE type, double openPrice, double currentSL)
{
   if(!InpUseTrailingStop)
      return;

   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   double bid   = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double ask   = SymbolInfoDouble(m_symbol, SYMBOL_ASK);

   if(type == POSITION_TYPE_BUY)
   {
      double profit = bid - openPrice;
      if(profit >= InpTrailingStart * point)
      {
         double newSL = NormalizeDouble(bid - InpTrailingStop * point, digits);
         // Only move SL up, never down. Must move at least TrailingStep.
         if(newSL > currentSL + InpTrailingStep * point)
         {
            double tp = PositionGetDouble(POSITION_TP);
            m_trade.PositionModify(ticket, newSL, tp);
         }
      }
   }
   else if(type == POSITION_TYPE_SELL)
   {
      double profit = openPrice - ask;
      if(profit >= InpTrailingStart * point)
      {
         double newSL = NormalizeDouble(ask + InpTrailingStop * point, digits);
         // Only move SL down, never up.
         if(currentSL == 0 || newSL < currentSL - InpTrailingStep * point)
         {
            double tp = PositionGetDouble(POSITION_TP);
            m_trade.PositionModify(ticket, newSL, tp);
         }
      }
   }
}

//+------------------------------------------------------------------+
void CTrailingManager::ManageOrders()
{
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

#endif
```

- [ ] **Step 2: Commit**

```bash
git add Include/GoldScalper/TrailingManager.mqh
git commit -m "feat: add TrailingManager with break even and trailing stop"
```

---

### Task 6: TimeFilter — Trading Hours

**Files:**
- Create: `Include/GoldScalper/TimeFilter.mqh`

- [ ] **Step 1: Create `Include/GoldScalper/TimeFilter.mqh`**

```mql5
//+------------------------------------------------------------------+
//|                                                   TimeFilter.mqh |
//|                                                      GoldScalper |
//+------------------------------------------------------------------+
#ifndef TIME_FILTER_MQH
#define TIME_FILTER_MQH

#include "Defines.mqh"

class CTimeFilter
{
public:
   // Public value for dashboard
   bool InTimeWindow;

   bool Init();
   bool IsTradeAllowed();
};

//+------------------------------------------------------------------+
bool CTimeFilter::Init()
{
   InTimeWindow = true;
   return true;
}

//+------------------------------------------------------------------+
bool CTimeFilter::IsTradeAllowed()
{
   if(!InpUseTimeFilter)
   {
      InTimeWindow = true;
      return true;
   }

   MqlDateTime dt;
   TimeCurrent(dt);

   int currentMinutes = dt.hour * 60 + dt.min;
   int startMinutes   = InpTradeStartHour * 60 + InpTradeStartMinute;
   int endMinutes     = InpTradeEndHour * 60 + InpTradeEndMinute;

   // Handle overnight windows (e.g., 22:00 - 06:00)
   if(startMinutes < endMinutes)
      InTimeWindow = (currentMinutes >= startMinutes && currentMinutes < endMinutes);
   else
      InTimeWindow = (currentMinutes >= startMinutes || currentMinutes < endMinutes);

   return InTimeWindow;
}

#endif
```

- [ ] **Step 2: Commit**

```bash
git add Include/GoldScalper/TimeFilter.mqh
git commit -m "feat: add TimeFilter for trading hours restriction"
```

---

### Task 7: NewsFilter — Economic Calendar

**Files:**
- Create: `Include/GoldScalper/NewsFilter.mqh`

- [ ] **Step 1: Create `Include/GoldScalper/NewsFilter.mqh`**

```mql5
//+------------------------------------------------------------------+
//|                                                   NewsFilter.mqh |
//|                                                      GoldScalper |
//+------------------------------------------------------------------+
#ifndef NEWS_FILTER_MQH
#define NEWS_FILTER_MQH

#include "Defines.mqh"

class CNewsFilter
{
private:
   datetime m_newsEvents[];
   string   m_newsNames[];
   int      m_newsCount;
   datetime m_lastRefresh;

   void LoadNewsEvents();

public:
   // Public values for dashboard
   string   NextNewsName;
   datetime NextNewsTime;
   bool     IsNewsBlocked;

   bool Init();
   bool IsTradeAllowed();
};

//+------------------------------------------------------------------+
bool CNewsFilter::Init()
{
   m_newsCount   = 0;
   m_lastRefresh = 0;
   NextNewsName  = "";
   NextNewsTime  = 0;
   IsNewsBlocked = false;

   if(InpUseNewsFilter)
      LoadNewsEvents();

   return true;
}

//+------------------------------------------------------------------+
void CNewsFilter::LoadNewsEvents()
{
   m_newsCount = 0;
   ArrayResize(m_newsEvents, 0);
   ArrayResize(m_newsNames, 0);

   MqlCalendarValue values[];
   datetime startTime = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   datetime endTime   = startTime + 86400;

   if(CalendarValueHistory(values, startTime, endTime, NULL, NULL) > 0)
   {
      for(int i = 0; i < ArraySize(values); i++)
      {
         MqlCalendarEvent event;
         if(!CalendarEventById(values[i].event_id, event))
            continue;

         MqlCalendarCountry country;
         if(!CalendarCountryById(event.country_id, country))
            continue;

         // Filter USD news only (relevant to XAUUSD)
         if(country.currency != "USD")
            continue;

         // Filter by impact level
         bool passImpact = false;
         switch(InpNewsImpact)
         {
            case NEWS_HIGH:   passImpact = (event.importance == CALENDAR_IMPORTANCE_HIGH);     break;
            case NEWS_MEDIUM: passImpact = (event.importance >= CALENDAR_IMPORTANCE_MODERATE); break;
            case NEWS_ALL:    passImpact = true;                                                break;
         }

         if(!passImpact)
            continue;

         m_newsCount++;
         ArrayResize(m_newsEvents, m_newsCount);
         ArrayResize(m_newsNames, m_newsCount);
         m_newsEvents[m_newsCount - 1] = values[i].time;
         m_newsNames[m_newsCount - 1]  = event.name;
      }
   }

   m_lastRefresh = TimeCurrent();
   Print(EA_NAME, ": Loaded ", m_newsCount, " USD news events for today");
}

//+------------------------------------------------------------------+
bool CNewsFilter::IsTradeAllowed()
{
   if(!InpUseNewsFilter)
   {
      IsNewsBlocked = false;
      return true;
   }

   // Refresh news every hour
   if(TimeCurrent() - m_lastRefresh > 3600)
      LoadNewsEvents();

   datetime now = TimeCurrent();
   IsNewsBlocked = false;
   NextNewsName  = "";
   NextNewsTime  = 0;

   for(int i = 0; i < m_newsCount; i++)
   {
      datetime newsTime   = m_newsEvents[i];
      datetime blockStart = newsTime - InpNewsMinsBefore * 60;
      datetime blockEnd   = newsTime + InpNewsMinsAfter * 60;

      // Track next upcoming news for dashboard
      if(newsTime > now && (NextNewsTime == 0 || newsTime < NextNewsTime))
      {
         NextNewsTime = newsTime;
         NextNewsName = m_newsNames[i];
      }

      // Check if currently in blocked window
      if(now >= blockStart && now <= blockEnd)
      {
         IsNewsBlocked = true;
         return false;
      }
   }

   return true;
}

#endif
```

- [ ] **Step 2: Commit**

```bash
git add Include/GoldScalper/NewsFilter.mqh
git commit -m "feat: add NewsFilter using MQL5 Economic Calendar"
```

---

### Task 8: Dashboard — On-Chart Display

**Files:**
- Create: `Include/GoldScalper/Dashboard.mqh`

- [ ] **Step 1: Create `Include/GoldScalper/Dashboard.mqh`**

```mql5
//+------------------------------------------------------------------+
//|                                                    Dashboard.mqh |
//|                                                      GoldScalper |
//+------------------------------------------------------------------+
#ifndef DASHBOARD_MQH
#define DASHBOARD_MQH

#include "Defines.mqh"

//--- Data struct passed from main EA to dashboard
struct SDashboardData
{
   bool        eaActive;
   string      stopReason;
   double      dailyPL;
   double      dailyPLPercent;
   double      dailyDD;
   double      dailyDDMax;
   int         openOrders;
   int         maxOrders;
   long        currentSpread;
   int         maxSpread;
   bool        trendUp;
   double      emaTrendFast;
   double      emaTrendSlow;
   double      emaFast;
   double      emaSlow;
   double      rsi;
   ENUM_SIGNAL signal;
   string      nextNewsName;
   datetime    nextNewsTime;
   bool        inTimeWindow;
};

class CDashboard
{
private:
   string m_prefix;
   int    m_startX;
   int    m_startY;
   int    m_lineHeight;
   int    m_fontSize;
   string m_fontName;

   void CreateLabel(string name, int x, int y, string text, color clr);

public:
   bool Init();
   void Update(const SDashboardData &data);
   void Destroy();
};

//+------------------------------------------------------------------+
bool CDashboard::Init()
{
   m_prefix     = EA_NAME + "_dash_";
   m_startX     = 10;
   m_startY     = 30;
   m_lineHeight = 20;
   m_fontSize   = 9;
   m_fontName   = "Consolas";
   return true;
}

//+------------------------------------------------------------------+
void CDashboard::CreateLabel(string name, int x, int y, string text, color clr)
{
   string fullName = m_prefix + name;

   if(ObjectFind(0, fullName) < 0)
   {
      ObjectCreate(0, fullName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, fullName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, fullName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetString(0, fullName, OBJPROP_FONT, m_fontName);
      ObjectSetInteger(0, fullName, OBJPROP_FONTSIZE, m_fontSize);
      ObjectSetInteger(0, fullName, OBJPROP_SELECTABLE, false);
   }

   ObjectSetInteger(0, fullName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, fullName, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, fullName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, fullName, OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
void CDashboard::Update(const SDashboardData &data)
{
   int x = m_startX;
   int y = m_startY;

   // Header
   CreateLabel("header", x, y, "=== " + EA_NAME + " v" + EA_VERSION + " ===", clrWhite);
   y += m_lineHeight;

   // EA Status
   string statusText = data.eaActive ? "ACTIVE" : ("STOPPED - " + data.stopReason);
   color  statusClr  = data.eaActive ? clrLime : clrRed;
   CreateLabel("status", x, y, "Status: " + statusText, statusClr);
   y += m_lineHeight;

   // Account Info
   CreateLabel("account", x, y,
      StringFormat("Balance: %.2f  |  Equity: %.2f  |  Free: %.2f",
         AccountInfoDouble(ACCOUNT_BALANCE),
         AccountInfoDouble(ACCOUNT_EQUITY),
         AccountInfoDouble(ACCOUNT_MARGIN_FREE)),
      clrWhite);
   y += m_lineHeight;

   // Today P&L
   color plClr = (data.dailyPL >= 0) ? clrLime : clrRed;
   CreateLabel("pnl", x, y,
      StringFormat("Today P&L: %+.2f  (%.2f%%)", data.dailyPL, data.dailyPLPercent),
      plClr);
   y += m_lineHeight;

   // Daily Drawdown
   color ddClr = clrLime;
   if(data.dailyDD >= data.dailyDDMax * 0.7) ddClr = clrYellow;
   if(data.dailyDD >= data.dailyDDMax)        ddClr = clrRed;
   CreateLabel("drawdown", x, y,
      StringFormat("Drawdown: %.2f%% / %.2f%%", data.dailyDD, data.dailyDDMax),
      ddClr);
   y += m_lineHeight;

   // Open Orders
   color ordClr = (data.openOrders < data.maxOrders) ? clrWhite : clrYellow;
   CreateLabel("orders", x, y,
      StringFormat("Orders: %d / %d", data.openOrders, data.maxOrders),
      ordClr);
   y += m_lineHeight;

   // Spread
   color spClr = (data.currentSpread <= data.maxSpread) ? clrLime : clrRed;
   CreateLabel("spread", x, y,
      StringFormat("Spread: %d / %d", data.currentSpread, data.maxSpread),
      spClr);
   y += m_lineHeight;

   // Trend M15
   string trendText = data.trendUp ? "UP" : "DOWN";
   color  trendClr  = data.trendUp ? clrLime : clrRed;
   CreateLabel("trend", x, y,
      StringFormat("Trend M15: %s  (EMA%d: %.2f  |  EMA%d: %.2f)",
         trendText, InpEmaTrendFast, data.emaTrendFast, InpEmaTrendSlow, data.emaTrendSlow),
      trendClr);
   y += m_lineHeight;

   // Signal M5
   string sigText;
   color  sigClr;
   switch(data.signal)
   {
      case SIGNAL_BUY:  sigText = "BUY";  sigClr = clrLime; break;
      case SIGNAL_SELL: sigText = "SELL"; sigClr = clrRed;  break;
      default:          sigText = "WAIT"; sigClr = clrGray; break;
   }
   CreateLabel("signal", x, y,
      StringFormat("Signal M5: %s  (EMA%d: %.2f  |  EMA%d: %.2f  |  RSI: %.1f)",
         sigText, InpEmaFastPeriod, data.emaFast, InpEmaSlowPeriod, data.emaSlow, data.rsi),
      sigClr);
   y += m_lineHeight;

   // Next News
   if(InpUseNewsFilter)
   {
      string newsText = (data.nextNewsTime > 0)
         ? TimeToString(data.nextNewsTime, TIME_MINUTES) + " - " + data.nextNewsName
         : "No news today";
      color newsClr = (data.nextNewsTime > 0 && data.nextNewsTime - TimeCurrent() < InpNewsMinsBefore * 60)
         ? clrYellow : clrWhite;
      CreateLabel("news", x, y, "Next News: " + newsText, newsClr);
      y += m_lineHeight;
   }

   // Time Filter
   if(InpUseTimeFilter)
   {
      string tfStatus = data.inTimeWindow ? "IN" : "OUT";
      color  tfClr    = data.inTimeWindow ? clrLime : clrYellow;
      CreateLabel("timefilter", x, y,
         StringFormat("Time: %02d:%02d - %02d:%02d  [%s]",
            InpTradeStartHour, InpTradeStartMinute,
            InpTradeEndHour, InpTradeEndMinute, tfStatus),
         tfClr);
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
void CDashboard::Destroy()
{
   ObjectsDeleteAll(0, m_prefix);
   ChartRedraw(0);
}

#endif
```

- [ ] **Step 2: Commit**

```bash
git add Include/GoldScalper/Dashboard.mqh
git commit -m "feat: add Dashboard with on-chart OBJ_LABEL display"
```

---

### Task 9: GoldScalper.mq5 — Main EA Orchestrator

**Files:**
- Create: `Experts/GoldScalper/GoldScalper.mq5`

- [ ] **Step 1: Create `Experts/GoldScalper/GoldScalper.mq5`**

```mql5
//+------------------------------------------------------------------+
//|                                                  GoldScalper.mq5 |
//|                                                      GoldScalper |
//|                 Scalping EA for XAUUSD - EMA Crossover + RSI     |
//+------------------------------------------------------------------+
#property copyright   EA_NAME
#property link        ""
#property version     "1.00"
#property description "Scalping EA for XAUUSD using Multi-timeframe EMA + RSI"
#property strict

#include <GoldScalper/Defines.mqh>
#include <GoldScalper/SignalManager.mqh>
#include <GoldScalper/TradeManager.mqh>
#include <GoldScalper/RiskManager.mqh>
#include <GoldScalper/TrailingManager.mqh>
#include <GoldScalper/TimeFilter.mqh>
#include <GoldScalper/NewsFilter.mqh>
#include <GoldScalper/Dashboard.mqh>

//--- Manager instances
CSignalManager   g_signalMgr;
CTradeManager    g_tradeMgr;
CRiskManager     g_riskMgr;
CTrailingManager g_trailingMgr;
CTimeFilter      g_timeFilter;
CNewsFilter      g_newsFilter;
CDashboard       g_dashboard;

//+------------------------------------------------------------------+
int OnInit()
{
   // Validate symbol
   if(StringFind(_Symbol, "XAU") < 0 && StringFind(_Symbol, "GOLD") < 0)
      Print(EA_NAME, ": WARNING - This EA is designed for XAUUSD. Current symbol: ", _Symbol);

   // Initialize all managers
   if(!g_signalMgr.Init(_Symbol))    { Print(EA_NAME, ": SignalManager init failed");   return INIT_FAILED; }
   if(!g_tradeMgr.Init(_Symbol))     { Print(EA_NAME, ": TradeManager init failed");    return INIT_FAILED; }
   if(!g_riskMgr.Init(_Symbol))      { Print(EA_NAME, ": RiskManager init failed");     return INIT_FAILED; }
   if(!g_trailingMgr.Init(_Symbol))  { Print(EA_NAME, ": TrailingManager init failed"); return INIT_FAILED; }
   if(!g_timeFilter.Init())          { Print(EA_NAME, ": TimeFilter init failed");      return INIT_FAILED; }
   if(!g_newsFilter.Init())          { Print(EA_NAME, ": NewsFilter init failed");       return INIT_FAILED; }
   if(!g_dashboard.Init())           { Print(EA_NAME, ": Dashboard init failed");        return INIT_FAILED; }

   // Timer for dashboard refresh when no ticks
   EventSetTimer(1);

   Print(EA_NAME, " v", EA_VERSION, " initialized on ", _Symbol);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   g_signalMgr.Deinit();
   g_dashboard.Destroy();
   EventKillTimer();
   Print(EA_NAME, " deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
void OnTick()
{
   // Track EA state for dashboard
   bool   eaActive   = true;
   string stopReason = "";

   //--- 1. Time Filter
   if(!g_timeFilter.IsTradeAllowed())
   {
      eaActive   = false;
      stopReason = "Outside trading hours";
      if(InpCloseOutsideTime)
         g_tradeMgr.CloseAll();
   }

   //--- 2. News Filter
   if(eaActive && !g_newsFilter.IsTradeAllowed())
   {
      eaActive   = false;
      stopReason = "News event";
      if(InpCloseBeforeNews)
         g_tradeMgr.CloseAll();
   }

   //--- 3. Daily Drawdown
   if(eaActive && g_riskMgr.IsDailyDrawdownExceeded())
   {
      eaActive   = false;
      stopReason = "Daily drawdown limit";
      if(InpDDAction == DD_CLOSE_ALL)
         g_tradeMgr.CloseAll();
   }

   //--- 4. Manage existing orders (trailing + break even) - always runs
   g_trailingMgr.ManageOrders();

   //--- 5. Check signal and open trades
   ENUM_SIGNAL signal = g_signalMgr.CheckSignal();

   if(eaActive && signal != SIGNAL_NONE)
   {
      // Close opposite orders if enabled
      if(InpCloseOnOpposite)
      {
         if(signal == SIGNAL_BUY)  g_tradeMgr.CloseAllSell();
         if(signal == SIGNAL_SELL) g_tradeMgr.CloseAllBuy();
      }

      // Check order limit and spread
      if(g_tradeMgr.CountOpenOrders() < InpMaxOpenOrders && g_tradeMgr.IsSpreadOK())
      {
         double lotSize = g_riskMgr.CalculateLot();

         if(signal == SIGNAL_BUY)
            g_tradeMgr.OpenBuy(lotSize, InpStopLoss, InpTakeProfit);
         else if(signal == SIGNAL_SELL)
            g_tradeMgr.OpenSell(lotSize, InpStopLoss, InpTakeProfit);
      }
   }

   //--- 6. Update Dashboard
   UpdateDashboard(eaActive, stopReason, signal);
}

//+------------------------------------------------------------------+
void OnTimer()
{
   // Refresh dashboard even when no ticks arrive
   g_riskMgr.UpdateDailyStats();
   ENUM_SIGNAL signal = g_signalMgr.CheckSignal();
   bool eaActive = g_timeFilter.IsTradeAllowed() && !g_newsFilter.IsNewsBlocked && !g_riskMgr.IsStopped;
   string stopReason = "";
   if(!g_timeFilter.InTimeWindow) stopReason = "Outside trading hours";
   else if(g_newsFilter.IsNewsBlocked) stopReason = "News event";
   else if(g_riskMgr.IsStopped) stopReason = "Daily drawdown limit";

   UpdateDashboard(eaActive, stopReason, signal);
}

//+------------------------------------------------------------------+
void UpdateDashboard(bool eaActive, string stopReason, ENUM_SIGNAL signal)
{
   g_riskMgr.UpdateDailyStats();

   SDashboardData data;
   data.eaActive      = eaActive;
   data.stopReason    = stopReason;
   data.dailyPL       = g_riskMgr.DailyPL;
   data.dailyPLPercent = g_riskMgr.DailyPLPercent;
   data.dailyDD       = g_riskMgr.DailyDrawdownPercent;
   data.dailyDDMax    = InpMaxDailyDDPercent;
   data.openOrders    = g_tradeMgr.CountOpenOrders();
   data.maxOrders     = InpMaxOpenOrders;
   data.currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   data.maxSpread     = InpMaxSpread;
   data.trendUp       = g_signalMgr.TrendUp;
   data.emaTrendFast  = g_signalMgr.EmaTrendFastValue;
   data.emaTrendSlow  = g_signalMgr.EmaTrendSlowValue;
   data.emaFast       = g_signalMgr.EmaFastValue;
   data.emaSlow       = g_signalMgr.EmaSlowValue;
   data.rsi           = g_signalMgr.RsiValue;
   data.signal        = signal;
   data.nextNewsName  = g_newsFilter.NextNewsName;
   data.nextNewsTime  = g_newsFilter.NextNewsTime;
   data.inTimeWindow  = g_timeFilter.InTimeWindow;

   g_dashboard.Update(data);
}
//+------------------------------------------------------------------+
```

- [ ] **Step 2: Commit**

```bash
git add Experts/GoldScalper/GoldScalper.mq5
git commit -m "feat: add GoldScalper.mq5 main EA orchestrator"
```

---

### Task 10: Deployment & Testing

**Files:**
- No new files — verification and testing instructions

- [ ] **Step 1: Copy files to MetaTrader 5 data folder**

Open MetaTrader 5 → File → Open Data Folder. This opens the `MQL5` directory. Copy the project files:

```
MQL5/
├── Experts/GoldScalper/GoldScalper.mq5     ← copy from project
└── Include/GoldScalper/
    ├── Defines.mqh                          ← copy from project
    ├── SignalManager.mqh
    ├── TradeManager.mqh
    ├── RiskManager.mqh
    ├── TrailingManager.mqh
    ├── TimeFilter.mqh
    ├── NewsFilter.mqh
    └── Dashboard.mqh
```

- [ ] **Step 2: Compile in MetaEditor**

Open MetaEditor (F4 from MT5) → Open `Experts/GoldScalper/GoldScalper.mq5` → Press Compile (F7).

Expected: 0 errors. Warnings about unused variables are acceptable.

If there are errors, check:
- All `.mqh` files are in `Include/GoldScalper/`
- The `#include <GoldScalper/...>` paths resolve correctly

- [ ] **Step 3: Test in Strategy Tester — visual mode**

Open Strategy Tester (Ctrl+R) with these settings:
- Expert: `GoldScalper`
- Symbol: `XAUUSD`
- Period: `M5`
- Model: `Every tick`
- Date: last 1 month
- Visual mode: ON

Verify:
1. EA attaches and shows dashboard on chart
2. Dashboard displays all 10 rows of information
3. EA opens Buy/Sell orders according to signal conditions
4. SL and TP are set correctly
5. Break Even triggers when price moves enough
6. Trailing Stop kicks in after Break Even
7. Time Filter blocks orders outside configured hours
8. News Filter blocks orders around USD news events
9. Daily Drawdown stops trading when limit is hit
10. Max Open Orders limit is respected

- [ ] **Step 4: Test on Demo Account**

Attach EA to a live XAUUSD M5 chart on a demo account. Monitor for at least one trading session (London or New York) to verify:
- Signals fire correctly in real market conditions
- Spread filter works with live spreads
- News filter loads actual economic calendar data
- Dashboard updates in real-time

- [ ] **Step 5: Commit final state**

```bash
git add -A
git commit -m "docs: add deployment and testing instructions"
```
