import strutils, times, strformat, sequtils
import ../types, ../library, ../wrapper/liquid

#[ Simulator with full-auto parameters ]#
proc simulateSimpleMovingDifference*(data: seq[chart], budget: float, score_threshold: float = 0.0): score =
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
                    reserve = truncate((budget + float score) / now_price, 6)
                    score -= int truncate(now_price * reserve, 6) - budget

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

proc simulateThresholdMovingDifference*(data: seq[chart], budget: float, score_threshold: float = 0.0): score =
    let
        differences = data.getDifference
    var max_score: score

    for threshold in countup(0, 10000, 50):
        for price_threshold in countup(9900, 10000, 5):
            var
                score = 0
                reserve = 0.0
                buy_price = 0.0

            for index in countup(0, differences.len - 1):
                let
                    now_price = data[index + 1].close
                    difference = differences[index]

                if -threshold.float > difference:
                    if reserve == 0: # Buy Operation
                        reserve = truncate((budget + float score) / now_price, 6)
                        score -= int truncate(now_price * reserve, 6) - budget
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

proc simulateSimpleMovingDifferentialMean*(data: seq[chart], budget: float, score_threshold: float = 0.0): score =
    let differences = data.getDifference
    var max_score: score

    for duration in countup(2, int data.len/10):
        var
            score = 0
            reserve = 0.0
        
        for index in countup(0, differences.len - 1):
            let
                now_price = data[index + 1].close
                difference = differences[index]
            
            if difference <= 0:
                if reserve == 0:
                    reserve = truncate((budget + float score) / now_price, 6)
                    score -= int truncate(now_price * reserve, 6) - budget

            elif difference > 0:
                if reserve != 0:
                    score += int truncate(now_price * reserve, 6) - budget
                    reserve = 0.0
        
        if reserve != 0:
            score += int truncate(data[data.len - 1].close * reserve, 6) - budget
        
        if score > max_score.score:
            max_score.duration = duration
            max_score.score = score
        
        if score.float > budget * score_threshold:
            echo "duration: ", duration, " score: ", score
    
    max_score

proc simulateMovingDifferentialMeanPolarReversal(data: seq[chart], budget: float, score_threshold: float = 0.0): score =
    let differences = data.getDifference
    var max_score: score

    for duration in countup(2, int data.len/10):
        var
            duration_score = 0
            reserve = 0.0
            point_old = differences[0..duration - 1].average
            point_now = differences[1..duration].average
            trend = if point_now > point_old: true else: false
        point_old = point_now
        # echo "\nduration: ", duration

        for index in countup(2, data.len - duration - 1):
            let now_price = data[index + duration].close
            point_now = differences[index..index + duration - 1].average

            if not trend:
                if point_now > point_old: # Buy Operation
                    trend = true
                    if reserve == 0:
                        reserve = truncate((budget + float duration_score) / now_price, 6)
                        duration_score -= int truncate(now_price * reserve, 6) - budget
            else: # if trend:
                if point_old > point_now: # Sell Operation
                    trend = false
                    if reserve != 0:
                        duration_score += int truncate(now_price * reserve, 6) - budget
                        reserve = 0.0

            point_old = point_now
                    
        if reserve != 0:
            duration_score += int truncate(data[data.len - 1].close * reserve, 4) - budget

        if duration_score > max_score.score:
            max_score.duration = duration
            max_score.score = duration_score
        
        if duration_score.float > budget * score_threshold:
            echo "duration: ", duration, " score: ", duration_score

    max_score

