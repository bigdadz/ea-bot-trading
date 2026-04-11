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
   int    m_atrHandle;          // ATR on M5
   string m_symbol;

   double m_emaFast[];
   double m_emaSlow[];
   double m_emaTrendFast[];
   double m_emaTrendSlow[];
   double m_rsi[];
   double m_atr[];

public:
   // Public values for dashboard
   double EmaFastValue;
   double EmaSlowValue;
   double EmaTrendFastValue;
   double EmaTrendSlowValue;
   double RsiValue;
   bool   TrendUp;
   double AtrValue;

   bool        Init(string symbol);
   void        Deinit();
   ENUM_SIGNAL CheckSignal();
   double      GetATR();
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
   m_atrHandle          = iATR(m_symbol, PERIOD_M5, InpAtrPeriod);

   if(m_emaFastHandle == INVALID_HANDLE || m_emaSlowHandle == INVALID_HANDLE ||
      m_emaTrendFastHandle == INVALID_HANDLE || m_emaTrendSlowHandle == INVALID_HANDLE ||
      m_rsiHandle == INVALID_HANDLE || m_atrHandle == INVALID_HANDLE)
   {
      Print(EA_NAME, ": Failed to create indicator handles");
      return false;
   }

   ArraySetAsSeries(m_emaFast, true);
   ArraySetAsSeries(m_emaSlow, true);
   ArraySetAsSeries(m_emaTrendFast, true);
   ArraySetAsSeries(m_emaTrendSlow, true);
   ArraySetAsSeries(m_rsi, true);
   ArraySetAsSeries(m_atr, true);

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
   if(m_atrHandle != INVALID_HANDLE)          IndicatorRelease(m_atrHandle);
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

#endif
