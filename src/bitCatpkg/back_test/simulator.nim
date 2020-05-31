import strutils, times, strformat
import ../types, ../library, ../wrapper/liquid

#[ Simulator with full-auto parameters ]#
proc simulateSimpleMovingDifference*(data: seq[chart], budget: float, score_threshold: float = 1): score =
    let
        differences = data.getDifference
    var max_score: score

    for threshold in countup(0, 10000, 50):
        var
            score = 0
            reserve = 0.0

        for index in countup(0, differences.len - 1):
            let
                now_price = data[index + 1].close
                difference = differences[index]

            if -threshold.float > difference:
                if reserve == 0: # Buy Operation
                    reserve = truncate((budget + float score) / (now_price + 500), 6)
                    score -= int truncate((now_price + 500) * reserve, 6) - budget

            elif difference > threshold.float:
                if  reserve != 0:# Sell Operation
                    score += int truncate(now_price * reserve, 6) - budget
                    reserve = 0.0
        
        if reserve != 0:
            score += int truncate(data[data.len - 1].close * reserve, 8) - budget
        
        if score > max_score.score:
            max_score.threshold = threshold.float
            max_score.score = score
        
        if score.float > budget * score_threshold:
            echo "threshold: ", threshold, " score: ", score
    
    max_score

proc simulateThresholdMovingDifference*(data: seq[chart], budget: float, score_threshold: float = 1): score =
    let
        differences = data.getDifference
    var max_score: score

    for threshold in countup(0, 10000, 50):
        for price_threshold in countup(9900, 10000, 5):
            var
                score = 0
                reserve = 0.0
                buy_price = 0.0

            for index in 0..<differences.len:
                let
                    now_price = data[index + 1].close
                    difference = differences[index]

                if -threshold.float > difference:
                    if reserve == 0: # Buy Operation
                        reserve = truncate((budget + float score) / (now_price + 500), 6)
                        score -= int truncate((now_price + 500) * reserve, 6) - budget
                        buy_price = now_price
                
                elif now_price < buy_price * float price_threshold / 10000:
                    if reserve != 0:
                        score += int truncate(now_price * reserve, 6) - budget
                        reserve = 0
                        buy_price = 0

                elif difference > threshold.float:
                    if  reserve != 0:# Sell Operation
                        score += int truncate(now_price * reserve, 6) - budget
                        reserve = 0
                        buy_price = 0
            
            if reserve != 0:
                score += int truncate(data[data.len - 1].close * reserve, 8) - budget
            
            if score > max_score.score:
                max_score.threshold = threshold.float
                max_score.price_threshold = price_threshold / 10000
                max_score.score = score
            
            if score.float > budget * score_threshold:
                echo "threshold: ", threshold, " score: ", score
    
    max_score

proc simulateSimpleMovingAverage*(data: seq[chart], budget: float, score_threshold: float = 1): score =
    var max_score: score

    for duration in 2..int data.len/10:
        let ma = data.getMovingAverage duration
        var
            score = 0
            reserve = 0.0
            old_indicator: float
        
        for index in 0..<ma.len:
            let
                now_price = data[duration + index - 1].close
                indicator = ma[index]
            
            if indicator > old_indicator:
                if reserve == 0: # Buy Operation
                    reserve = truncate((budget + float score) / (now_price + 500), 6)
                    score -= int truncate((now_price + 500) * reserve, 6) - budget
            
            else:
                if reserve != 0:
                    score += int truncate(now_price * reserve, 6) - budget
                    reserve = 0
        
        if reserve != 0:
            score += int truncate(data[data.len - 1].close * reserve, 8) - budget
            
        if score > max_score.score:
            max_score.duration = duration
            max_score.score = score
            
        if score.float > budget * score_threshold:
            echo "duration: ", duration, " score: ", score
    
    max_score

