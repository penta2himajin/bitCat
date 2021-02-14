import times
from httpclient import HttpRequestError
from json import JsonParsingError
import library/[logic, dataman, wrapper/liquid]
from token import liquid_token


proc trader(self: Api) =
  let
    chart = getChart("btcjpy", "1min", 100)[^50..^1]
    account = self.getAccount
    product = getProduct("btcjpy")
  
  echo now().format("yyyy-MM-dd HH:mm:ss"), " | Start Processing |"
  log now().format("yyyy-MM-dd HH:mm:ss") & " | Start Processing |"
  
  try:
    case chart.localOptimization
    of Buy:
      let response = self.postOrder("market", "btcjpy", "buy", account["JPY"] / product.ask - 0.00001)
      echo now().format("yyyy-MM-dd HH:mm:ss"), " | Trade : BUY  |", response
      log now().format("yyyy-MM-dd HH:mm:ss") & " | ---TRADE--- : BUY  | " & response
    
    of Sell:
      let response = self.postOrder("market", "btcjpy", "sell", account["BTC"])
      echo now().format("yyyy-MM-dd HH:mm:ss"), " | Trade : SELL |", response
      log now().format("yyyy-MM-dd HH:mm:ss") & " | ---TRADE--- : SELL | " & response
    
    of None: discard

  except HttpRequestError:
      echo now().format("yyyy-MM-dd HH:mm:ss"), " | Error | HttpRequestError | Received an error message from the server"
      log now().format("yyyy-MM-dd HH:mm:ss") & " | ***ERROR*** : Received an error message from the server."

  except JsonParsingError:
      echo now().format("yyyy-MM-dd HH:mm:ss"), " | Error | JsonParsingError | Occured an error at parsing some data"
      log now().format("yyyy-MM-dd HH:mm:ss") & " | ***ERROR*** : Occured an error at parsing some data."

  except:
      echo now().format("yyyy-MM-dd HH:mm:ss"), " | Error |   UnknownError   | Unknown error occured"
      log now().format("yyyy-MM-dd HH:mm:ss") & " | ***ERROR*** : Unknown error occured."

  finally:
    echo now().format("yyyy-MM-dd HH:mm:ss"), " | Processing Exit |"
    log now().format("yyyy-MM-dd HH:mm:ss") & " | Processing Exit |"


when isMainModule:
  liquid_token.trader