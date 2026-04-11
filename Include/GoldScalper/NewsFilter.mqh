//+------------------------------------------------------------------+
//|                                                   NewsFilter.mqh |
//|                                                      GoldScalper |
//+------------------------------------------------------------------+
#ifndef NEWS_FILTER_MQH
#define NEWS_FILTER_MQH

#include "Defines.mqh"

class CNewsFilter
{
private:
   datetime m_newsEvents[];
   string   m_newsNames[];
   int      m_newsCount;
   datetime m_lastRefresh;

   void LoadNewsEvents();

public:
   // Public values for dashboard
   string   NextNewsName;
   datetime NextNewsTime;
   bool     IsNewsBlocked;

   bool Init();
   bool IsTradeAllowed();
};

//+------------------------------------------------------------------+
bool CNewsFilter::Init()
{
   m_newsCount   = 0;
   m_lastRefresh = 0;
   NextNewsName  = "";
   NextNewsTime  = 0;
   IsNewsBlocked = false;

   if(InpUseNewsFilter)
      LoadNewsEvents();

   return true;
}

//+------------------------------------------------------------------+
void CNewsFilter::LoadNewsEvents()
{
   m_newsCount = 0;
   ArrayResize(m_newsEvents, 0);
   ArrayResize(m_newsNames, 0);

   MqlCalendarValue values[];
   datetime startTime = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   datetime endTime   = startTime + 86400;

   if(CalendarValueHistory(values, startTime, endTime, NULL, NULL) > 0)
   {
      for(int i = 0; i < ArraySize(values); i++)
      {
         MqlCalendarEvent event;
         if(!CalendarEventById(values[i].event_id, event))
            continue;

         MqlCalendarCountry country;
         if(!CalendarCountryById(event.country_id, country))
            continue;

         // Filter USD news only (relevant to XAUUSD)
         if(country.currency != "USD")
            continue;

         // Filter by impact level
         bool passImpact = false;
         switch(InpNewsImpact)
         {
            case NEWS_HIGH:   passImpact = (event.importance == CALENDAR_IMPORTANCE_HIGH);     break;
            case NEWS_MEDIUM: passImpact = (event.importance >= CALENDAR_IMPORTANCE_MODERATE); break;
            case NEWS_ALL:    passImpact = true;                                                break;
         }

         if(!passImpact)
            continue;

         m_newsCount++;
         ArrayResize(m_newsEvents, m_newsCount);
         ArrayResize(m_newsNames, m_newsCount);
         m_newsEvents[m_newsCount - 1] = values[i].time;
         m_newsNames[m_newsCount - 1]  = event.name;
      }
   }

   m_lastRefresh = TimeCurrent();
   Print(EA_NAME, ": Loaded ", m_newsCount, " USD news events for today");
}

//+------------------------------------------------------------------+
bool CNewsFilter::IsTradeAllowed()
{
   if(!InpUseNewsFilter)
   {
      IsNewsBlocked = false;
      return true;
   }

   // Refresh news every hour
   if(TimeCurrent() - m_lastRefresh > 3600)
      LoadNewsEvents();

   datetime now = TimeCurrent();
   IsNewsBlocked = false;
   NextNewsName  = "";
   NextNewsTime  = 0;

   for(int i = 0; i < m_newsCount; i++)
   {
      datetime newsTime   = m_newsEvents[i];
      datetime blockStart = newsTime - InpNewsMinsBefore * 60;
      datetime blockEnd   = newsTime + InpNewsMinsAfter * 60;

      // Track next upcoming news for dashboard
      if(newsTime > now && (NextNewsTime == 0 || newsTime < NextNewsTime))
      {
         NextNewsTime = newsTime;
         NextNewsName = m_newsNames[i];
      }

      // Check if currently in blocked window
      if(now >= blockStart && now <= blockEnd)
      {
         IsNewsBlocked = true;
         return false;
      }
   }

   return true;
}

#endif