#[ Simulator with Argument parameters ]#
proc simulateSimpleMovingDifference_arg*(data: seq[chart], budget: float, threshold: int, visualize: bool = false): (score, seq[float]) =
    let
        differences = data.getDifference
    var
        max_score: score
        score = 0
        reserve = 0.0
        score_chart = newSeq[float]()

    if visualize:
        echo "Threshold: ", threshold

    for index in countup(0, differences.len - 1):
        let
            now_price = data[index + 1].close
            difference = differences[index]

        if -threshold.float > difference:
            if reserve == 0: # Buy Operation
                reserve = truncate((budget + float score) / (now_price + 500), 6)
                score -= int truncate((now_price + 500) * reserve, 8) - budget
                if visualize:
                    echo "BUY : ", score + truncate(reserve * now_price, 0).int,
                        " net: ", (score + truncate(reserve * now_price, 0).int) - budget.int,
                        " time: ", data[index + 1].timestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss")
        elif difference > threshold.float:
            if  reserve != 0:# Sell Operation
                score += int truncate(now_price * reserve, 8) - budget
                reserve = 0.0
                if visualize:
                    echo "SELL: ", score + int budget,
                        " net: ", score,
                        " time: ", data[index + 1].timestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss")
        if reserve != 0:
            score_chart.add (truncate(reserve * now_price, 0) - budget) * 100 / budget
        else:
            score_chart.add score.float * 100 / budget
    
    if reserve != 0:
        score += int truncate(data[data.len - 1].close * reserve, 8) - budget

    max_score.threshold = threshold.float
    max_score.score = score
    score_chart = newSeq[float](data.len - score_chart.len) & score_chart
    
    (max_score, score_chart)

proc simulateThresholdMovingDifference_arg*(data: seq[chart], budget: float, threshold: int, price_threshold: float, visualize: bool = false): (score, seq[float]) =
    let
        differences = data.getDifference
    var
        max_score: score
        score_chart = newSeq[float]()
        score = 0
        reserve = 0.0
        buy_price = 0.0

    for index in countup(0, differences.len - 1):
        let
            now_price = data[index + 1].close
            difference = differences[index]

        if -threshold.float > difference:
            if reserve == 0: # Buy Operation
                reserve = truncate((budget + float score) / (now_price + 500), 6)
                score -= int truncate((now_price + 500) * reserve, 6) - budget
                buy_price = now_price
                
        elif now_price < buy_price * float price_threshold:
            if reserve != 0:
                score += int truncate(now_price * reserve, 6) - budget
                reserve = 0
                buy_price = 0

        elif difference > threshold.float:
            if  reserve != 0:# Sell Operation
                score += int truncate(now_price * reserve, 6) - budget
                reserve = 0
                buy_price = 0
        
        if reserve != 0:
            score_chart.add (truncate(reserve * now_price, 0) - budget) * 100 / budget
        else:
            score_chart.add score.float * 100 / budget
            
    if reserve != 0:
        score += int truncate(data[data.len - 1].close * reserve, 8) - budget

    max_score.threshold = threshold.float
    max_score.price_threshold = price_threshold
    max_score.score = score
    score_chart = newSeq[float](data.len - score_chart.len) & score_chart
    
    (max_score, score_chart)

proc simulateSimpleMovingAverage_arg*(data: seq[chart], budget: float, duration: int, visualize = false): (score, seq[float]) =
    let ma = data.getMovingAverage duration
    var
        max_score: score
        score_chart = newSeq[float]()
        score = 0
        reserve = 0.0
        old_indicator: float
        
    for index in 0..<ma.len:
        let
            now_price = data[duration + index - 1].close
            indicator = ma[index]
            
        if indicator > old_indicator:
            if reserve == 0: # Buy Operation
                reserve = truncate((budget + float score) / (now_price + 500), 6)
                score -= int truncate((now_price + 500) * reserve, 6) - budget
            
        else:
            if reserve != 0:
                score += int truncate(now_price * reserve, 6) - budget
                reserve = 0
        
        if reserve != 0:
            score_chart.add (truncate(reserve * now_price, 0) - budget) * 100 / budget
        else:
            score_chart.add score.float * 100 / budget
        
    if reserve != 0:
        score += int truncate(data[data.len - 1].close * reserve, 8) - budget

    max_score.duration = duration
    max_score.score = score
    score_chart = newSeq[float](data.len - score_chart.len) & score_chart
    
    (max_score, score_chart)


