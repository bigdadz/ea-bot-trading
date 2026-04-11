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
