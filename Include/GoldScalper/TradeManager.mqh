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
   bool ValidateStops(int slPoints, int tpPoints);
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

//+------------------------------------------------------------------+
bool CTradeManager::ValidateStops(int slPoints, int tpPoints)
{
   long   stopsLevel = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long   spread     = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
   long   minDist    = MathMax(stopsLevel, spread) + 10;  // +10 buffer

   bool valid = true;

   if(slPoints > 0 && slPoints < minDist)
   {
      Print(EA_NAME, ": ERROR - StopLoss (", slPoints, " pts) is below minimum distance (",
            minDist, " pts). StopsLevel=", stopsLevel, " Spread=", spread,
            ". Did you reset inputs in Strategy Tester? (Right-click Inputs → Reset)");
      valid = false;
   }

   if(tpPoints > 0 && tpPoints < minDist)
   {
      Print(EA_NAME, ": ERROR - TakeProfit (", tpPoints, " pts) is below minimum distance (",
            minDist, " pts). StopsLevel=", stopsLevel, " Spread=", spread,
            ". Did you reset inputs in Strategy Tester? (Right-click Inputs → Reset)");
      valid = false;
   }

   return valid;
}

#endif
