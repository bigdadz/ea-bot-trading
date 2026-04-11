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
   double m_lastATR;

   bool IsBreakEvenApplied(ulong ticket);
   void MarkBreakEvenApplied(ulong ticket);
   void ApplyBreakEven(ulong ticket, ENUM_POSITION_TYPE type, double openPrice);
   void ApplyTrailingStop(ulong ticket, ENUM_POSITION_TYPE type, double openPrice, double currentSL);

public:
   bool Init(string symbol);
   void ManageOrders(double atrValue = 0);
};

//+------------------------------------------------------------------+
bool CTrailingManager::Init(string symbol)
{
   m_symbol = symbol;
   m_trade.SetExpertMagicNumber(EA_MAGIC);
   m_beCount = 0;
   ArrayResize(m_beApplied, 0);
   m_lastATR = 0;
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

//+------------------------------------------------------------------+
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
         if(currentSL == 0 || newSL < currentSL - trailStep * point)
         {
            double tp = PositionGetDouble(POSITION_TP);
            m_trade.PositionModify(ticket, newSL, tp);
         }
      }
   }
}

//+------------------------------------------------------------------+
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

         ApplyBreakEven(ticket, type, openPrice);

         if(m_position.SelectByIndex(i))
            currentSL = m_position.StopLoss();

         ApplyTrailingStop(ticket, type, openPrice, currentSL);
      }
   }
}

#endif
