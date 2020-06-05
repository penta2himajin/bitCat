import strutils, times, strformat, sugar, math
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
                echo "buy: ", buy_threshold, " sell: ", sell_threshold, " score: ", score
    
    max_score

proc simulateThresholdUpDownMovingDifference*(data: seq[chart], budget: float, buy_threshold: int, sell_threshold: int, score_threshold: float = 1): score =
    let differences = data.getDifference
    var max_score: score

    for price_threshold in countup(9500, 10000, 50):
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
            echo "buy: ", buy_threshold, " sell: ", sell_threshold, " price: ", price_threshold, " score: ", score
    
    max_score

proc simulateSimpleMovingReversal*(data: seq[chart], budget: float, score_threshold: float = 1): score =
    var max_score: score

    for reverse_threshold in countup(900, 1000):
        var
            score   = 0
            reserve = 0.0
            trend   = if data[0].close < data[1].close: true else: false
            high    = if trend: data[1].close else: data[0].close
            low     = if trend: data[0].close else: data[1].close

        for index in 2..<data.len:
            let now_price = data[index].close

            if not trend:
                if now_price > low * (1 + (1 - reverse_threshold / 1000)):
                    if reserve == 0: # Buy Operation
                        reserve = truncate((budget + float score) / (now_price + spread), 6)
                        score -= int truncate((now_price + spread) * reserve, 6) - budget

                    trend = true
                    high = now_price

                else:
                    if now_price < low:
                        low = now_price

            else:
                if now_price < high * (reverse_threshold / 1000):
                    if  reserve != 0:# Sell Operation
                        score += int truncate(now_price * reserve, 6) - budget
                        reserve = 0

                    trend = false
                    low = now_price
                        
                else:
                    if now_price > high:
                        high = now_price
                
        if reserve != 0:
            score += int truncate(data[data.len - 1].close * reserve, 8) - budget
                        
        if score > max_score.score:
            max_score.threshold = reverse_threshold / 1000
            max_score.score = score
                        
        if score.float > budget * score_threshold:
            echo " reverse: ", reverse_threshold / 1000, " score: ", score

    max_score

proc simulateMovingReversal*(data: seq[chart], budget: float, score_threshold: float = 1): score =
    var max_score: score

    for buy_threshold in countup(500, 50000, 500):
        for sell_threshold in countup(500, 50000, 500):
            for reverse_threshold in countup(90, 100):
                var
                    score   = 0
                    reserve = 0.0
                    trend   = if data[0].close < data[1].close: true else: false
                    high    = if trend: data[1].close else: data[0].close
                    low     = if trend: data[0].close else: data[1].close

                for index in 2..<data.len:
                    let now_price = data[index].close

                    if not trend:
                        if now_price < high - buy_threshold.float:
                            if reserve == 0: # Buy Operation
                                reserve = truncate((budget + float score) / (now_price + spread), 6)
                                score -= int truncate((now_price + spread) * reserve, 6) - budget

                        if now_price > low * (1 + (1 - reverse_threshold / 100)):
                            trend = true
                            high = now_price
                        
                        else:
                            if now_price < low:
                                low = now_price
                    
                    else:
                        if now_price > low + sell_threshold.float:
                            if  reserve != 0:# Sell Operation
                                score += int truncate(now_price * reserve, 6) - budget
                                reserve = 0

                        if now_price < high * (reverse_threshold / 100):
                            if  reserve != 0:# Sell Operation
                                score += int truncate(now_price * reserve, 6) - budget
                                reserve = 0

                            trend = false
                            low = now_price
                        
                        else:
                            if now_price > high:
                                high = now_price
                
                if reserve != 0:
                    score += int truncate(data[data.len - 1].close * reserve, 8) - budget
                        
                if score > max_score.score:
                    max_score.buy = buy_threshold
                    max_score.sell = sell_threshold
                    max_score.threshold = reverse_threshold / 100
                    max_score.score = score
                        
                if score.float > budget * score_threshold:
                    echo "buy: ", buy_threshold, " sell: ", sell_threshold, " reverse: ", reverse_threshold / 100, " score: ", score

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

proc simulateSimpleMovingReversal_arg*(data: seq[chart], budget: float, reverse_threshold: float): (score, seq[float]) =
    var
        max_score: score
        score_chart = newSeq[float]()
        score   = 0
        reserve = 0.0
        trend   = if data[0].close < data[1].close: true else: false
        high    = if trend: data[1].close else: data[0].close
        low     = if trend: data[0].close else: data[1].close

    for index in 2..<data.len:
        let now_price = data[index].close
                    
        if not trend:
            if now_price > low * (1 + (1 - reverse_threshold)):
                if reserve == 0: # Buy Operation
                    reserve = truncate((budget + float score) / (now_price + spread), 6)
                    score -= int truncate((now_price + spread) * reserve, 6) - budget

                trend = true
                high = now_price
                        
            else:
                if now_price < low:
                    low = now_price
                    
        else:
            if now_price < high * (reverse_threshold):
                if  reserve != 0:# Sell Operation
                    score += int truncate(now_price * reserve, 6) - budget
                    reserve = 0

                trend = false
                low = now_price

            else:
                if now_price > high:
                    high = now_price
        
        if reserve != 0:
            score_chart.add (truncate(reserve * now_price, 0) - budget) * 100 / budget
        else:
            score_chart.add score.float * 100 / budget
                
    if reserve != 0:
        score += int truncate(data[data.len - 1].close * reserve, 8) - budget                    

    max_score.threshold = reverse_threshold
    max_score.score = score
    score_chart = newSeq[float](data.len - score_chart.len) & score_chart

    (max_score, score_chart)

