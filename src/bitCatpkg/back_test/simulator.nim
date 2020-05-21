import strutils, times, strformat
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
    var max_score = (
        duration: 0,
        threshold: 0.0,
        score: 0
    )

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
    score_chart = newSeqFromCount[float](data.len - score_chart.len) & score_chart
    
    (max_score, score_chart)

proc simulateMovingDifferentialMeanPolarReversal_arg(data: seq[chart], budget: float, duration: int, visualize: bool = false): (score, seq[float]) =
    let differences = data.getDifference
    var
        max_score = (
            duration: 0,
            threshold: 0.0,
            score: 0
        )
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
    score_chart = newSeqFromCount[float](data.len - score_chart.len) & score_chart

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

    stdout.write "score threshold: "
    let score_threshold = stdin.readLine.parseFloat

    let data = getChart(symbol, period, size)
    echo "*****************************"

    let
        smd_max = data.simulateSimpleMovingDifference(budget, score_threshold)
        smd_max_score_chart = data.simulateSimpleMovingDifference_arg(budget, smd_max.threshold.int)[1]
        smd_850 = data.simulateSimpleMovingDifference_arg(budget, 850)
        smd_1500 = data.simulateSimpleMovingDifference_arg(budget, 1500)
        smd_7000 = data.simulateSimpleMovingDifference_arg(budget, 7000)
        horizon = newSeqFromCount[float](data.len)

    echo "SMD max : ", smd_max
    echo "SMD 850 : ", smd_850[0]                # threshold: 1500
    echo "SMD 1500: ", smd_1500[0]                # threshold: 1500
    echo "SMD 7000: ", smd_7000[0]                # threshold: 1500

    horizon.plotter("", "", (smd_max_score_chart, &"SMD ({smd_max.threshold.int})"), (smd_850[1], "SMD (850)"), (smd_1500[1], "SMD (1500)"), (smd_7000[1], "SMD (7000)"))

    echo "press any key to continue..."
    discard stdin.readChar