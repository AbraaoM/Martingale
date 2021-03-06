//+------------------------------------------------------------------+
//|                                                   Martingale.mq5 |
//|                                                   Abraão Moreira |
//|                                      abraaol.moreira@outlook.com |
//+------------------------------------------------------------------+
#property copyright "Abraão Moreira"
#property link      "abraaol.moreira@outlook.com"
#property version   "1.00"
#property script_show_inputs

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
enum tradeWay {
  w0 = 0,  //Contra
  w1 = 1,  //A favor
};
input tradeWay swapWay = w0;              //Sentido da entrada
input int amount = 1;                     //Tamanho do lote
input int tpA = 100;                        //Take profit
input int slA = 100;                        //Stop loss
enum trailingStop {
  nTS = 0,   //Não
  yTS = 1,   //Sim
};
input trailingStop swapTS = nTS;          //Aplicar trailing stop
enum breakeven {
  nB = 0,   //Não
  yB = 1,   //Sim
};
input breakeven swapBreakeven = nB;       //Aplicar breakeven
enum martingale {
  nM = 0,   //Não
  yM = 1,   //Sim
};
input martingale swapMartingale = nM;     //Aplicar martingale
enum autoTrade {
  nAT = 0,   //Não
  yAT = 1,   //Sim
};
input autoTrade swapAutoTrade = nAT;     //Possibilitar entradas automáticas
input double martingaleFactor = 2;      //Fator martingale (atentar ao ativo)
input int martingaleMaxRepeat = 1;        //Maximo de vezes que o martingale será executado
input double maxLoss = 1000;                 //Perda máxima em um dia em dinheiro
input double maxProfit = 5000;                 //Ganho máximo do dia em dinheiro
input datetime startTime = D'09:30:00';   //Horário de início
input datetime endTime = D'17:30:00';     //Horário de finalização

//+------------------------------------------------------------------+
//| Variáveis globais                                                |
//+------------------------------------------------------------------+

CTrade trade;                             //Classe responsável pelas negociações
double ask = 0;
double bid = 0;
MqlDateTime actTime;
MqlDateTime staTime;
MqlDateTime finTime;
double priceBuffer[];
int contMart = 0;
double currProfit = 0;

//+------------------------------------------------------------------+
//|  Função de iniciação do EA                                       |
//+------------------------------------------------------------------+
int OnInit() {
  ArraySetAsSeries(priceBuffer, true);
  TimeToStruct(startTime, staTime);
  TimeToStruct(endTime, finTime);
  return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason) {

}

//+------------------------------------------------------------------+
//|  Função executada a cada tick                                    |
//+------------------------------------------------------------------+
void OnTick() {
  double marAmount = amount;
  TimeCurrent(actTime);
  if(!PositionSelect(_Symbol)) {    //Checa se não há posição aberta
    if(!LimLoss() && !LimProfit()) {
      if(AfterLoss()) {
        if(!LimMart()) {
          marAmount = Operation(marAmount, martingaleFactor);    //Executa um martingale
        }
      } else {
        if(swapAutoTrade == yAT) {
          if(actTime.hour == staTime.hour) {
            if(actTime.min >= staTime.min) {
              marAmount = Operation(amount, 1);
            }
          } else {
            if(actTime.hour > staTime.hour) {
              marAmount = Operation(amount, 1);
            }
          }
        }
      }
    }
  }
}

//+------------------------------------------------------------------+
//|  Executa uma operação, retornando o tamanho do lote negociado    |
//+------------------------------------------------------------------+
double Operation(double marAmount, double percAmount) {
  double correctAmount;
  correctAmount = marAmount * percAmount;
  if(actTime.min%(int)_Period == 0 && actTime.sec == 59) {
    if(Trend() == 1) {
      if(swapWay == w0)
        Venda(correctAmount);
      if(swapWay == w1)
        Compra(correctAmount);
    }
    if(Trend() == 0) {
      if(swapWay == w1)
        Venda(correctAmount);
      if(swapWay == w0)
        Compra(correctAmount);
    }
  }
  return correctAmount;
}

//+------------------------------------------------------------------+
//|  Verifica se o número máximo de Martingales foi atingido         |
//+------------------------------------------------------------------+
bool LimMart() {
  if(contMart >= martingaleMaxRepeat) {
    contMart = 0;
    return true;
  } else
    return false;
}

//+------------------------------------------------------------------+
//|  Função que calcula se o limite de ganhos estabelecido pelo      |
//|  usuário foi atingido ou não.                                    |
//+------------------------------------------------------------------+
bool LimProfit() {
  double sumProfit = 0;
  ulong ticket;
  if(HistorySelect(startTime, StructToTime(actTime))) {
    uint total = HistoryDealsTotal();
    for(uint i=0 ; i<total ; i++) {
      if((ticket = HistoryDealGetTicket(i)) > 0) {
        sumProfit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
      }
    }
  }
  if(sumProfit >= maxProfit)
    return true;
  return false;
}

//+------------------------------------------------------------------+
//|  Função que calcula se o limite de perdas estabelecido pelo      |
//|  usuário foi atingido ou não.                                    |
//+------------------------------------------------------------------+
bool LimLoss() {
  double sumLoss = 0;
  ulong ticket;
  if(HistorySelect(startTime, StructToTime(actTime))) {
    uint total = HistoryDealsTotal();
    for(uint i=0 ; i<total ; i++) {
      if((ticket = HistoryDealGetTicket(i)) > 0) {
        sumLoss += HistoryDealGetDouble(ticket, DEAL_PROFIT);
      }
    }
  }
  if(sumLoss*(-1) >= maxLoss)
    return true;
  return false;
}

//+------------------------------------------------------------------+
//| Verifica se a ultima operação é foi um loss                      |
//+------------------------------------------------------------------+
bool AfterLoss() {
  ulong ticket;
  if(HistorySelect(startTime, StructToTime(actTime))) {
    uint total = HistoryDealsTotal();
    if((ticket = HistoryDealGetTicket(total-1)) > 0) {
      if(HistoryDealGetDouble(ticket, DEAL_PROFIT) < 0)
        return true;
    }
  }
  return false;
}

//+------------------------------------------------------------------+
//|  Função que identifica a tendência                               |
//|  tendência de alta: return = 1                                   |
//|  tendencia de baixa: return = 0                                  |
//+------------------------------------------------------------------+
int Trend() {
  CopyClose(_Symbol, _Period,0, 3, priceBuffer);
  if(priceBuffer[1] < priceBuffer[2])
    return 1;
  if(priceBuffer[1] > priceBuffer[2])
    return 0;
  return 1;
}

//+------------------------------------------------------------------+
//|  Função que executa a compra                                     |
//+------------------------------------------------------------------+
void Compra(double percentAmount) {
  ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
  trade.Buy(amount*percentAmount, _Symbol, ask, ask - slA*_Point, ask + tpA*_Point, "Ordem de compra automática");
}

//+------------------------------------------------------------------+
//|  Função que executa a venda                                      |
//+------------------------------------------------------------------+
void Venda(double percentAmount) {
  bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
  trade.Sell(amount*percentAmount, _Symbol, bid, bid + slA*_Point, bid - tpA*_Point, "Ordem de venda automática");
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