proc simulateMovingReversal_arg*(data: seq[chart], budget: float, buy_threshold: int, sell_threshold: int, reverse_threshold: float): (score, seq[float]) =
    var
        max_score: score
        score_chart = newSeq[float]()
        score   = 0
        reserve = 0.0
        trend   = if data[0].close < data[1].close: true else: false
        high    = if trend: data[1].close else: data[0].close
        low     = if trend: data[0].close else: data[1].close

    for index in 2..<data.len:
        let now_price = data[index].close
                    
        if not trend:
            if now_price < high - buy_threshold.float:
                if reserve == 0: # Buy Operation
                    reserve = truncate((budget + float score) / (now_price + spread), 6)
                    score -= int truncate((now_price + spread) * reserve, 6) - budget

            if now_price > low * (1 + (1 - reverse_threshold)):
                trend = true
                high = now_price
                        
            else:
                if now_price < low:
                    low = now_price
                    
        else:
            if now_price > low + sell_threshold.float:
                if  reserve != 0:# Sell Operation
                    score += int truncate(now_price * reserve, 6) - budget
                    reserve = 0

            if now_price < high * (reverse_threshold):
                if  reserve != 0:# Sell Operation
                    score += int truncate(now_price * reserve, 6) - budget
                    reserve = 0

                trend = false
                low = now_price

            else:
                if now_price > high:
                    high = now_price
        
        if reserve != 0:
            score_chart.add (truncate(reserve * now_price, 0) - budget) * 100 / budget
        else:
            score_chart.add score.float * 100 / budget
                
    if reserve != 0:
        score += int truncate(data[data.len - 1].close * reserve, 8) - budget                    
    
    max_score.buy = buy_threshold
    max_score.sell = sell_threshold
    max_score.threshold = reverse_threshold
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

