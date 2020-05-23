import httpclient, times, json, sugar, math, os, tables, strutils, gnuplot, strformat
import types
from sequtils import zip

#[ Library functions ]#
func sum*[T](a: seq[T]): T =
    var sum: T
    for i in a:
        sum += i
    sum

func average*[T](a: seq[T]): T =
    T a.sum / float a.len

func truncate*(num: float, digit: int): float =
    floor(num * 10.0 ^ digit) / 10.0 ^ digit

func getDifference*(data: seq[chart]): seq[float] =
    collect(newSeq):
        for (old, now) in zip(data[0 .. data.len - 2], data[1 .. data.len - 1]):
            now.close - old.close

func getMovingAverage*(data: seq[chart], duration: int): seq[float] =
    collect(newSeq):
        for index in 0..data.len - duration:
            let c = collect(newSeq):
                for d in data[index..index + duration - 1]:
                    d.close
            c.average

proc sleepTimer*(unixnow: int64, time: int) =
    sleep(int((unixnow + time - now().toTime.toUnix) * 1000))

proc plotter*[T](horizontal_axis: seq[T], x_label: string = "", y_label:string = "", args: varargs[(seq[T], string)]) =
    if x_label != "": cmd &"set xlabel '{x_label}' tc rgb \"white\""
    if x_label != "": cmd &"set ylabel '{y_label}' tc rgb \"white\""
    cmd "set object 1 rect behind from screen 0,0 to screen 1,1 fc rgb \"#333631\" fillstyle solid 1.0"
    cmd "set border lc rgb \"white\""
    cmd "set key tc rgb \"white\""
    cmd "set grid"

    for (arg, title) in args:
        if horizontal_axis.len != arg.len:
            var e: ref RangeError
            new e
            e.msg = "horizontal_axis length not equal to arg length: " & $horizontal_axis.len & " == " & $arg.len
            raise e
        
        plot horizontal_axis, arg, title

proc newSeqFromCount*[T](length: int): seq[T] =
    collect(newSeq):
        for i in countup(1, length): i.T

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
            now_price = product.ask
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
                    
                if reserve == 0: # Buy Operation
                    echo "\n*** BUY OPERATION ***"
                    try:
                        echo api.order("market", 5, "buy", truncate(fiat / product.ask - 0.00002, 8))
                    except HttpRequestError:
                        echo "Operation Failed."
                    finally: discard
            else:
                if now_price + threshold.float < extreme_point:
                    extreme_point = now_price + threshold.float
        else:
            if now_price < extreme_point:
                trend = false

                if reserve != 0: # Sell Operation
                    echo "\n### SELL OPERATION ###"
                    try:
                        echo api.order("market", 5, "sell", reserve)
                    except HttpRequestError:
                        echo "Operation Failed."
                    finally: discard
            else:
                if now_price - threshold.float > extreme_point:
                    extreme_point = now_price - threshold.float
        
        echo "\n__________________________________________\n"
        unixnow.sleepTimer period