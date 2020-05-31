#[

    *** NOTE ***
    This module has been abandoned for development.
    Please use it after making your own changes.

]#

import httpclient, json, sugar, times, algorithm, uri, strutils, hmac, base64
import ../types


let
    end_point = "https://api-cloud.huobi.co.jp"

func `~`*(left: string, right: string): string =
    left & "\n" & right

proc getChart*(symbol: string, period_arg: string, size: int = 150): seq[chart] =
    let
        period = if period_arg == "1hour": "60min" else: period_arg
        client = newHttpClient()
        chart_json = client.getContent(end_point & "/market/history/kline?period=" & period & "&size=" & repr(size) & "&symbol=" & symbol).parseJson["data"]
        chart = collect(newSeq):
            for point_json in chart_json:
                (
                    timestamp: point_json["id"].getInt,
                    open: point_json["open"].getFloat,
                    high: point_json["high"].getFloat,
                    low: point_json["low"].getFloat,
                    close: point_json["close"].getFloat,
                    hl: (point_json["high"].getFloat + point_json["low"].getFloat) / 2,
                    hlc: (point_json["high"].getFloat + point_json["low"].getFloat + point_json["close"].getFloat) / 3,
                    ohlc: (point_json["open"].getFloat + point_json["high"].getFloat + point_json["low"].getFloat + point_json["close"].getFloat) / 4
                )
    
    chart

proc getBoard*(symbol: string, aggregate: int = 0): board =
    let
        client = newHttpClient()
        board_json = parseJson(client.getContent(end_point & "/market/depth?symbol=" & symbol & "&type=step" & repr(aggregate)))["tick"]
        bids = collect(newSeq):
            for order_json in board_json["bids"]:
                (
                    price: order_json[0].getFloat,
                    amount: order_json[1].getFloat
                )
        asks = collect(newSeq):
            for order_json in board_json["asks"]:
                (
                    price: order_json[0].getFloat,
                    amount: order_json[1].getFloat
                )
        board = (
            timestamp: board_json["ts"].getInt,
            bids: bids,
            asks: asks
        )
    
    board

proc getSignature(api: api, http_method: string, path: string, arguments: openArray[(string, string)] = @[]): string =
    var
        query: seq[(string, string)] = @{
            "AccessKeyId": api.key,
            "SignatureMethod": "HmacSHA256",
            "SignatureVersion": $2,
            "Timestamp": now().utc().format("yyyy-MM-dd HH:mm:ss").replace(" ", "T")
        }
    
    for argument in arguments:
        query.add(argument)
    
    query.sort()
    "?" & query.encodeQuery & "&Signature=" & hmac_sha256(key=api.secret, data=http_method ~ end_point ~ path ~ query.encodeQuery).encode

proc getAccount*(api: api) =
    let
        path = "/v1/account/accounts"
        client = newHttpClient()
        url = end_point & path & api.getSignature("GET", path)
        account_json = client.getContent(url).parseJson
    echo url
    echo account_json