proc simulateSimpleThresholdPolarReversal*(data: seq[chart], budget: float, score_threshold: float = 0.0): score =
    var
        max_score: score
    
    for threshold in countup(0, 200, 1):
        var
            score = 0
            reserve = 0.0
            extreme_point = 0.0
            trend = if data[0].close < data[1].close: true else: false
        
        for index in countup(2, data.len - 1):
            let now_price = data[index].close

            if not trend:
                if now_price > extreme_point:
                    trend = true
                    
                    if reserve == 0:
                        reserve = truncate((budget + float score) / now_price, 8)
                        score -= int truncate(now_price * reserve, 8) - budget
                else:
                    if now_price + threshold.float < extreme_point:
                        extreme_point = now_price + threshold.float
            else:
                if now_price < extreme_point:
                    trend = false

                    if reserve != 0:
                        score += int truncate(now_price * reserve, 8) - budget
                        reserve = 0.0
                else:
                    if now_price - threshold.float > extreme_point:
                        extreme_point = now_price - threshold.float
        
        if reserve != 0:
            score += int truncate(data[data.len - 1].close * reserve, 8) - budget
        
        if score > max_score.score:
            max_score.threshold = threshold.float
            max_score.score = score
        
        if score.float > budget * score_threshold:
            echo "threshold: ", threshold, " score: ", score
    
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
                reserve = truncate((budget + float score) / now_price, 6)
                score -= int truncate(now_price * reserve, 8) - budget
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
                reserve = truncate((budget + float score) / now_price, 6)
                score -= int truncate(now_price * reserve, 6) - budget
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

proc simulateMovingDifferentialMeanPolarReversal_arg(data: seq[chart], budget: float, duration: int, visualize: bool = false): (score, seq[float]) =
    let differences = data.getDifference
    var
        max_score: score
        score_chart = newSeq[float]()
        duration_score = 0
        reserve = 0.0
        point_old = differences[0..duration - 1].average
        point_now = differences[1..duration].average
        trend = if point_now > point_old: true else: false
    point_old = point_now

    if visualize:
        echo "Duration: ", duration

    for index in countup(2, data.len - duration - 1):
        let now_price = data[index + duration].close
        point_now = differences[index..index + duration - 1].average

        if not trend:
            if point_now > point_old: # Buy Operation
                trend = true
                if reserve == 0:
                    reserve = truncate((budget + float duration_score) / now_price, 6)
                    duration_score -= int truncate(now_price * reserve, 8) - budget
                    if visualize:
                        echo "BUY : ", duration_score + truncate(reserve * now_price, 8).int,
                            " net: ", (duration_score + truncate(reserve * now_price, 8).int) - budget.int,
                            " time: ", data[index + 1].timestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss")

        else: # if trend:
            if point_old > point_now: # Sell Operation
                trend = false
                if reserve != 0:
                    duration_score += int truncate(now_price * reserve, 8) - budget
                    reserve = 0.0
                    if visualize:
                        echo "SELL: ", duration_score + int budget,
                            " net: ", duration_score,
                            " time: ", data[index + duration].timestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss")

        point_old = point_now

        if reserve != 0:
            score_chart.add (truncate(reserve * now_price, 0) - budget) * 100 / budget
        else:
            score_chart.add duration_score.float * 100 / budget
    
    if reserve != 0:
        duration_score += int truncate(data[data.len - 1].close * reserve, 4) - budget

    max_score.duration = duration
    max_score.score = duration_score
    score_chart = newSeq[float](data.len - score_chart.len) & score_chart

    (max_score, score_chart)

proc simulateSimpleThresholdPolarReversal_arg(data: seq[chart], budget: float, threshold: int, visualize: bool = false): (score, seq[float]) =
    var
        max_score: score
        score_chart = newSeq[float]()
        score = 0
        reserve = 0.0
        extreme_point = 0.0
        trend = if data[0].close < data[1].close: true else: false
        
    for index in countup(2, data.len - 1):
        let now_price = data[index].close

        if not trend:
            if now_price > extreme_point:
                trend = true
                    
                if reserve == 0:
                    reserve = truncate((budget + float score) / now_price, 8)
                    score -= int truncate(now_price * reserve, 8) - budget
                    if visualize:
                        echo "BUY : ", score + truncate(reserve * now_price, 8).int,
                            " net: ", (score + truncate(reserve * now_price, 8).int) - budget.int,
                            " time: ", data[index].timestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss")
            else:
                if now_price + threshold.float < extreme_point:
                    extreme_point = now_price + threshold.float
        else:
            if now_price < extreme_point:
                trend = false

                if reserve != 0:
                    score += int truncate(now_price * reserve, 8) - budget
                    reserve = 0.0
                    if visualize:
                        echo "SELL: ", score + int budget,
                            " net: ", score,
                            " time: ", data[index].timestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss")
            else:
                if now_price - threshold.float > extreme_point:
                    extreme_point = now_price - threshold.float

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


