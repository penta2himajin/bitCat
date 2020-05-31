import strutils, times, strformat
import ../types, ../library, ../wrapper/liquid


const spread = 500

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
                    reserve = truncate((budget + float score) / (now_price + spread), 6)
                    score -= int truncate((now_price + spread) * reserve, 6) - budget

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
        for price_threshold in countup(9000, 10000, 5):
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
                        reserve = truncate((budget + float score) / (now_price + spread), 6)
                        score -= int truncate((now_price + spread) * reserve, 6) - budget
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
                max_score.price = price_threshold / 10000
                max_score.score = score
            
            if score.float > budget * score_threshold:
                echo "threshold: ", threshold, " score: ", score
    
    max_score

proc simulateSimpleUpDownMovingDifference*(data: seq[chart], budget: float, score_threshold: float = 1): score =
    let differences = data.getDifference
    var max_score: score

    for sell_threshold in countup(0, 10000, 50):
        for buy_threshold in countup(0, 10000, 50):
            var
                score = 0
                reserve = 0.0
            
            for index in 0..<differences.len:
                let
                    now_price = data[index + 1].close
                    difference = differences[index]
                
                if -buy_threshold.float > difference:
                    if reserve == 0: # Buy Operation
                        reserve = truncate((budget + float score) / (now_price + spread), 6)
                        score -= int truncate((now_price + spread) * reserve, 6) - budget
                
                elif difference > sell_threshold.float:
                    if  reserve != 0:# Sell Operation
                        score += int truncate(now_price * reserve, 6) - budget
                        reserve = 0
            
            if reserve != 0:
                score += int truncate(data[data.len - 1].close * reserve, 8) - budget
            
            if score > max_score.score:
                max_score.buy = buy_threshold
                max_score.sell = sell_threshold
                max_score.score = score
            
            if score.float > budget * score_threshold:
                echo "buy: ", buy_threshold, "sell: ", sell_threshold, " score: ", score
    
    max_score

proc simulateThresholdUpDownMovingDifference*(data: seq[chart], budget: float, buy_threshold: int, sell_threshold: int, score_threshold: float = 1): score =
    let differences = data.getDifference
    var max_score: score

    for price_threshold in countup(9000, 10000, 50):
        var
            score = 0
            reserve = 0.0
            buy_price = 0.0
                
        for index in 0..<differences.len:
            let
                now_price = data[index + 1].close
                difference = differences[index]
                    
            if -buy_threshold.float > difference:
                if reserve == 0: # Buy Operation
                    reserve = truncate((budget + float score) / (now_price + spread), 6)
                    score -= int truncate((now_price + spread) * reserve, 6) - budget
                    buy_price = now_price + spread
                    
            elif now_price < buy_price * float price_threshold / 10000:
                if reserve != 0:
                    score += int truncate(now_price * reserve, 6) - budget
                    reserve = 0
                    buy_price = 0
                    
            elif difference > sell_threshold.float:
                if  reserve != 0:# Sell Operation
                    score += int truncate(now_price * reserve, 6) - budget
                    reserve = 0
                    buy_price = 0
                
        if reserve != 0:
            score += int truncate(data[data.len - 1].close * reserve, 8) - budget
                
        if score > max_score.score:
            max_score.buy = buy_threshold
            max_score.sell = sell_threshold
            max_score.price = price_threshold / 10000
            max_score.score = score
                
        if score.float > budget * score_threshold:
            echo "buy: ", buy_threshold, "sell: ", sell_threshold, "price: ", price_threshold, " score: ", score
    
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
                    reserve = truncate((budget + float score) / (now_price + spread), 6)
                    score -= int truncate((now_price + spread) * reserve, 6) - budget
            
            else:
                if reserve != 0:
                    score += int truncate(now_price * reserve, 6) - budget
                    reserve = 0
        
            old_indicator = indicator
        
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
                reserve = truncate((budget + float score) / (now_price + spread), 6)
                score -= int truncate((now_price + spread) * reserve, 8) - budget
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
                reserve = truncate((budget + float score) / (now_price + spread), 6)
                score -= int truncate((now_price + spread) * reserve, 6) - budget
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
    max_score.price = price_threshold
    max_score.score = score
    score_chart = newSeq[float](data.len - score_chart.len) & score_chart
    
    (max_score, score_chart)

