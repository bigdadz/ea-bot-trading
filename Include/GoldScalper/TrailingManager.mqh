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
