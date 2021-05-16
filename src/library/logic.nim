import algorithm, math
import dataman, wrapper/types, chaos

export dataman, types

type Operation* = enum
    Buy
    Sell
    None

export Operation


#[ Tool ]#
func askCmp(x, y: Data): int =
  if x.ask < y.ask: -1
  elif x.ask == y.ask: 0
  else: 1

func pvCmp(x, y: Data): int =
  if x.pv < y.pv: -1
  elif x.pv == y.pv: 0
  else: 1

func bidCmp(x, y: Data): int =
  if x.bid < y.bid: -1
  elif x.bid == y.bid: 0
  else: 1

func closeCmp(x, y: Chart): int =
  if x.close < y.close: -1
  elif x.close == y.close: 0
  else: 1


#[ Logic ]#
func biasRatio*(old_data: Data, data: Data): Operation =
  if (old_data.ask > data.ask) and (abs(max(data.ask, data.pv) - min(data.ask, data.pv)) < abs(max(data.pv, data.bid) - min(data.pv, data.bid))):
    Buy
  elif (old_data.ask < data.bid) and (abs(max(data.ask, data.pv) - min(data.ask, data.pv)) > abs(max(data.pv, data.bid) - min(data.pv, data.bid))):
    Sell
  else:
    None

func localOptimization*(data: seq[Data]): Operation =
  if data.sorted(askCmp)[0].ask == data[^1].ask:
    Buy
  elif data.sorted(bidCmp)[^1].bid == data[^1].bid:
    Sell
  else:
    None

func localOptimization*(data: seq[Chart]): Operation =
  if data.sorted(closeCmp)[0].close == data[^1].close:
    Buy
  elif data.sorted(closeCmp)[^1].close == data[^1].close:
    Sell
  else:
    None

func priceSpring*(data: seq[Data], threshold: float): Operation =
  if data[^1].ask > int floor data.sorted(askCmp)[0].ask.float * (1.0 + threshold):
    Sell#Buy
  elif data[^1].bid < int floor data.sorted(bidCmp)[^1].bid.float * (1.0 - threshold):
    Buy#Sell
  else:
    None

proc expX*(data: seq[Data], duration: int): Operation =
  let pv_ema = data.pvs.EMA(duration)
  if data[^1].ask < pv_ema[^1]:
    Buy
  elif pv_ema[^1] < data[^1].bid:
    Sell
  else:
    None

func thresholdEMA*(data: seq[Data], duration, up, down: int): Operation =
  let pv_ema = data.pvs.EMA duration
  if up < (pv_ema[^1] - pv_ema[0]):
    Buy
  elif (pv_ema[^1] - pv_ema[0]) < down:
    Sell
  else:
    None

func crossTrade*(data: seq[Data], short, long: int): Operation =
  let
    short_ma = data.pvs.EMA(short)[^1]
    long_ma = data.pvs.EMA(long)[^1]
  
  if long_ma < short_ma:
    Buy
  elif short_ma < long_ma:
    Sell
  else:
    None

func changePoint*(data: seq[Data]): Operation =
  let
    rci = data.pvs.RCI
  
  if 80 < rci:
    Buy
  elif rci < -80:
    Sell
  else:
    None