proc simulateSimpleUpDownMovingDifference_arg*(data: seq[chart], budget: float, buy_threshold: int, sell_threshold: int, visualize = false): (score, seq[float]) =
    let differences = data.getDifference
    var
        max_score: score
        score_chart = newSeq[float]()
        score = 0
        reserve = 0.0
            
    for index in 0..<differences.len:
        let
            now_price = data[index + 1].close
            difference = differences[index]
                
        if -buy_threshold.float > difference:
            if reserve == 0: # Buy Operation
                reserve = truncate((budget + float score) / (now_price + spread), 6)
                score -= int truncate((now_price + spread) * reserve, 6) - budget
                
        elif difference > sell_threshold.float:
            if  reserve != 0:# Sell Operation
                score += int truncate(now_price * reserve, 6) - budget
                reserve = 0
        
        if reserve != 0:
            score_chart.add (truncate(reserve * now_price, 0) - budget) * 100 / budget
        else:
            score_chart.add score.float * 100 / budget
            
    if reserve != 0:
        score += int truncate(data[data.len - 1].close * reserve, 8) - budget

    max_score.buy = buy_threshold
    max_score.sell = sell_threshold
    max_score.score = score
    score_chart = newSeq[float](data.len - score_chart.len) & score_chart
    
    (max_score, score_chart)

proc simulateThresholdUpDownMovingDifference_arg*(data: seq[chart], budget: float, buy_threshold: int, sell_threshold: int, price_threshold: float): (score, seq[float]) =
    let differences = data.getDifference
    var
        max_score: score
        score_chart = newSeq[float]()
        score = 0
        reserve = 0.0
        buy_price = 0.0
                
    for index in 0..<differences.len:
        let
            now_price = data[index + 1].close
            difference = differences[index]
                    
        if -buy_threshold.float > difference:
            if reserve == 0: # Buy Operation
                reserve = truncate((budget + float score) / (now_price + spread), 6)
                score -= int truncate((now_price + spread) * reserve, 6) - budget
                buy_price = now_price
                    
        elif now_price < buy_price * float price_threshold:
            if reserve != 0:
                score += int truncate(now_price * reserve, 6) - budget
                reserve = 0
                buy_price = 0
                    
        elif difference > sell_threshold.float:
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

    max_score.buy = buy_threshold
    max_score.sell = sell_threshold
    max_score.price = price_threshold
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
                reserve = truncate((budget + float score) / (now_price + spread), 6)
                score -= int truncate((now_price + spread) * reserve, 6) - budget
            
        else:
            if reserve != 0:
                score += int truncate(now_price * reserve, 6) - budget
                reserve = 0
        
        if reserve != 0:
            score_chart.add (truncate(reserve * now_price, 0) - budget) * 100 / budget
        else:
            score_chart.add score.float * 100 / budget
        
        old_indicator = indicator
        
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
        tmd_max = data.simulateThresholdMovingDifference budget
        sma_max = data.simulateSimpleMovingAverage budget
        sudmd_max = data.simulateSimpleUpDownMovingDifference budget
        tudmd_max = data.simulateThresholdUpDownMovingDifference(budget, sudmd_max.buy, sudmd_max.sell)
        horizon = newSeqFromCount[float](data.len)

    echo " SMD  max: ", smd_max
    echo " TMD  max: ", tmd_max
    echo " SMA  max: ", sma_max
    echo "SUDMD max: ", sudmd_max
    echo "TUDMD max: ", tudmd_max

    let
        smd_max_score_chart = data.simulateSimpleMovingDifference_arg(budget, smd_max.threshold.int)[1]
        tmd_max_score_chart = data.simulateThresholdMovingDifference_arg(budget, tmd_max.threshold.int, tmd_max.price)[1]
        sudmd_max_score_chart = data.simulateSimpleUpDownMovingDifference_arg(budget, sudmd_max.buy, sudmd_max.sell)[1]
        tudmd_max_score_chart = data.simulateThresholdUpDownMovingDifference_arg(budget, tudmd_max.buy, tudmd_max.sell, tudmd_max.price)[1]

    horizon.plotter("", "",
        (smd_max_score_chart, &"SMD (threshold: {smd_max.threshold.int})"),
        (tmd_max_score_chart, &"TMD (threshold: {tmd_max.threshold.int}, price threshold: {tmd_max.price.truncate(4) * 100}%)"),
        (sudmd_max_score_chart, &"SUDMD (Buy: {sudmd_max.buy}, Sell: {sudmd_max.sell})"),
        (tudmd_max_score_chart, &"TUDMD (Buy: {tudmd_max.buy}, Sell: {tudmd_max.sell}, Price: {tudmd_max.price.truncate(4) * 100}%)")
    )

    echo "press any key to continue..."
    discard stdin.readChar