import httpclient, times, json, os, tables, strutils
import types, library


#[ Trading functions ]#
proc tradeSimpleMovingDifference*(api: api, product: proc, chart: proc, order: proc, account: proc, period_string: string, threshold: int) =
    echo "Algorithm: Simple Moving Difference"
    echo " Period  : ", period_string
    echo "Threshold: ", threshold
    echo "******************************************\n"

    var
        period: int

    case period_string # sleepTimer(sec)
    of  "1min": period = 60
    of  "5min": period = 300
    of "15min": period = 900
    of "30min": period = 1800
    of "1hour": period = 3600
    of "4hour": period = 14400
    of  "1day": period = 86400

    while true:
        let
            unixnow = now().toTime.toUnix
            difference = chart("btcjpy", period_string, 2).getDifference[0]
            product = product("btcjpy")
            accounts = api.account
            reserve = accounts["BTC"]
            fiat = accounts["JPY"]

        echo "now at ", now().format("yyyy-MM-dd HH:mm:ss"), "\n"

        echo "JPY: ", fiat
        echo "BTC: ", reserve, "\n"

        echo "rate (BTCJPY): ", product.last_traded_price
        echo "indicator: ", difference

        if -threshold.float > difference:
            if reserve == 0: # Buy Operation
                echo "\n*** BUY OPERATION ***"
                try:
                    echo api.order("market", 5, "buy", truncate(fiat / product.ask - 0.00002, 8))
                except HttpRequestError:
                    echo "Operation Failed."
                finally: discard

        elif difference > threshold.float:
            if  reserve != 0:# Sell Operation
                echo "\n### SELL OPERATION ###"
                try:
                    echo api.order("market", 5, "sell", reserve)
                except HttpRequestError:
                    echo "Operation Failed."
                finally: discard
        
        echo "\n__________________________________________\n"
        unixnow.sleepTimer period

proc tradeMovingDifferentialMeanPolarReversal*(api: api, product: proc, chart: proc, order: proc, account: proc, period_string: string, duration: int) =
    echo "Algorithm: Moving Differential Mean Polar Reversal"
    echo " Period  : ", period_string
    echo "Duration : ", duration
    echo "******************************************\n"

    var
        period: int
        data = chart("btcjpy", period_string, duration + 1)
        point_old = data[0..duration - 1].getDifference.average
        point_now = data[1..duration].getDifference.average
        trend = if point_now > point_old: true else: false
    point_old = point_now

    case period_string # sleepTimer(sec)
    of  "1min": period = 60
    of  "5min": period = 300
    of "15min": period = 900
    of "30min": period = 1800
    of "1hour": period = 3600
    of "4hour": period = 14400
    of  "1day": period = 86400

    while true:
        let
            unixnow = now().toTime.toUnix
            product = product("btcjpy")

            accounts = api.account()
            reserve = accounts["BTC"]
            fiat = accounts["JPY"]
        point_now = chart("btcjpy", period_string, duration)[0..duration - 1].getDifference.average
        
        echo "now at ", now().format("yyyy-MM-dd HH:mm:ss"), "\n"

        echo "JPY: ", fiat
        echo "BTC: ", reserve, "\n"

        echo "rate (BTCJPY): ", product.last_traded_price
        echo "trend: ", trend
        echo "old difference: ", point_old
        echo "now difference: ", point_now

        if not trend:
            if point_now > point_old: # Buy Operation
                trend = true
                if reserve == 0:
                    echo "\n*** BUY OPERATION ***"
                    try:
                        echo api.order("market", 5, "buy", truncate(fiat / product.ask - 0.00002, 8))
                    except HttpRequestError:
                        echo "Operation Failed."
                    finally: discard

        else:
            if point_old > point_now: # Sell Operation
                trend = false
                if reserve != 0:
                    echo "\n### SELL OPERATION ###"
                    try:
                        echo api.order("market", 5, "sell", reserve)
                    except HttpRequestError:
                        echo "Operation Failed."
                    finally: discard

        point_old = point_now
        echo "\n__________________________________________\n"
        unixnow.sleepTimer period

