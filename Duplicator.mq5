//+------------------------------------------------------------------+
//|                                                   Duplicator.mq5 |
//|                                      Copyright 2021, ItIsHermann |
//|                                       https://www.itishermann.me |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

#define TRADE_COMMENT "Placed by duplicator"
//--- input parameters
input ulong    slippage=5;          // Authorized deviation
input int      clones=5;            // Number of desired copies of a position
input ulong    MAGIC_NUMBER=12345;  // Magic Number of EA

CTrade trade;
CPositionInfo position;
CAccountInfo account;

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
   if(account.TradeMode() == ACCOUNT_TRADE_MODE_DEMO ){ trade.LogLevel(LOG_LEVEL_ALL); }
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
   if(numPos == PositionsTotal() && trans.type == TRADE_TRANSACTION_POSITION)
     {// edited
      numPos = PositionsTotal();
      int positionIndex = getPositionIndexByTicket(trans.position);
      ulong ticket = trans.position;
      double sl=0, tp=0;
      string comment="";
      if(position.SelectByIndex(positionIndex)){
         sl = position.StopLoss();
         tp = position.TakeProfit();
         comment = position.Comment();
      } else {
         Print("Cannot get edited position");
      }
      for(int i = PositionsTotal() -1; i >= 0; i--){
         position.SelectByIndex(i);
         Print(position.Comment() == IntegerToString(ticket) , IntegerToString(position.Ticket()) == comment, position.Ticket(), comment, position.Comment(), ticket);
         if(position.Comment() == IntegerToString(ticket) || IntegerToString(position.Ticket()) == comment || position.Comment() == comment){
            if(trade.PositionModify(position.Ticket(), sl, tp)){
               if(account.TradeMode() != ACCOUNT_TRADE_MODE_DEMO) Print("Position #", position.Ticket()," edited ");
            } else {
               if(account.TradeMode() != ACCOUNT_TRADE_MODE_DEMO) Print("Could not modify position #", position.Ticket());
               break;
            }
         }
      }
     }
   if(numPos < PositionsTotal() && position.Magic() != MAGIC_NUMBER && trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal != 0)
     {// new
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
            if(account.TradeMode() != ACCOUNT_TRADE_MODE_DEMO) Print("Position #", position.Ticket()," cloned ", i, " times");
           }
         else
           {
            if(account.TradeMode() != ACCOUNT_TRADE_MODE_DEMO) Print("Could not duplicate position #", position.Ticket());
            break;
           }
        }
      i = 0;
      numPos = PositionsTotal();
     }
   if(numPos > PositionsTotal() && trans.deal != 0)
     {// deleted
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
         if(IntegerToString(closed_ticket) == position.Comment() && position.Magic() == MAGIC_NUMBER){
            ulong ticket = position.Ticket();
            if(trade.PositionClose(ticket, slippage)){
               if(account.TradeMode() != ACCOUNT_TRADE_MODE_DEMO) Print("Position #", ticket," closed successfully");
            } else {
               if(account.TradeMode() != ACCOUNT_TRADE_MODE_DEMO) Print("Position #", ticket," not closed");
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
int getPositionIndexByTicket(ulong ticket){
   for(int i = PositionsTotal() -1; i >= 0; i--){
      position.SelectByIndex(i);
      if(position.Ticket() == ticket){
         return i;
      }
   }
   return NULL;
}