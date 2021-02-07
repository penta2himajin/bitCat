import times
from httpclient import HttpRequestError
from json import JsonParsingError
import library/[logic, dataman, wrapper/liquid]
from token import liquid_token


proc trader(self: Api) =
  echo "bitCat"
  let
    chart = getChart("btcjpy", "1min", 100)[^50..^1]
    account = self.getAccount
    product = getProduct("btcjpy")
  
  try:
    case chart.localOptimization
    of Buy:
      echo "Operation | Buy  | amount: ", account["JPY"] / product.ask - 0.00001
      log now().format("yyyy-MM-dd HH:mm:ss") & " : ---TRADE--- " & self.postOrder("market", "btcjpy", "buy", account["JPY"] / product.ask - 0.00001)
    
    of Sell:
      echo "Operation | Sell | amount: ", account["BTC"]
      log now().format("yyyy-MM-dd HH:mm:ss") & " : ---TRADE--- " & self.postOrder("market", "btcjpy", "sell", account["BTC"])
    
    of None: discard

  except HttpRequestError:
      echo "  Error   | HttpRequestError | Received an error message from the server"
      log now().format("yyyy-MM-dd HH:mm:ss") & " : ***ERROR*** Received an error message from the server."

  except JsonParsingError:
      echo "  Error   | JsonParsingError | Occured an error at parsing some data"
      log now().format("yyyy-MM-dd HH:mm:ss") & " : ***ERROR*** Occured an error at parsing some data."

  except:
      echo "  Error   |   UnknownError   | Unknown error occured"
      log now().format("yyyy-MM-dd HH:mm:ss") & " : ***ERROR*** Unknown error occured."

  finally: discard


when isMainModule:
  liquid_token.trader