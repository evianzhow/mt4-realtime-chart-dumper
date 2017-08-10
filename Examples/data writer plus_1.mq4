//+------------------------------------------------------------------+
//|                                           data writer plus 1.mq4 |
//|                                               Copyright © 2009,  |
//|                                                                  |
//+------------------------------------------------------------------+
/*This version of indicator will export all bar data in the current cart 
  no mather its newest completed one or oldest one*/
#property copyright "Copyright © 2009, "
#property link      ""

#property indicator_chart_window
#define c 6
#define e 7

//---- input parameters
extern bool      show_comment=true;

string namafile="";
string date="";
string time="";
string high="";
string low="";
string close="";
string open="";
string volume="";
string a=",";
int    handlefile=0;
int    b=0;
int    d=0;
int    bar=0;
int    res=0;
bool   writefile=false;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- 
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
//----
   if(show_comment) Comment(" ");
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   if(show_comment) mycomment();
   if(bar==Bars) return(0);
   namafile="_data of "+Symbol()+" period M"+Period()+".csv";
   handlefile=FileOpen(namafile, FILE_CSV|FILE_WRITE, " ");
   if(handlefile>0)
     { 
      for(int i=Bars-1; i>=1; i--)
         {
          date=TimeToStr(Time[i], TIME_DATE);
          time=TimeToStr(Time[i], TIME_MINUTES);
          high=DoubleToStr(High[i], Digits);
          low=DoubleToStr(Low[i], Digits);
          close=DoubleToStr(Close[i], Digits);
          open=DoubleToStr(Open[i], Digits);
          volume=DoubleToStr(Volume[i], 0);
          writefile=FileWrite(handlefile, date+a+time+a+high+a+low+a+close+a+open+a+volume);
          }
      }
    else
      {
       for(i=Bars-1; i>=1; i--)
          {
           date=TimeToStr(Time[i], TIME_DATE);
           time=TimeToStr(Time[i], TIME_MINUTES);
           high=DoubleToStr(High[i], Digits);
           low=DoubleToStr(Low[i], Digits);
           close=DoubleToStr(Close[i], Digits);
           open=DoubleToStr(Open[i], Digits);
           volume=DoubleToStr(Volume[i], 0);
           writefile=FileWrite(handlefile, date+a+time+a+high+a+low+a+close+a+open+a+volume);
          }
       if(writefile) d=e;
      } 
//----
   if(writefile) FileClose(handlefile);  
   return(0);
  }
//+------------------------------------------------------------------+
//| my comment                                                       |
//+------------------------------------------------------------------+
string mycomment()
  {
   date=TimeToStr(Time[1], TIME_DATE);
   time=TimeToStr(Time[1], TIME_MINUTES);
   high=DoubleToStr(High[1], Digits);
   low=DoubleToStr(Low[1], Digits);
   close=DoubleToStr(Close[1], Digits);
   open=DoubleToStr(Open[1], Digits);
   volume=DoubleToStr(Volume[1], 0);
   Comment("data writer plus ", Symbol(), " period M", Period(),"\n\n", "LAST BAR DATA : \n", "date   =  ",date,"\n",
           "time   =  ",time,"\n","high   =  ",high,"\n", "low    =  ",low,"\n", "volume =  ",volume);
   return("");
  } 