proc simulatePartialProbabilityTrade_arg*(data: seq[chart], budget: float, score_threshold: float = 1): (score, seq[float]) =
    var
        max_score: score
        score_chart = newSeq[float]()
        
        old_price = data[0].close
        trend: bool
        trend_index: int
        
        score = int budget
        reserve = 0.0
    

    for i in 1..<data.len:
        let now_price = data[i].close
        
        echo "index: ", i, 
            " trend: ", trend,
            " trend_index: ", trend_index,
            " score: ", score,
            " reserve: ", reserve,
            " time: ", data[i].timestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss")
        
        if now_price < old_price:
            if trend:
                #[ let buy = truncate(score.float * (round(1/8 * 1000) / 1000.0) / (now_price + spread), 8)
                reserve += truncate(score.float * (round(1/8 * 1000) / 1000.0) / (now_price + spread), 8)
                score -= int truncate((now_price + spread) * buy, 8) ]#

                trend = false
                trend_index = 0
            
            else:
                if trend_index == 3:
                    let buy = truncate(score.float * (round(1/8 * 1000) / 1000.0) / (now_price + spread), 8)
                    reserve += truncate(score.float * (round(1/8 * 1000) / 1000.0) / (now_price + spread), 8)
                    score -= int truncate((now_price + spread) * buy, 8)

                if trend_index == 4:
                    let buy = truncate(score.float * (round(2/7 * 1000) / 1000) / (now_price + spread), 8)
                    reserve += truncate(score.float * (round(2/7 * 1000) / 1000) / (now_price + spread), 8)
                    score -= int truncate((now_price + spread) * buy, 8)
                
                elif trend_index == 5:
                    let buy = truncate(score.float / (now_price + spread), 8)
                    reserve += truncate(score.float / (now_price + spread), 8)
                    score -= int truncate((now_price + spread) * buy, 8)

                trend_index += 1
        
        elif now_price > old_price:
            if not trend:
                if reserve != 0: # Sell Operation
                    score += int truncate(now_price * reserve * (round(1/8 * 1000) / 1000), 8)
                    reserve -= truncate(reserve * (round(1/8 * 1000) / 1000), 8)
                
                trend = true
                trend_index = 0
            
            else:
                if trend_index == 0:
                    if reserve != 0: # Sell Operation
                        score += int truncate(now_price * reserve * (round(2/7 * 1000) / 1000), 8)
                        reserve -= truncate(reserve * (round(2/7 * 1000) / 1000), 8)
                
                if trend_index == 1:
                    if reserve != 0: # Sell Operation
                        score += int truncate(now_price * reserve, 8)
                        reserve = 0

                trend_index += 1
        
        old_price = now_price
        
        if reserve != 0:
            score_chart.add (truncate(now_price * reserve, 8) + score.float - budget) / budget * 100
        else:
            score_chart.add (score.float - budget) * 100 / budget
        
    if reserve != 0:
        score += int truncate(data[data.len - 1].close * reserve, 8) - budget

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

    #[ stdout.write "difference: "
    let diff = stdin.readLine.parseInt ]#

    let data = getChart(symbol, period, size)
    echo "*****************************"

    let
        data_close = collect(newSeq):
            for d in data:
                (d.close / data[0].close - 1) * 100
        #smd_max = data.simulateSimpleMovingDifference budget
        #tmd_max = data.simulateThresholdMovingDifference budget
        #sudmd_max = data.simulateSimpleUpDownMovingDifference budget
        #tudmd_max = data.simulateThresholdUpDownMovingDifference(budget, sudmd_max.buy, sudmd_max.sell)
        #sma_max = data.simulateSimpleMovingAverage budget
        #smr_max = data.simulateSimpleMovingReversal budget
        #mr_max = data.simulateMovingReversal budget
        ppt = data.simulatePartialProbabilityTrade_arg(budget)
        horizon = newSeqFromCount[float](data.len)

    #echo " SMD  max: ", smd_max
    #echo " TMD  max: ", tmd_max
    #echo "SUDMD max: ", sudmd_max
    #echo "TUDMD max: ", tudmd_max
    #echo " SMA  max: ", sma_max
    #echo "  MR  max: ", mr_max
    echo "   PPT max: ", ppt[0]

    let
        #smd_max_score_chart = data.simulateSimpleMovingDifference_arg(budget, smd_max.threshold.int)[1]
        #tmd_max_score_chart = data.simulateThresholdMovingDifference_arg(budget, tmd_max.threshold.int, tmd_max.price)[1]
        #sudmd_max_score_chart = data.simulateSimpleUpDownMovingDifference_arg(budget, sudmd_max.buy, sudmd_max.sell)[1]
        #tudmd_max_score_chart = data.simulateThresholdUpDownMovingDifference_arg(budget, tudmd_max.buy, tudmd_max.sell, tudmd_max.price)[1]
        #tudmd_2900_3700_098 = data.simulateThresholdUpDownMovingDifference_arg(budget, 2900, 3700, 0.95)[1]
        #smr_max_score_chart = data.simulateSimpleMovingReversal_arg(budget, smr_max.threshold)[1]
        #mr_max_score_chart = data.simulateMovingReversal_arg(budget, mr_max.buy, mr_max.sell, mr_max.threshold)[1]
        ppt_score_chart = ppt[1]

    horizon.plotter("", "",
        (data_close, "close"),
        #(smd_max_score_chart, &"SMD (threshold: {smd_max.threshold.int})"),
        #(tmd_max_score_chart, &"TMD (threshold: {tmd_max.threshold.int}, price threshold: {tmd_max.price.truncate(4) * 100}%)"),
        #(sudmd_max_score_chart, &"SUDMD (Buy: {sudmd_max.buy}, Sell: {sudmd_max.sell})"),
        #(tudmd_max_score_chart, &"TUDMD (Buy: {tudmd_max.buy}, Sell: {tudmd_max.sell}, Price: {tudmd_max.price.truncate(4) * 100}%)"),
        #(tudmd_2900_3700_098, &"TUDMD (Buy: 2900, Sell: 3700, Price: 95%)"),
        #(smr_max_score_chart, &"SMR (Reverse: {smr_max.threshold * 100}%)"),
        #(mr_max_score_chart, &"MR (Buy: {mr_max.buy}, Sell: {mr_max.sell}, Reverse: {int mr_max.threshold * 100}%)"),
        (ppt_score_chart, "PPT"),
    )

    #[ let
        data_close = collect(newSeq):
            for d in data:
                (d.close / data[0].close - 1) * 100
        differences = data.getDifference
        horizon = newSeqFromCount[float](data.len)
    var
        diff_sums = collect(newSeq):
            for i in 0..differences.len - diff:
                sum[float](differences[i..i + diff - 1])
        diff_average = collect(newSeq):
            for i in 0..differences.len - diff:
                average[float](differences[i..i + diff - 1])
        diff_test = collect(newSeq):
            for i in 0..<differences.len:
                differences[i] / data[i + 1].close * 100
    
    diff_sums = newSeq[float](data.len - diff_sums.len) & diff_sums
    diff_average = newSeq[float](data.len - diff_average.len) & diff_average
    diff_test = newSeq[float](data.len - diff_test.len) & diff_test

    horizon.plotter("time", "move",
        (data_close, "real data"),
        #(diff_sums, &"difference sum"),
        #(diff_average, "difference average"),
        (diff_test, "diff test") 
    ) ]#

    echo "press any key to continue..."
    discard stdin.readChar