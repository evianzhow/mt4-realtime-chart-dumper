//+------------------------------------------------------------------+
//| Helper_Functions.mq4
//| Copyright 2017, Evian Zhow
//| blog.evianzhow.com
//+------------------------------------------------------------------+
#property copyright   "Copyright 2017, Evian Zhow"
#property link        "blog.evianzhow.com"

#define epsilon 0.001 // #import <cmath> hack

#define IF_DEBUG_THEN if (Debug)

//+------------------------------------------------------------------+
//| convert user configured time zone +8.5 to standard +08:30, etc   |
//+------------------------------------------------------------------+
string timeZoneISOStandard(string configure)
{
  double doubleTZ = StrToDouble(configure);
  int intTZ = StrToInteger(configure);
  double delta = doubleTZ - intTZ;
  if (fabs(doubleTZ) < epsilon) {
    // UTC
    return "Z";
  } else if (fabs(delta) < epsilon) {
    // Integer Timezone Offset
    if (intTZ > 0) {
      return StringFormat("+%02d:00", intTZ);
    } else {
      return StringFormat("-%02d:00", fabs(intTZ));
    }
  } else {
    // Half Timezone Offset
    if (intTZ > 0) {
      return StringFormat("+%02d:%02d", intTZ, (int)(fabs(delta) * 60));
    } else {
      return StringFormat("-%02d:%02d", fabs(intTZ), (int)(fabs(delta) * 60));
    }
  }
}

//+------------------------------------------------------------------+
//| convert period constant to description                           |
//+------------------------------------------------------------------+
string periodDescriptionFromConstant(int period)
{
  switch (period) {
    case PERIOD_M1:    return "PERIOD_M1";
    case PERIOD_M5:    return "PERIOD_M5";
    case PERIOD_M15:   return "PERIOD_M15";
    case PERIOD_M30:   return "PERIOD_M30";
    case PERIOD_H1:    return "PERIOD_H1";
    case PERIOD_H4:    return "PERIOD_H4";
    case PERIOD_D1:    return "PERIOD_D1";
    case PERIOD_W1:    return "PERIOD_W1";
    case PERIOD_MN1:   return "PERIOD_MN1";
  }
      
  return "";
}

//+------------------------------------------------------------------+
//| convert period constant to description                           |
//+------------------------------------------------------------------+
string shortPeriodDescriptionFromConstant(int period)
{
  switch (period) {
    case PERIOD_M1:    return "M1";
    case PERIOD_M5:    return "M5";
    case PERIOD_M15:   return "M15";
    case PERIOD_M30:   return "M30";
    case PERIOD_H1:    return "H1";
    case PERIOD_H4:    return "H4";
    case PERIOD_D1:    return "D1";
    case PERIOD_W1:    return "W1";
    case PERIOD_MN1:   return "MN1";
  }
      
  return "";
}

//+------------------------------------------------------------------+
//| convert period description to constant                           |
//+------------------------------------------------------------------+
int periodConstantFromDescription(string desc)
{
  if (desc == "PERIOD_M1")        return PERIOD_M1;
  else if (desc == "PERIOD_M5")   return PERIOD_M5;
  else if (desc == "PERIOD_M15")  return PERIOD_M15;
  else if (desc == "PERIOD_M30")  return PERIOD_M30;
  else if (desc == "PERIOD_H1")   return PERIOD_H1;
  else if (desc == "PERIOD_H4")   return PERIOD_H4;
  else if (desc == "PERIOD_D1")   return PERIOD_D1;
  else if (desc == "PERIOD_W1")   return PERIOD_W1;
  else if (desc == "PERIOD_MN1")  return PERIOD_MN1;
  else return (PERIOD_CURRENT);
}

//+------------------------------------------------------------------+
//| filename without extension                                       |
//+------------------------------------------------------------------+
string fileNameWithoutExtension(string filename)
{
  string sep = ".";
  string results[];
  ushort u_sep = StringGetCharacter(sep, 0);

  int k = StringSplit(filename, u_sep, results);
  if (k > 1) {
    string res = "";
    for (int i = 0; i < k - 1; i++) {
      StringAdd(res, results[i]);
      if (i < k - 2) StringAdd(res, sep);
    }
    return res;
  } else if (k == 1) {
    return filename;
  } else {
    return "";
  }
}

//+------------------------------------------------------------------+
//| filename naming schema                                           |
//| {Symbol}-{ShortPeriodDescriptionFromConstant}.csv                |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| filename from symbol and period                                  |
//+------------------------------------------------------------------+
string fileNameFromSymbolAndPeriod(string symbol, int period)
{
  return symbol + "-" + shortPeriodDescriptionFromConstant(period) + ".csv";
}

//+------------------------------------------------------------------+
//| symbol from filename                                             |
//+------------------------------------------------------------------+
string symbolFromFileName(string filename)
{
  filename = fileNameWithoutExtension(filename);

  string sep = "-";
  string results[];
  ushort u_sep = StringGetCharacter(sep, 0);

  int k = StringSplit(filename, u_sep, results);
  // If the separator is not found in the passed string, only one source
  // string will be placed in the array.
  if (k > 1) {
    string res = "";
    for (int i = 0; i < k - 1; i++) {
      StringAdd(res, results[i]);
      if (i < k - 2) StringAdd(res, sep);
    }
    return res;
  } else {
    return "";
  }
}

//+------------------------------------------------------------------+
//| period from filename                                             |
//+------------------------------------------------------------------+
int periodFromFileName(string filename)
{
  filename = fileNameWithoutExtension(filename);

  string sep = "-";
  string results[];
  ushort u_sep = StringGetCharacter(sep, 0);

  int k = StringSplit(filename, u_sep, results);
  if (k > 1) {
    Print(results[k - 1]);
    return periodConstantFromDescription("PERIOD_" + results[k - 1]);
  } else {
    return PERIOD_CURRENT;
  }
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
