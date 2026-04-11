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
