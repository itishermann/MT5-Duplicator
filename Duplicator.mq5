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
   position.SelectByIndex(PositionsTotal()-1);
   if(numPos == PositionsTotal())
     {
      numPos = PositionsTotal();
      // Print("Trade edited", trans.deal, EnumToString(trans.type), EnumToString(trans.deal_type), EnumToString(trans.type));
     }
   if(numPos < PositionsTotal() && position.Magic() != MAGIC_NUMBER && trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal != 0)
     {
      int i = 0;
      while(i < clones)
        {
         bool openSuccess = trade.PositionOpen(
                               position.Symbol(),
                               (position.TypeDescription() == "buy") ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                               position.Volume(),
                               position.PriceCurrent(),
                               position.StopLoss(),
                               position.TakeProfit(),
                               IntegerToString(position.Ticket())
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
   if(numPos > PositionsTotal() && trans.deal != 0)
     {
      ulong closed_ticket = trans.position;
      string closed_comment = request.comment;
      int closed_magic = request.magic;
      if(PositionSelectByTicket(closed_ticket)){
         Print("inside");
         PositionGetString(POSITION_COMMENT, closed_comment);
         closed_magic = PositionGetInteger(POSITION_MAGIC);
         Print("Pos ", closed_comment, " ", closed_magic);
      }
      for(int i = PositionsTotal()-1; i >= 0; i--){
         Print("closed ticket :", closed_ticket, " closed comment: ", closed_comment, " closed magic: ", closed_magic);
         position.SelectByIndex(i);
         if(
         (IntegerToString(closed_ticket) == position.Comment() && position.Magic() == MAGIC_NUMBER) ||
         (closed_comment != NULL &&
            (closed_magic == position.Magic()) &&
            (closed_comment == position.Comment() ||
            closed_comment == IntegerToString(position.Ticket()))
          )){
            ulong ticket = position.Ticket();
            if(trade.PositionClose(ticket, slippage)){
               Print("Position #", ticket," closed successfully");
            } else {
               Print("Position #", ticket," not closed");
            }
         }
      }
      numPos = PositionsTotal();
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
