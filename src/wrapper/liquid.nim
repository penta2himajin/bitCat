import times, httpClient, json, sugar, strutils, jwt, tables, uri
import types


const end_point = "https://api.liquid.com"

#[ Public API ]#
proc getProducts*(): seq[product] =
    let
        client = newHttpClient()
        products_json = client.getContent(end_point & "/products").parseJson
        products = collect(newSeq):
            for product_json in products_json:
                (
                    id: product_json["id"].getStr.parseInt,
                    symbol: product_json["currency_pair_code"].getStr,
                    ask: product_json["high_market_ask"].getStr.parseFloat,
                    bid: product_json["low_market_bid"].getStr.parseFloat,
                    spread: product_json["market_ask"].getFloat - product_json["market_bid"].getFloat,
                    last_traded_price: product_json["last_traded_price"].getFloat,
                    timestamp: product_json["timestamp"].getStr.parseFloat.int
                )
    
    products

proc getProduct*(symbol: string): product =
    for product in getProducts():
        if product.symbol == symbol.toUpper:
            let
                path = "/products/"
                client = newHttpClient()
                product_json = client.getContent(end_point & path & $product.id).parseJson
            return (
                id: product_json["id"].getStr.parseInt,
                symbol: product_json["currency_pair_code"].getStr,
                ask: product_json["market_ask"].getFloat,
                bid: product_json["market_bid"].getFloat,
                spread: product_json["market_ask"].getFloat - product_json["market_bid"].getFloat,
                last_traded_price: product_json["last_traded_price"].getStr.parseFloat,
                timestamp: product_json["timestamp"].getStr.parseFloat.int
            )

proc getChart*(symbol: string, period_string: string, duration: int = 500): seq[chart] =
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
        chart_json = client.getContent("http://api.cryptowat.ch/markets/liquid/" & symbol & "/ohlc?" & query).parseJson["result"][repr period]
        chart = collect(newSeq):
            for point_json in chart_json:
                (
                    timestamp: point_json[0].getInt,
                    open: point_json[1].getFloat,
                    high: point_json[2].getFloat,
                    low: point_json[3].getFloat,
                    close: point_json[4].getFloat,
                    hl: (point_json[2].getFloat + point_json[3].getFloat) / 2,
                    hlc: (point_json[2].getFloat + point_json[3].getFloat + point_json[4].getFloat) / 3,
                    ohlc: (point_json[1].getFloat + point_json[2].getFloat + point_json[3].getFloat + point_json[4].getFloat) / 4
                )

    chart

proc getBoard*(id: int, full: int = 20): board =
    let
        path_head = "/products/"
        path_foot = "/price_levels"
        client = newHttpClient()
        board_json = client.getContent(end_point & path_head & $id & path_foot).parseJson
    let
        bids = collect(newSeq):
            for order_json in board_json["sell_price_levels"]:
                (
                    price: order_json[0].getStr.parseFloat,
                    amount: order_json[1].getStr.parseFloat
                )
        asks = collect(newSeq):
            for order_json in board_json["buy_price_levels"]:
                (
                    price: order_json[0].getStr.parseFloat,
                    amount: order_json[1].getStr.parseFloat
                )
        board = (
            timestamp: int board_json["timestamp"].getStr.parseFloat,
            bids: bids,
            asks: asks
        )
    
    board

#[ Authentication ]#
proc getSignature(api: api, path: string): HttpHeaders =
    var signature = toJWT(%*{
            "header": {
                "alg": "HS256",
                "typ": "JWT"
            },
            "claims": {
                "path": path,
                "nonce": $ int now().toTime.toUnix,
                "token_id": api.key
            }
        })
    
    signature.sign(api.secret)
    [
        (key: "X-Quoine-API-Version", val: $2),
        (key: "X-Quoine-Auth", val: $signature),
        (key: "Content-Type", val: "application/json")
    ].newHttpHeaders

#[ Private API (needs API auth) ]#
proc getAccount*(api: api): account =
    let
        path = "/accounts/balance"
        client = newHttpClient(headers=api.getSignature(path))
        accounts_json = client.getContent(end_point & path).parseJson
        accounts = collect(newSeq):
            for account_json in accounts_json:
                (
                    currency: account_json["currency"].getStr,
                    amount: account_json["balance"].getStr.parseFloat
                )
    
    accounts.toTable()

proc postOrder*(api: api, order_type: string, product_pair: string, side: string, quantity: float): string =
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

    echo body

    let
        client = newHttpClient(headers=api.getSignature(path))
        response = client.postContent(url=(end_point & path), body=body)

    response


when isMainModule:
    from ../token import liquid_token

    echo liquid_token.getAccount