//+------------------------------------------------------------------+
//|                                                  GoldScalper.mq5 |
//|                                                      GoldScalper |
//|                 Scalping EA for XAUUSD - EMA Crossover + RSI     |
//+------------------------------------------------------------------+
#property copyright   "GoldScalper"
#property link        ""
#property version     "1.01"
#property description "Scalping EA for XAUUSD using Multi-timeframe EMA + RSI"

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

//--- New bar detection
datetime g_lastBarTime = 0;

//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 0);
   if(currentBarTime != g_lastBarTime)
   {
      g_lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

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
   if(InpSlTpMode == SLTP_ATR)
      Print(EA_NAME, ": Mode=ATR | SL=ATR*", DoubleToString(InpAtrSlMultiplier, 1),
            " | TP=ATR*", DoubleToString(InpAtrTpMultiplier, 1),
            " | ATR Period=", InpAtrPeriod,
            " | POINT=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_POINT), _Digits));
   else
      Print(EA_NAME, ": Mode=Fixed | SL=", InpStopLoss, " pts ($", DoubleToString(InpStopLoss * SymbolInfoDouble(_Symbol, SYMBOL_POINT), 2),
            ") | TP=", InpTakeProfit, " pts ($", DoubleToString(InpTakeProfit * SymbolInfoDouble(_Symbol, SYMBOL_POINT), 2),
            ") | POINT=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_POINT), _Digits));
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
   bool newBar = IsNewBar();

   // Track EA state for dashboard
   bool   eaActive   = true;
   string stopReason = "";

   //--- 1. Time Filter
   bool timeOK = g_timeFilter.IsTradeAllowed();
   if(!timeOK)
   {
      eaActive   = false;
      stopReason = "Outside trading hours";
      if(InpCloseOutsideTime)
         g_tradeMgr.CloseAll();
   }

   //--- 2. News Filter
   bool newsOK = true;
   if(eaActive)
   {
      newsOK = g_newsFilter.IsTradeAllowed();
      if(!newsOK)
      {
         eaActive   = false;
         stopReason = "News event";
         if(InpCloseBeforeNews)
            g_tradeMgr.CloseAll();
      }
   }

   //--- 3. Daily Drawdown
   bool ddOK = true;
   if(eaActive)
   {
      ddOK = !g_riskMgr.IsDailyDrawdownExceeded();
      if(!ddOK)
      {
         eaActive   = false;
         stopReason = "Daily drawdown limit";
         if(InpDDAction == DD_CLOSE_ALL)
            g_tradeMgr.CloseAll();
      }
   }

   //--- 4. Get ATR value
   double atrValue = g_signalMgr.GetATR();

   //--- 5. Manage existing orders (trailing + break even) - always runs
   g_trailingMgr.ManageOrders(atrValue);

   //--- 6. Check signal and open trades (only on new bar to avoid repeated attempts)
   ENUM_SIGNAL signal = g_signalMgr.CheckSignal();

   if(eaActive && signal != SIGNAL_NONE && newBar)
   {
      if(InpDebugMode)
         Print(EA_NAME, ": >>> SIGNAL detected: ", (signal == SIGNAL_BUY ? "BUY" : "SELL"),
               " | Spread: ", SymbolInfoInteger(_Symbol, SYMBOL_SPREAD),
               " | Orders: ", g_tradeMgr.CountOpenOrders(), "/", InpMaxOpenOrders);

      // Close opposite orders if enabled
      if(InpCloseOnOpposite)
      {
         if(signal == SIGNAL_BUY)  g_tradeMgr.CloseAllSell();
         if(signal == SIGNAL_SELL) g_tradeMgr.CloseAllBuy();
      }

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
      else if(InpDebugMode)
      {
         if(!stopsOK)     Print(EA_NAME, ": Signal BLOCKED - SL/TP too small for current market conditions");
         if(!spreadOK)    Print(EA_NAME, ": Signal BLOCKED - Spread too high: ", SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), " > ", InpMaxSpread);
         if(!orderLimitOK) Print(EA_NAME, ": Signal BLOCKED - Max orders reached");
      }
   }

   //--- 7. Debug logging on new M5 bar
   if(newBar && InpDebugMode)
   {
      string signalStr = (signal == SIGNAL_BUY) ? "BUY" : (signal == SIGNAL_SELL) ? "SELL" : "NONE";
      string trendStr  = g_signalMgr.TrendUp ? "UP" : "DOWN";

      Print(EA_NAME, ": --- New Bar ", TimeToString(iTime(_Symbol, PERIOD_M5, 0)), " ---");
      Print(EA_NAME, ": Filters: Time=", (timeOK ? "OK" : "BLOCKED"),
            " | News=", (newsOK ? "OK" : "BLOCKED"),
            " | DD=", (ddOK ? "OK" : "BLOCKED"),
            " | Active=", (eaActive ? "YES" : "NO"));
      Print(EA_NAME, ": Trend M15: ", trendStr,
            " (EMA", InpEmaTrendFast, "=", DoubleToString(g_signalMgr.EmaTrendFastValue, 2),
            " | EMA", InpEmaTrendSlow, "=", DoubleToString(g_signalMgr.EmaTrendSlowValue, 2), ")");
      Print(EA_NAME, ": Signal M5: ", signalStr,
            " (EMA", InpEmaFastPeriod, "=", DoubleToString(g_signalMgr.EmaFastValue, 2),
            " | EMA", InpEmaSlowPeriod, "=", DoubleToString(g_signalMgr.EmaSlowValue, 2),
            " | RSI=", DoubleToString(g_signalMgr.RsiValue, 1), ")");
      Print(EA_NAME, ": Spread=", SymbolInfoInteger(_Symbol, SYMBOL_SPREAD),
            " | Orders=", g_tradeMgr.CountOpenOrders());
      if(InpSlTpMode == SLTP_ATR)
      {
         double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         int dbgSL = (atrValue > 0) ? (int)(atrValue * InpAtrSlMultiplier / point) : 0;
         int dbgTP = (atrValue > 0) ? (int)(atrValue * InpAtrTpMultiplier / point) : 0;
         Print(EA_NAME, ": ATR=$", DoubleToString(atrValue, 2),
               " | Dynamic SL=", dbgSL, " pts ($", DoubleToString(dbgSL * point, 2),
               ") | TP=", dbgTP, " pts ($", DoubleToString(dbgTP * point, 2), ")");
      }
   }

   //--- 7. Update Dashboard
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

   g_dashboard.Update(data);
}
//+------------------------------------------------------------------+
