//+------------------------------------------------------------------+
//| QuoteExport_SingleInstrument_MultiPeriod.mq4
//| Copyright 2017, Evian Zhow
//| blog.evianzhow.com
//+------------------------------------------------------------------+
#property copyright   "Copyright 2017, Evian Zhow"
#property link        "blog.evianzhow.com"
#property description "This EA automatically exports selected instrument candle"
#property description "charts w/ different periods as multiple database SQL queries to "
#property description "MQL4\\Files folder."

#include "Helper_Functions.mq4"
#include <stdlib.mqh>
#include <SQLite3/Statement.mqh>

//--- input parameters
extern string    TimeZoneOffsetFromUTC="+8";
extern string    Instrument="XAUUSD";
extern bool      Debug=false;

string name;
SQLite3 *db;

// int periods[] = { PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1 };
int periods[] = { PERIOD_H1, PERIOD_D1 };

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

  //--- optional but recommended
  SQLite3::initialize();

  //--- ensure the dll and the lib is of the same version
  Print(SQLite3::getVersionNumber(), " = ", SQLITE_VERSION_NUMBER);
  Print(SQLite3::getVersion(), " = ", SQLITE_VERSION);
  Print(SQLite3::getSourceId(), " = ", SQLITE_SOURCE_ID);

  //--- create an empty db
  #ifdef __MQL5__
    string filesPath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files";
  #else
    string filesPath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL4\\Files";
  #endif
  string dbPath = filesPath + "\\data.db";

  db = new SQLite3(dbPath, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE);

  if (!db.isValid()) return (INIT_FAILED);
  string sql = "CREATE TABLE IF NOT EXISTS `candles` ("
                 "`Symbol`  TEXT NOT NULL,"
                 "`Timeframe` TEXT NOT NULL,"
                 "`Time`  INTEGER NOT NULL,"
                 "`Open`  REAL NOT NULL,"
                 "`High`  REAL NOT NULL,"
                 "`Low` REAL NOT NULL,"
                 "`Close` REAL NOT NULL,"
                 "PRIMARY KEY(`Symbol`,`Timeframe`,`Time`)"
               ");";

  if (!Statement::isComplete(sql)) return (INIT_FAILED);
  Statement s(db, sql);
  if (!s.isValid()) {
    Alert("Error - Failed to initialize sqlite db. " + db.getErrorMsg());
    return (INIT_FAILED);
  }
  int r = s.step();
  if (r == SQLITE_OK || r == SQLITE_DONE)
    Print("Notice - Initialize sqlite db finished.");
  else
    Alert("Error - Failed to execute statement: ", db.getErrorMsg());

  err = checkHistoryAvailability();
  if (err != 0) {
    Alert("Error " + err + " - Unable to update local history files!. Please re-run the script later.");
    return (INIT_FAILED);
  }

  err = saveHistory(Instrument);
  if (err != 0) {
    Alert("Error " + err + " - Initial candlesticks write failed!");
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

  delete db;
  //--- optional but recommended
  SQLite3::shutdown();

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

  int err = saveHistoryIncrement(Instrument);
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
    int pause = 3;

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

    if (!db.isValid()) return (INIT_FAILED);

    for (int k = 0; k < availableBars; k++) {
      O = iOpen(symbol, periods[i], k);
      H = iHigh(symbol, periods[i], k);      
      L = iLow(symbol, periods[i], k);      
      C = iClose(symbol, periods[i], k);               
      T = iTime(symbol, periods[i], k);

      string sql = "INSERT OR REPLACE INTO `candles`(Symbol, Timeframe, "
                   "Time, Open, High, Low, Close) VALUES ('" +
                   symbol + "','" +
                   shortPeriodDescriptionFromConstant(periods[i]) + "'," + 
                   IntegerToString(T) + "," +
                   DoubleToString(O, Digits) + "," +
                   DoubleToString(H, Digits) + "," +
                   DoubleToString(L, Digits) + "," +
                   DoubleToString(C, Digits) + ");";
      if (!Statement::isComplete(sql)) {
        IF_DEBUG_THEN Alert("Error - SQL Statement is not complete!");
        return (INIT_FAILED);
      }
      Statement s(db, sql);
      if (!s.isValid()) {
        IF_DEBUG_THEN Alert("Error - SQL Statement is not valid!");
        return (INIT_FAILED);
      }

      int r = s.step();
      if (r == SQLITE_OK)
        IF_DEBUG_THEN Print("Notice - Step finished.");
      else if (r == SQLITE_DONE)
        IF_DEBUG_THEN Print("Notice - SQL query succeeded.");
      else
        IF_DEBUG_THEN Alert("Error - Failed to execute statement: ", db.getErrorMsg());
    }
    touchBlankFile(symbol, periods[i]);
  }
  return (GetLastError());
}

