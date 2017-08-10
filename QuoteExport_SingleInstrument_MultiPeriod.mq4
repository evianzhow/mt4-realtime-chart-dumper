//+------------------------------------------------------------------+
//| QuoteExport_SingleInstrument_MultiPeriod.mq4
//| Copyright 2017, Evian Zhow
//| blog.evianzhow.com
//+------------------------------------------------------------------+
#property copyright   "Copyright 2017, Evian Zhow"
#property link        "blog.evianzhow.com"
#property description "This EA automatically exports selected instrument candle"
#property description "charts w/ different periods as multiple CSV files to "
#property description "MQL4\\Files folder."

#include "Helper_Functions.mq4"
#include <stdlib.mqh>

//--- input parameters
extern string    TimeZoneOffsetFromUTC="+8";
extern string    Instrument="XAUUSD";
extern bool      Debug=false;

string name;

int periods[] = { PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1 };

//+------------------------------------------------------------------+
//| configure max bars to be read                                    |
//+------------------------------------------------------------------+
int maxBarsToRead (int period) {
  switch (period) {
    case PERIOD_M1:  return (1000);
    case PERIOD_M5:  return (1000);
    case PERIOD_M15: return (1000);
    case PERIOD_M30: return (1000);
    case PERIOD_H1:  return (720);
    case PERIOD_H4:  return (180);
    case PERIOD_D1:  return (120);
    case PERIOD_W1:  return (60);
    case PERIOD_MN1: return (36);
  }
      
  return (0);
}

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  name = "QuoteExport_SingleInstrument_MultiPeriod";

  int err = 0;

  if (IsConnected() == false) {
    Alert("You must be connected to the server first!");
    return (INIT_FAILED);
  }

  if (Symbol() != Instrument) {
    Alert("Attach this EA to a different chart will cause delay in receiving ticks!");
    return (INIT_FAILED);
  }

  err = checkHistoryAvailability();
  if (err != 0) {
    Alert("Error " + err + " - Unable to update local history files!. Please re-run the script later.");
    return (INIT_FAILED);
  }

  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  if (reason == REASON_INITFAILED) {
    IF_DEBUG_THEN Alert("OnInit failed!");
  }
  return;
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
  if (Symbol() != Instrument) {
    return;
  }

  int err = saveHistory(Instrument);
  if (err != 0) {
    IF_DEBUG_THEN Alert("Error " + err + " - Saving failed!");
  }

  return;
}

//+------------------------------------------------------------------+
//| check history availability                                       |
//+------------------------------------------------------------------+
int checkHistoryAvailability() {
  int err;
  int periodsCount = ArraySize(periods);

  for (int i = 0; i < periodsCount; i++) {
    int pause = 5;

    while (true) {
      int getBars = iBars(Instrument, periods[i]);
      int maxBars = maxBarsToRead(periods[i]);
      int bars = maxBars;

      if (getBars < maxBars) bars = getBars;
      err = GetLastError();

      if (err != 0 || bars < maxBars) {
        IF_DEBUG_THEN Alert("Local history files are being updated from server. Attempting again in " + pause + " seconds...");
        Sleep(pause * 1000);
        pause += 2;
      } else {
        IF_DEBUG_THEN Alert("Successfully loaded " + shortPeriodDescriptionFromConstant(periods[i]) + " history files.");
        break;
      }
    }
  }
  
  return err;
}

//+------------------------------------------------------------------+
//| save history                                                     |
//+------------------------------------------------------------------+
int saveHistory(string symbol)
{
  double O, H, L, C, T;
  int periodsCount = ArraySize(periods);
  for (int i = 0; i < periodsCount; i++) {
    int availableBars = iBars(symbol, periods[i]);

    int handle = FileOpen(fileNameFromSymbolAndPeriod(symbol, periods[i]), FILE_CSV|FILE_WRITE, ',');

    FileWrite(handle, "date", "open", "high", "low", "close");
    for (int k = 0; k < availableBars; k++) {
      if (handle <= 0) continue;

      O = iOpen(symbol, periods[i], k);
      H = iHigh(symbol, periods[i], k);      
      L = iLow(symbol, periods[i], k);      
      C = iClose(symbol, periods[i], k);               
      T = iTime(symbol, periods[i], k);

      string date = TimeToStr(T, TIME_DATE|TIME_SECONDS);
      StringReplace(date, " ", "T"); StringReplace(date, ".", "-");
      date += timeZoneISOStandard(TimeZoneOffsetFromUTC); // Exported as ISO 8601 Standard
      FileWrite(handle, date, O, H, L, C);
    }
    FileClose(handle);
  }
  return (GetLastError());
}