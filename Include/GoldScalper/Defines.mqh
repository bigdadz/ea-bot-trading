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

//--- Input Parameters: Debug
input group "=== Debug ==="
input bool   InpDebugMode           = true;    // Debug Mode (log to Experts tab)

#endif
