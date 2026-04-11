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
