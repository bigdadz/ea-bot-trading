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