when isMainModule:
    stdout.write "symbol: "
    let symbol = stdin.readLine

    stdout.write "period: "
    let period: string = stdin.readLine

    stdout.write "budget: "
    let budget = stdin.readLine.parseFloat

    stdout.write "data size: "
    let size = stdin.readLine.parseInt - 1

    let data = getChart(symbol, period, size)
    echo "*****************************"

    let
        smd_max = data.simulateSimpleMovingDifference budget
        smd_max_score_chart = data.simulateSimpleMovingDifference_arg(budget, smd_max.threshold.int)[1]
        tmd_max = data.simulateThresholdMovingDifference budget
        tmd_max_score_chart = data.simulateThresholdMovingDifference_arg(budget, tmd_max.threshold.int, tmd_max.price_threshold)[1]
        sma_max = data.simulateSimpleMovingAverage budget
        sma_max_score_chart = data.simulateSimpleMovingAverage_arg(budget, sma_max.duration)[1]
        sma_450 = data.simulateSimpleMovingAverage_arg(budget, 450)[1]
        horizon = newSeqFromCount[float](data.len)

    echo "SMD max: ", smd_max
    echo "TMD max: ", tmd_max
    echo "SMA max: ", sma_max

    horizon.plotter("", "",
        (smd_max_score_chart, &"SMD (threshold: {smd_max.threshold.int})"),
        (tmd_max_score_chart, &"TMD (threshold: {tmd_max.threshold.int}, price threshold: {tmd_max.price_threshold.truncate(4) * 100}%)"),
        (sma_max_score_chart, &"SMA (duration : {sma_max.duration.int})"),
        (sma_450, "SMA (duration : 450)")
    )

    #[ let
        duration = 60
        horizon = newSeqFromCount[float](data.len)

    var
        ma = data.getMovingAverage duration
        normal_ma = ma
        estimated_ma: seq[float]
    
    for i in 0..<data.len - ma.len:
        normal_ma = ma[0] & normal_ma
    
    for i in ma.len..<data.len - difference:
        ma.add ((data[i..<data.len].getMovingAverage data.len - i)[0] + ma[ma.len - 1]) / 2

    for i in 0..<difference:
        ma = ma[0] & ma

    for index in duration + difference..<data.len:
        estimated_ma.add (ma[index - duration] + (data[duration..<index].getMovingAverage index - duration)[0]) / 2
    
    for i in 0..<duration + difference:
        estimated_ma = estimated_ma[0] & estimated_ma
    
    echo "chart length: ", data.len
    echo " ma length  : ", normal_ma.len
    
    horizon.plotter("time", "price",
        (data.close, "Chart Data"),
        (normal_ma, "Moving Average"),
        (ma, "Complemented Moving Average"),
        (estimated_ma, "Estimated Moving Average")
    ) ]#
    
    #[ var
        up_count = newSeq[int](16)
        down_count = newSeq[int](16)
        horizon = newSeqFromCount[int](16)
        trend = false
        trend_index = 0
    
    for i in 1..<data.len:
        if not trend and data[i - 1].close < data[i].close:
            down_count[i - trend_index - 1] += 1
            trend = true
            trend_index = i

        if trend and data[i - 1].close >= data[i].close:
            up_count[i - trend_index - 1] += 1
            trend = false
            trend_index = i
    
    horizon.plotter("duration", "count",
        (up_count, "Up"),
        (down_count, "Down")
    )

    echo " Up : ", up_count
    echo "Down: ", down_count ]#

    echo "press any key to continue..."
    discard stdin.readChar