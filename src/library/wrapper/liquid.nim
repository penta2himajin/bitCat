import times, httpClient, json, sugar, strutils, jwt, tables, uri
import types

export types


const end_point = "https://api.liquid.com"

#[ Public API ]#
proc getProducts*(): seq[Product] =
  let
    path = "/products"
    client = newHttpClient()
    products_json = client.getContent(end_point & path).parseJson
  
  collect(newSeq):
    for product_json in products_json:
      Product((
        id: product_json["id"].getStr.parseInt,
        symbol: product_json["currency_pair_code"].getStr,
        ask: product_json["market_ask"].getFloat,
        bid: product_json["market_bid"].getFloat,
        last_traded_price: product_json["last_traded_price"].getFloat,
        timestamp: product_json["timestamp"].getStr.parseFloat.int
      ))

proc getProduct*(symbol: string): Product =
  for product in getProducts():
    if product.symbol == symbol.toUpper:
      return product

proc getChart*(symbol: string, period_string: string, duration: int = 500): seq[Chart] =
  var period: int

  case period_string
  of  "1min": period = 60
  of  "5min": period = 300
  of "15min": period = 900
  of "30min": period = 1800
  of "1hour": period = 3600
  of "4hour": period = 14400
  of  "1day": period = 86400

  let
    now = now().utc.toTime.toUnix
    query = {
      "before": repr now + period,
      "after": repr now - period * (duration),
      "periods": repr period,
    }.encodeQuery
    client = newHttpClient()
    chart_json = client.getContent("http://api.cryptowat.ch/markets/liquid/" & symbol & "/ohlc?" & query).parseJson
  
  collect(newSeq):
    for point_json in chart_json["result"][repr period]:
      Chart((
        timestamp: point_json[0].getInt,
        open: point_json[1].getFloat,
        high: point_json[2].getFloat,
        low: point_json[3].getFloat,
        close: point_json[4].getFloat
      ))

proc getBoard*(id: int, full: int = 20): Board =
  let
    path_head = "/products/"
    path_foot = "/price_levels"
    client = newHttpClient()
    board_json = client.getContent(end_point & path_head & $id & path_foot).parseJson
  let
    bids = collect(newSeq):
      for order_json in board_json["sell_price_levels"]:
        Order((
          price: order_json[0].getStr.parseFloat,
          amount: order_json[1].getStr.parseFloat
        ))
    asks = collect(newSeq):
      for order_json in board_json["buy_price_levels"]:
        Order((
          price: order_json[0].getStr.parseFloat,
          amount: order_json[1].getStr.parseFloat
        ))
  
  Board((
    timestamp: int board_json["timestamp"].getStr.parseFloat,
    bids: bids,
    asks: asks
  ))

#[ Authentication ]#
proc getSignature(self: Api, path: string): HttpHeaders =
  var signature = toJWT(%*{
      "header": {
        "alg": "HS256",
        "typ": "JWT"
      },
      "claims": {
        "path": path,
        "nonce": $ int now().toTime.toUnix,
        "token_id": self.key
      }
    })
  
  signature.sign(self.secret)
  [
    (key: "X-Quoine-API-Version", val: $2),
    (key: "X-Quoine-Auth", val: $signature),
    (key: "Content-Type", val: "application/json")
  ].newHttpHeaders

#[ Private API (needs API auth) ]#
proc getAccount*(self: Api): Account =
  let
    path = "/accounts/balance"
    client = newHttpClient(headers=self.getSignature(path))
    accounts_json = client.getContent(end_point & path).parseJson
    accounts = collect(newSeq):
      for account_json in accounts_json:
        (
          currency: account_json["currency"].getStr,
          amount: account_json["balance"].getStr.parseFloat
        )
  
  Account(accounts.toTable())

proc postOrder*(self: Api, order_type: string, product_pair: string, side: string, quantity: float): string =
  let
    path = "/orders/"
    body = $ %*{
      "order": {
        "order_type": order_type,
        "product_id": $getProduct(product_pair).id,
        "side": side,
        "quantity": quantity.formatFloat(ffDecimal, 8)
      }
    }
    client = newHttpClient(headers=self.getSignature(path))
  
  client.postContent(url=(end_point & path), body=body)


when isMainModule:
  from ../../token import liquid_token

  echo liquid_token.getAccount