//+------------------------------------------------------------------+
//| save history incrementally                                       |
//+------------------------------------------------------------------+
int saveHistoryIncrement(string symbol)
{
  double O, H, L, C, T;
  int periodsCount = ArraySize(periods);
  for (int i = 0; i < periodsCount; i++) {
    if (!db.isValid()) return (INIT_FAILED);
    int k = 0;
    while (1) {
      O = iOpen(symbol, periods[i], k);
      H = iHigh(symbol, periods[i], k);      
      L = iLow(symbol, periods[i], k);      
      C = iClose(symbol, periods[i], k);               
      T = iTime(symbol, periods[i], k);
      k++;

      string sql = "SELECT * FROM `candles` WHERE Symbol = '" + symbol + 
                   "' and Timeframe = '" + shortPeriodDescriptionFromConstant(periods[i])
                   + "' and Time = " + IntegerToString(T) + ";";
      if (!Statement::isComplete(sql)) {
        IF_DEBUG_THEN Alert("Error - SQL Statement is not complete!");
        return (INIT_FAILED);
      }
      Statement s(db, sql);
      if (!s.isValid()) {
        IF_DEBUG_THEN Alert("Error - SQL Statement is not valid!");
        return (INIT_FAILED);
      }

      int r = s.step();
      if (r != SQLITE_OK && r != SQLITE_DONE && r != SQLITE_ROW) {
        IF_DEBUG_THEN Alert("Error - Failed to execute statement: ", db.getErrorMsg());
        return (INIT_FAILED);
      }
      if (s.getDataCount() > 0) {
        // Already has this record
        double cO, cH, cL, cC;
        s.getColumn(3, cO); s.getColumn(4, cH); s.getColumn(5, cL); s.getColumn(6, cC);
        if (fabs(cO - O) <= epsilon && fabs(cH - H) <= epsilon && fabs(cL - L) <= epsilon && fabs(cC - C) <= epsilon) break;
      }
      // Insert
      string sql_ins = "INSERT OR REPLACE INTO `candles`(Symbol, Timeframe, "
                       "Time, Open, High, Low, Close) VALUES ('" +
                       symbol + "','" +
                       shortPeriodDescriptionFromConstant(periods[i]) + "'," + 
                       IntegerToString(T) + "," +
                       DoubleToString(O, Digits) + "," +
                       DoubleToString(H, Digits) + "," +
                       DoubleToString(L, Digits) + "," +
                       DoubleToString(C, Digits) + ");";
      if (!Statement::isComplete(sql_ins)) {
        IF_DEBUG_THEN Alert("Error - SQL Statement is not complete!");
        return (INIT_FAILED);
      }
      Statement s_ins(db, sql_ins);
      if (!s_ins.isValid()) {
        IF_DEBUG_THEN Alert("Error - SQL Statement is not valid!");
        return (INIT_FAILED);
      }

      int r_ins = s_ins.step();
      if (r_ins == SQLITE_OK)
        IF_DEBUG_THEN Print("Notice - Step finished.");
      else if (r_ins == SQLITE_DONE)
        IF_DEBUG_THEN Print("Notice - SQL query succeeded.");
      else
        IF_DEBUG_THEN Alert("Error - Failed to execute statement: ", db.getErrorMsg());
    }
    touchBlankFile(symbol, periods[i]);
  }
  return (GetLastError());
}

//+------------------------------------------------------------------+
//| touch blank file                                                 |
//+------------------------------------------------------------------+
int touchBlankFile(string symbol, int period)
{
  int handle = FileOpen(fileNameFromSymbolAndPeriod(symbol, period), FILE_CSV|FILE_WRITE, ',');
  if (handle <= 0) return (INIT_FAILED);
  FileWrite(handle, "");
  FileClose(handle);
  return (GetLastError());
}