when isMainModule:
    stdout.write "symbol: "
    let symbol = stdin.readLine

    stdout.write "period: "
    let period: string = stdin.readLine

    #[ stdout.write "budget: "
    let budget = stdin.readLine.parseFloat ]#

    stdout.write "data size: "
    let size = stdin.readLine.parseInt - 1

    #[ stdout.write "score threshold: "
    let score_threshold = stdin.readLine.parseFloat ]#

    stdout.write "difference: "
    let difference = stdin.readLine.parseInt

    let data = getChart(symbol, period, size)
    echo "*****************************"

    #[ let
        smd_max = data.simulateSimpleMovingDifference(budget, score_threshold)
        smd_max_score_chart = data.simulateSimpleMovingDifference_arg(budget, smd_max.threshold.int)[1]
        smd_700 = data.simulateSimpleMovingDifference_arg(budget, 700)
        smd_850 = data.simulateSimpleMovingDifference_arg(budget, 850)
        tmd_max = data.simulateThresholdMovingDifference(budget, score_threshold)
        tmd_max_score_chart = data.simulateThresholdMovingDifference_arg(budget, tmd_max.threshold.int, tmd_max.price_threshold)[1]
        tmd_750 = data.simulateThresholdMovingDifference_arg(budget, 750, 0.9995)
        mdmpr_max = data.simulateMovingDifferentialMeanPolarReversal(budget, score_threshold)
        mdmpr_max_score_chart = data.simulateMovingDifferentialMeanPolarReversal_arg(budget, mdmpr_max.duration.int)[1]
        stpr_max = data.simulateSimpleThresholdPolarReversal(budget, score_threshold)
        stpr_max_score_chart = data.simulateSimpleThresholdPolarReversal_arg(budget, stpr_max.threshold.int)[1]
        stpr_57 = data.simulateSimpleThresholdPolarReversal_arg(budget, 57)
        horizon = newSeqFromCount[float](data.len)

    echo "SMD max  : ", smd_max
    echo "SMD 700  : ", smd_700[0]
    echo "SMD 850  : ", smd_850[0]
    echo "TMD max  : ", tmd_max
    echo "TMD 750 99.95%  : ", tmd_750[0]
    echo "MDMPR max: ", mdmpr_max
    echo "STPR max : ", stpr_max
    echo "STPR 57  : ", stpr_57[0]

    horizon.plotter("", "",
        (smd_max_score_chart, &"SMD (threshold: {smd_max.threshold.int})"),
        (smd_700[1], "SMD (700)"),
        (smd_850[1], "SMD (850)"),
        (tmd_max_score_chart, &"TMD (threshold: {tmd_max.threshold.int}, price threshold: {tmd_max.price_threshold.truncate(4) * 100}%)"),
        (tmd_750[1], "TMD (threshold: 750, price threshold: 99.95%)"),
        (mdmpr_max_score_chart, &"MDMPR (duration: {mdmpr_max.duration.int})"),
        (stpr_max_score_chart, &"STPR (threshold: {stpr_max.threshold.int})"),
        (stpr_57[1], "STPR (threshold: 57)")
    ) ]#

    let
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
    )

    echo "press any key to continue..."
    discard stdin.readChar