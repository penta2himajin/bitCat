import httpclient, json, sugar, times, algorithm, uri, strutils, hmac, base64, uri, tables
import types

export types


let end_point = "https://api-cloud.huobi.co.jp"

#[ Public API ]#
proc getChart*(symbol: string, period_arg: string, size: int = 150): seq[Chart] =
  let
    period = if period_arg == "1hour": "60min" else: period_arg
    client = newHttpClient()
    chart_json = client.getContent(end_point & "/market/history/kline?period=" & period & "&size=" & repr(size) & "&symbol=" & symbol).parseJson
  
  collect(newSeq):
    for point_json in chart_json["data"]:
      Chart((
        timestamp: point_json["id"].getInt,
        open: point_json["open"].getFloat,
        high: point_json["high"].getFloat,
        low: point_json["low"].getFloat,
        close: point_json["close"].getFloat
      ))

proc getBoard*(symbol: string, aggregate: int = 0): Board =
  let
    client = newHttpClient()
    board_json = parseJson(client.getContent(end_point & "/market/depth?symbol=" & symbol & "&type=step" & repr(aggregate)))["tick"]
    bids = collect(newSeq):
      for order_json in board_json["bids"]:
        Order((
          price: order_json[0].getFloat,
          amount: order_json[1].getFloat
        ))
    asks = collect(newSeq):
      for order_json in board_json["asks"]:
        Order((
          price: order_json[0].getFloat,
          amount: order_json[1].getFloat
        ))

  Board((
    timestamp: board_json["ts"].getInt,
    bids: bids,
    asks: asks
  ))


#[ Authentication ]#
proc getSignature(self: Api, http_method: string, path: string, arguments: openArray[(string, string)] = @[]): string =
  var
    query: seq[(string, string)] = @{
      "AccessKeyId": self.key,
      "SignatureMethod": "HmacSHA256",
      "SignatureVersion": "2",
      "Timestamp": now().utc().format("yyyy-MM-dd HH:mm:ss").replace(" ", "T")
    }
  
  for argument in arguments:
    query.add(argument)
  
  query.sort()
  "?" & query.encodeQuery & "&Signature=" & hmac_sha256(key=self.secret, data=[http_method, "self-cloud.huobi.co.jp", path, query.encodeQuery].join("\n")).encode.encodeUrl

#[ Private API (needs API auth) ]#
proc getUserID(self: Api): int =
  newHttpClient()
    .getContent(
      end_point & "/v1/account/accounts" & self.getSignature(
        "GET",
        "/v1/account/accounts"))
    .parseJson["data"][0]["id"]
    .getInt

proc getAccount*(self: Api): Account =
  let
    id = self.getUserID
    path = "/v1/account/accounts/" & $id & "/balance"
    entry_point = end_point & path & self.getSignature("GET", path)
    client = newHttpClient()
    accounts_json = client.getContent(entry_point).parseJson
    accounts = collect(newSeq):
      for account_json in accounts_json["data"]["list"]:
        if account_json["type"].getStr == "trade":
          (
            currency: account_json["currency"].getStr.toUpper,
            amount: account_json["balance"].getStr.parseFloat
          )

  Account(accounts.toTable)

proc postOrder*(self: Api, order_type: string, product_pair: string, side: string, quantity: float): string =
  let
    id = self.getUserID
    path = "/v1/order/orders/place"
    body = $ %* {
      "account-id": $id,
      "amount": $quantity,
      "symbol": product_pair,
      "type": side & "-" & order_type
    }
    entry_point = end_point & path & self.getSignature("POST", path)
    client = newHttpClient(headers=newHttpHeaders({"Content-Type": "application/json"}))
  
  client.postContent(url=entry_point, body=body)


when isMainModule:
  from ../../token import huobi_jp_token

  echo huobi_jp_token.getAccount