from sequtils import toSeq
import library/[sandbox, dataman, logic, plotter]


func data2Chart(wallet: Wallet, data: seq[Data]): seq[float] =
  var
    w = wallet
    sim_result = newSeq[float](1)
  
  w = w.order("buy", data[0].ask.float, (w.fiat)/data[0].ask.float)
  for i in 1..<data.len:
    sim_result.add ((w.full_amount data[i].pv.float) / (wallet.full_amount data[0].pv.float) - 1)*100

  sim_result

func simulateBiasRatio(wallet: Wallet, data: seq[Data]): seq[float] =
  var
    w = wallet
    sim_result = newSeq[float](1)

  for i in 1..<data.len:
    case biasRatio(data[i-1], data[i])
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


when isMainModule:
  let
    wallet: Wallet = (
      fiat: 10000.0,
      crypto: 0.0 
    )
    data = loadData("liquid_logger/liquid.log")

    data_chart = wallet.data2Chart data
    #bias_ratio = wallet.simulateBiasRatio data
    local_optimization = wallet.simulateLocalOptimization(data, 50)
    price_spring = wallet.simulatePriceSpring(data, 0.01, 20)

  show("time", "profit (%)", 0,
    (toSeq(1..data_chart.len), data_chart, "data"),
    #(toSeq(1..bias_ratio.len), bias_ratio, "Bias Ratio"),
    (toSeq(50..data_chart.len), local_optimization, "Local Optimization"),
    (toSeq(20..data_chart.len), price_spring, "Price Spring"),
  )

  #[ show("time", "flucturation", 1,
    (toSeq(1..data.len), data.asks, "Ask"),
    (toSeq(1..data.len), data.pvs, "Last traded price"),
    (toSeq(1..data.len), data.bids, "Bid"),
  ) ]#

  stdout.write "press any key to continue..."
  discard stdin.readChar