proc tradeSimpleThresholdPolarReversal*(api: api, product: proc, chart: proc, order: proc, account: proc, period_string: string, threshold: int) =
    echo "Algorithm: Simple Threshold Polar Reversal"
    echo "Threshold: ", threshold
    echo "******************************************\n"

    var
        period: int
        data = chart("btcjpy", period_string, 2)
        trend = if data[0].close < data[1].close: true else: false
        extreme_point = if trend: data[1].close else: data[0].close

    case period_string # sleepTimer(sec)
    of  "1min": period = 60
    of  "5min": period = 300
    of "15min": period = 900
    of "30min": period = 1800
    of "1hour": period = 3600
    of "4hour": period = 14400
    of  "1day": period = 86400

    while true:
        let
            unixnow = now().toTime.toUnix
            product = product("btcjpy")
            now_price = product.bid
            accounts = api.account()
            reserve = accounts["BTC"]
            fiat = accounts["JPY"]
        
        echo "now at ", now().format("yyyy-MM-dd HH:mm:ss"), "\n"

        echo "JPY: ", fiat
        echo "BTC: ", reserve, "\n"

        echo "rate (BTCJPY): ", product.last_traded_price
        echo "trend: ", trend
        echo "extreme point: ", extreme_point

        if not trend:
            if now_price > extreme_point:
                trend = true
                extreme_point = product.ask - threshold.float
                    
                if reserve == 0: # Buy Operation
                    echo "\n*** BUY OPERATION ***"
                    try:
                        echo api.order("market", 5, "buy", truncate(fiat / product.ask - 0.00002, 8))
                    except HttpRequestError:
                        echo "Operation Failed."
                    finally: discard
            else:
                if product.ask + threshold.float < extreme_point:
                    extreme_point = product.ask + threshold.float
        else:
            if now_price < extreme_point:
                trend = false
                extreme_point = product.ask + threshold.float

                if reserve != 0: # Sell Operation
                    echo "\n### SELL OPERATION ###"
                    try:
                        echo api.order("market", 5, "sell", reserve)
                    except HttpRequestError:
                        echo "Operation Failed."
                    finally: discard
            else:
                if product.ask - threshold.float > extreme_point:
                    extreme_point = product.ask - threshold.float
        
        echo "\n__________________________________________\n"
        unixnow.sleepTimer period

proc tradeSimplePolarReversal*(api: api, product: proc, chart: proc, order: proc, account: proc, period_string: string) =
    echo "Algorithm: Simple Polar Reversal"
    echo "******************************************\n"

    var
        period: int
        data = chart("btcjpy", "1min", 2)
        trend = if data[0].close < data[1].close: true else: false
        extreme_point = if trend: data[1].close else: data[0].close

    case period_string # sleepTimer(sec)
    of  "2sec": period = 2
    of  "5sec": period = 5
    of "10sec": period = 10
    of "15sec": period = 15
    of "30sec": period = 30
    of  "1min": period = 60
    of  "5min": period = 300
    of "15min": period = 900
    of "30min": period = 1800
    of "1hour": period = 3600
    of "4hour": period = 14400
    of  "1day": period = 86400

    while true:
        let
            unixnow = now().toTime.toUnixFloat
            product = product("btcjpy")
            now_price = product.bid
            accounts = api.account()
            reserve = accounts["BTC"]
            fiat = accounts["JPY"]

        echo "now at ", unixnow.fromUnixFloat.format("yyyy-MM-dd HH:mm:ss"), "\n"

        echo "JPY: ", fiat
        echo "BTC: ", reserve, "\n"

        echo "rate (BTCJPY): ", product.last_traded_price
        echo "trend: ", trend
        echo "extreme point: ", extreme_point

        if not trend:
            if now_price > extreme_point:
                trend = true
                extreme_point = product.bid - product.spread
                    
                if reserve < 0.001: # Buy Operation
                    echo "\n*** BUY OPERATION ***"
                    try:
                        echo api.order("market", 5, "buy", fiat / product.ask - 0.00002)
                    except HttpRequestError:
                        echo "Operation Failed."
                    finally: discard
            else:
                if reserve > 0.001:
                    echo "\n### SELL OPERATION ###"
                    try:
                        echo api.order("market", 5, "sell", reserve)
                    except HttpRequestError:
                        echo "Operation Failed."
                    finally: discard
                if product.ask + product.spread < extreme_point:
                    extreme_point = product.ask + product.spread
        else:
            if now_price < extreme_point:
                trend = false
                extreme_point = product.ask + product.spread

                if reserve > 0.001: # Sell Operation
                    echo "\n### SELL OPERATION ###"
                    try:
                        echo api.order("market", 5, "sell", reserve)
                    except HttpRequestError:
                        echo "Operation Failed."
                    finally: discard
            else:
                if product.bid - product.spread > extreme_point:
                    extreme_point = product.bid - product.spread

        echo "\n__________________________________________\n"
        unixnow.sleepTimer period