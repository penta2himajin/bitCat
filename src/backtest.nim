from sequtils import toSeq
import library/[sandbox, dataman, logic, plotter, chaos]


func data2Chart(wallet: Wallet, data: seq[Data]): seq[float] =
  var
    w = wallet
    sim_result = newSeq[float](1)
  
  w = w.order("buy", data[0].ask.float, (w.fiat)/data[0].ask.float)
  for i in 1..<data.len:
    sim_result.add ((w.full_amount data[i].pv.float) / (wallet.full_amount data[0].pv.float) - 1)*100

  sim_result

func simulateBestScore(wallet: Wallet, data: seq[Data]): seq[float] =
  var
    w = wallet
    sim_result = newSeq[float](1)

  for i in 1..<data.len:
    if data[i-1].ask < data[i].bid:
      w = w.order("buy", data[i-1].ask.float, (w.fiat)/data[i-1].ask.float)
    else:
      w = w.order("sell", data[i-1].bid.float, (w.crypto))

    sim_result.add ((w.full_amount data[i].pv.float) / (wallet.full_amount data[0].pv.float) - 1)*100

  sim_result

func simulateBiasRatio(wallet: Wallet, data: seq[Data], diff: int = 1): seq[float] =
  var
    w = wallet
    sim_result = newSeq[float](1)

  for i in diff..<data.len:
    case biasRatio(data[i-diff], data[i])
    of Buy:
      w = w.order("buy", data[i].ask.float, (w.fiat)/data[i].ask.float)
    of Sell:
      w = w.order("sell", data[i].bid.float, (w.crypto))
    of None:
      discard
    
    sim_result.add ((w.full_amount data[i].pv.float) / (wallet.full_amount data[0].pv.float) - 1)*100

  sim_result

func simulateLocalOptimization(wallet: Wallet, data: seq[Data], duration: int): seq[float] =
  var
    w = wallet
    sim_result = newSeq[float](1)
  
  for i in duration..<data.len:
    case localOptimization(data[i - duration..i])
    of Buy:
      w = w.order("buy", data[i].ask.float, (w.fiat)/data[i].ask.float)
    of Sell:
      w = w.order("sell", data[i].bid.float, (w.crypto))
    else:
      discard
    
    sim_result.add ((w.full_amount data[i].pv.float) / (wallet.full_amount data[0].pv.float) - 1)*100

  sim_result

func simulatePriceSpring(wallet: Wallet, data: seq[Data], threshold: float, duration: int): seq[float] =
  var
    w = wallet
    sim_result = newSeq[float](1)
  
  for i in duration..<data.len:
    case priceSpring(@(data[i-duration..i]), threshold)
    of Buy:
      w = w.order("buy", data[i].ask.float, (w.fiat)/data[i].ask.float)
    of Sell:
      w = w.order("sell", data[i].bid.float, (w.crypto))
    else:
      discard
    
    sim_result.add ((w.full_amount data[i].pv.float) / (wallet.full_amount data[0].pv.float) - 1)*100

  sim_result

func simulateExpX(wallet: Wallet, data: seq[Data], duration: int): seq[float] =
  var
    w = wallet
    sim_result = newSeq[float](1)
  
  for i in duration..<data.len:
    case expX(@(data[i-duration..i]), duration)
    of Buy:
      w = w.order("buy", data[i].ask.float, (w.fiat)/data[i].ask.float)
    of Sell:
      w = w.order("sell", data[i].bid.float, (w.crypto))
    else:
      discard
    
    sim_result.add ((w.full_amount data[i].pv.float) / (wallet.full_amount data[0].pv.float) - 1)*100

  sim_result

func simulateThresholdEMA(wallet: Wallet, data: seq[Data], duration: int, up: int, down: int): seq[float] =
  var
    w = wallet
    sim_result = newSeq[float](1)
  
  for i in duration..<data.len:
    case thresholdEMA(@(data[i-duration..i]), duration, up, down)
    of Buy:
      w = w.order("buy", data[i].ask.float, (w.fiat)/data[i].ask.float)
    of Sell:
      w = w.order("sell", data[i].bid.float, (w.crypto))
    else:
      discard
    
    sim_result.add ((w.full_amount data[i].pv.float) / (wallet.full_amount data[0].pv.float) - 1)*100

  sim_result

func simulateCrossTrade(wallet: Wallet, data: seq[Data], short, long: int): seq[float] =
  var
    w = wallet
    sim_result = newSeq[float](1)
  
  for i in long..<data.len:
    case crossTrade(@(data[i-long..i]), short, long)
    of Buy:
      w = w.order("buy", data[i].ask.float, (w.fiat)/data[i].ask.float)
    of Sell:
      w = w.order("sell", data[i].bid.float, (w.crypto))
    else:
      discard
    
    sim_result.add ((w.full_amount data[i].pv.float) / (wallet.full_amount data[0].pv.float) - 1)*100

  sim_result

proc simulateChangePoint(wallet: Wallet, data: seq[Data], duration: int): seq[float] =
  var
    w = wallet
    sim_result = newSeq[float](1)
  
  for i in duration..<data.len:
    case changePoint(@(data[i-duration..i]))
    of Buy:
      w = w.order("buy", data[i].ask.float, (w.fiat)/data[i].ask.float)
    of Sell:
      w = w.order("sell", data[i].bid.float, (w.crypto))
    else:
      discard
    
    sim_result.add ((w.full_amount data[i].pv.float) / (wallet.full_amount data[0].pv.float) - 1)*100

  sim_result


when isMainModule:

  let
    wallet: Wallet = (
      fiat: 10000.0,
      crypto: 0.0 
    )
    data = loadData("liquid_logger/liquid.log")
    data_chart = wallet.data2Chart data
    local_optimization = wallet.simulateLocalOptimization(data, 50)
    #threshold_ema = wallet.simulateThresholdEMA(data, 15, 6000, 3000)
    cross_trade = wallet.simulateCrossTrade(data, 15, 210)
    change_point = wallet.simulateChangePoint(data, 30)

  var data_for_plot = @[
    (toSeq(1..data_chart.len), data_chart, "data"),
    #(toSeq(1..data_chart.len), wallet.simulateBestScore data, "best score"),
    #(toSeq(15..data_chart.len), wallet.simulateBiasRatio(data, 15), "Bias Ratio"),
    (toSeq(data_chart.len - local_optimization.len + 1..data_chart.len), local_optimization, "Local Optimization"),
    #(toSeq(20..data_chart.len), wallet.simulatePriceSpring(data, 0.01, 20), "Price Spring"),
    #(toSeq(data_chart.len - threshold_ema.len + 1..data_chart.len), threshold_ema, "Threshold EMA"),
    (toSeq(data_chart.len - cross_trade.len + 1..data_chart.len), cross_trade, "Cross Trade"),
    (toSeq(data_chart.len - change_point.len + 1..data_chart.len), change_point, "Change Point"),
  ]


  show("time", "profit (%)", 0, data_for_plot)

  #[ show("time", "flucturation", 1,
    #(toSeq(1..data.len), data.asks, "Ask"),
    (toSeq(1..data.len), data.pvs, "Last traded price"),
    #(toSeq(1..data.len), data.bids, "Bid"),
    (toSeq(15..data.len), data.pvs.EMA 15, "Bid"),
  ) ]#

  stdout.write "press any key to continue..."
  discard stdin.readChar