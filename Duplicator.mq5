//+------------------------------------------------------------------+
//|                                                   Duplicator.mq5 |
//|                                      Copyright 2021, ItIsHermann |
//|                                       https://www.itishermann.me |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

#define TRADE_COMMENT "Placed by duplicator"
//--- input parameters
input ulong      slippage=5;
input int    clones=5;
input ulong    MAGIC_NUMBER=12345;

CTrade trade;
CPositionInfo position;

int numPos;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ResetLastError();
   trade.SetExpertMagicNumber(MAGIC_NUMBER);
   trade.SetDeviationInPoints(slippage);
   numPos = PositionsTotal();
   return(INIT_SUCCEEDED);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   int i = 0;
   position.SelectByIndex(PositionsTotal()-1);
   if(position.Magic() != MAGIC_NUMBER && trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal != 0)
     {
      if(numPos == PositionsTotal())
        {
         numPos = PositionsTotal();
         Print("Trade edited");
        }
      if(numPos < PositionsTotal())
        {
         while(i < clones)
           {
            bool openSuccess = trade.PositionOpen(
                                  position.Symbol(),
                                  position.Type() == POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                                  position.Volume(),
                                  position.PriceCurrent(),
                                  position.StopLoss(),
                                  position.TakeProfit(),
                                  TRADE_COMMENT
                               );
            if(openSuccess)
              {
               i++;
              }
            else
              {
               Print("Could not duplicate position #", position.Ticket());
               break;
              }
           }
         i = 0;
         numPos = PositionsTotal();
        }
      if(numPos > PositionsTotal())
        {
         numPos = PositionsTotal();
         Print("Trade closed");
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
