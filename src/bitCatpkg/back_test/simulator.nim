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

proc simulateSimpleTrendMovingDifference*(data: seq[chart], budget: float, score_threshold: float = 1): score =
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

proc simulateThresholdTrendMovingDifference*(data: seq[chart], budget: float, buy_threshold: int, sell_threshold: int, score_threshold: float = 1): score =
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

    for reverse_threshold in countup(80, 100):
        var
            score   = 0
            reserve = 0.0
            trend   = if data[0].close < data[1].close: true else: false
            high    = if trend: data[1].close else: data[0].close
            low     = if trend: data[0].close else: data[1].close

        for index in 2..<data.len:
            let now_price = data[index].close

            if not trend:
                if now_price > low * (1 + (1 - reverse_threshold / 100)):
                    if reserve == 0: # Buy Operation
                        reserve = truncate((budget + float score) / (now_price + spread), 6)
                        score -= int truncate((now_price + spread) * reserve, 6) - budget

                    trend = true
                    high = now_price

                else:
                    if now_price < low:
                        low = now_price

            else:
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
            max_score.threshold = reverse_threshold / 100
            max_score.score = score

        if score.float > budget * score_threshold:
            echo "reverse: ", reverse_threshold / 100, " score: ", score

    max_score

proc simulateThresholdMovingReversal*(data: seq[chart], budget: float, score_threshold: float = 1): score =
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

proc simulateMovingAverageEstimate*(data: seq[chart], budget: float, score_threshold: float = 1): score =
    var max_score: score

    for t in 950..1000:
        let threshold = t / 1000
        for duration in 15..60:
            let ma_seq = data.getMovingAverage duration

            for difference in 0..duration - int duration/10:
                for p in 990..1000:
                    let price_threshold = p / 1000
                    var
                        score = 0
                        reserve = 0.0
                        buy_price = 0.0
                    
                    for index in duration + 1..<data.len:
                        let
                            now_price = data[index].close
                            estimated = ma_seq[index - duration] + (ma_seq[index - duration] - ma_seq[index - duration - 1]) * difference.float
                        
                        if now_price > estimated * (1 + (1 - threshold)):
                            if reserve == 0: # Buy Operation
                                reserve = truncate((budget + float score) / (now_price + spread), 8)
                                score -= int truncate((now_price + spread) * reserve, 8) - budget
                                buy_price = (now_price + spread)
                        
                        if now_price < buy_price * price_threshold:
                            score += int truncate(now_price * reserve, 8) - budget
                            reserve = 0
                            buy_price = 0
                        
                        elif now_price < estimated * threshold:
                            if reserve != 0: # Sell Operation
                                score += int truncate(now_price * reserve, 8) - budget
                                reserve = 0
                                buy_price = 0
                    
                    if reserve != 0:
                        score += int truncate(data[data.len - 1].close * reserve, 8) - budget
                        
                    if score > max_score.score:
                        max_score.duration = duration
                        max_score.difference = difference
                        max_score.threshold = threshold
                        max_score.price = price_threshold
                        max_score.score = score
                
                    if score.float > budget * score_threshold:
                        echo "duration: ", duration, " difference: ", difference, " threshold: ", threshold, " price_threshold: ", price_threshold, " score: ", score
    
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

proc simulateSimpleTrendMovingDifference_arg*(data: seq[chart], budget: float, buy_threshold: int, sell_threshold: int, visualize = false): (score, seq[float]) =
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

proc simulateThresholdTrendMovingDifference_arg*(data: seq[chart], budget: float, buy_threshold: int, sell_threshold: int, price_threshold: float): (score, seq[float]) =
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

proc simulateSimpleMovingReversal_arg*(data: seq[chart], budget: float, reverse_threshold: float, visualize: bool = false): (score, seq[float]) =
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
                    if visualize:
                        echo "BUY : ", score + truncate(reserve * now_price, 0).int,
                            " net: ", (score + truncate(reserve * now_price, 0).int) - budget.int,
                            " time: ", data[index + 1].timestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss")

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
                    if visualize:
                        echo "SELL: ", score + int budget,
                            " net: ", score,
                            " time: ", data[index + 1].timestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss")

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

proc simulateThresholdMovingReversal_arg*(data: seq[chart], budget: float, buy_threshold: int, sell_threshold: int, reverse_threshold: float): (score, seq[float]) =
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

proc simulateMovingAverageEstimate_arg*(data: seq[chart], budget: float, duration: int, difference: int, threshold: float, price_threshold: float): (score, seq[float]) =
    let ma_seq = data.getMovingAverage duration
    var
        max_score: score
        score_chart = newSeq[float]()
        score = 0
        reserve = 0.0
        buy_price = 0.0
        
    for index in duration + 1..<data.len:
        let
            now_price = data[index].close
            estimated = ma_seq[index - duration] + (ma_seq[index - duration] - ma_seq[index - duration - 1]) * difference.float
            
        if now_price > estimated * (1 + (1 - threshold)):
            if reserve == 0: # Buy Operation
                reserve = truncate((budget + float score) / (now_price + spread), 8)
                score -= int truncate((now_price + spread) * reserve, 8) - budget
                buy_price = 0
                        
        if now_price < buy_price * price_threshold:
            score += int truncate(now_price * reserve, 8) - budget
            reserve = 0
            buy_price = 0
            
        elif now_price < estimated * threshold:
            if reserve != 0: # Sell Operation
                score += int truncate(now_price * reserve, 8) - budget
                reserve = 0
                buy_price = 0
        
        if reserve != 0:
            score_chart.add (truncate(reserve * now_price, 0) - budget) * 100 / budget
        else:
            score_chart.add score.float * 100 / budget
        
    if reserve != 0:
        score += int truncate(data[data.len - 1].close * reserve, 8) - budget
    
    max_score.duration = duration
    max_score.difference = difference
    max_score.threshold = threshold
    max_score.score = score
    score_chart = newSeq[float](data.len - score_chart.len) & score_chart
    
    (max_score, score_chart)

proc simulateSimpleDurationReversal*(data: seq[chart], budget: float, buy: int, sell: int): (score, seq[float]) =
    var
        max_score: score
        score_chart = newSeq[float]()
        trend = if data[1].close - data[0].close > 0: true else: false
        trend_index = 0
        score = 0
        reserve = 0.0
    
    for i in 2..<data.len:
        let now_price = data[i].close

        if not trend:
            if data[i].close - data[i - 1].close > 0:
                trend = true
                trend_index = i

            if i - trend_index + 1 == buy:
                if reserve == 0: # Buy Operation
                    reserve = truncate((budget.int + score) / int(now_price + spread), 8)
                    score -= int truncate((now_price + spread) * reserve, 8) - budget
                    #[ echo "BUY : ", score + truncate(reserve * now_price, 0).int,
                        "\tnet: ", (score + truncate(reserve * now_price, 0).int) - budget.int,
                        " \ttime: ", data[i + 1].timestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss") ]#

        else:
            if data[i].close - data[i - 1].close < 0:
                trend = false
                trend_index = i

            if i - trend_index + 1 == sell and reserve != 0: # Sell Operation
                if reserve != 0: # Sell Operation
                    score += int truncate(now_price * reserve, 8) - budget
                    reserve = 0
                    #[ echo "SELL: ", score + int budget,
                        "\tnet: ", score,
                        " \ttime: ", data[i + 1].timestamp.fromUnix.format("yyyy-MM-dd HH:mm:ss") ]#
        
        if reserve != 0:
            score_chart.add (truncate(reserve * now_price, 0) - budget) * 100 / budget
        else:
            score_chart.add score.float * 100 / budget
    
    if reserve != 0:
        score += int truncate(data[data.len - 1].close * reserve, 8) - budget
    
    max_score.buy = buy
    max_score.sell = sell
    max_score.score = score
    score_chart = newSeq[float](data.len - score_chart.len) & score_chart
    
    (max_score, score_chart)

proc simulateAutomatedSimpleMovingReversal*(data: seq[chart], budget: float, duration: int): (score, seq[float]) =
    var
        max_score: score
        score_chart = newSeq[float]()
        score   = 0
        reserve = 0.0
        trend   = if data[0].close < data[1].close: true else: false
        high    = if trend: data[1].close else: data[0].close
        low     = if trend: data[0].close else: data[1].close

    for index in duration..<data.len:
        let
            now_price = data[index].close
            reverse_threshold = data[index - duration..index].simulateSimpleMovingReversal(budget).threshold
                    
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
            if now_price < high * reverse_threshold:
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

    max_score.score = score
    score_chart = newSeq[float](data.len - score_chart.len) & score_chart

    (max_score, score_chart)


when isMainModule:
    const
        symbol = "btcjpy"
        period = "1min"
        size   = 5760
        budget = 5000.0

    #[ stdout.write "symbol: "
    let symbol = stdin.readLine ]#

    #[ stdout.write "period: "
    let period: string = stdin.readLine ]#

    #[ stdout.write "budget: "
    let budget = stdin.readLine.parseFloat ]#

    #[ stdout.write "data size: "
    let size = stdin.readLine.parseInt - 1 ]#

    #[ stdout.write "difference: "
    let diff = stdin.readLine.parseInt ]#

    let data = getChart(symbol, period, size)
    echo "*****************************"

    let
        horizon = newSeqFromCount[float](data.len)
        data_close = collect(newSeq):
            for d in data:
                (d.close / data[0].close - 1) * 100
        #smd_max = data.simulateSimpleMovingDifference budget
        #tmd_max = data.simulateThresholdMovingDifference budget
        #stmd_max = data.simulateSimpleTrendMovingDifference budget
        #ttmd_max = data.simulateThresholdTrendMovingDifference(budget, stmd_max.buy, stmd_max.sell)
        smr_max = data.simulateSimpleMovingReversal budget
        #tmr_max = data.simulateThresholdMovingReversal budget
        #mae_max = data.simulateMovingAverageEstimate budget
        #smd_max_score_chart = data.simulateSimpleMovingDifference_arg(budget, smd_max.threshold.int)[1]
        #tmd_max_score_chart = data.simulateThresholdMovingDifference_arg(budget, tmd_max.threshold.int, tmd_max.price)[1]
        #ttmd_max_score_chart = data.simulateThresholdTrendMovingDifference_arg(budget, ttmd_max.buy, ttmd_max.sell, ttmd_max.price)[1]
        smr_max_score_chart = data.simulateSimpleMovingReversal_arg(budget, smr_max.threshold)[1]
        asmr_max_score_chart = data.simulateAutomatedSimpleMovingReversal(budget, 1440)
        #tmr_max_score_chart = data.simulateThresholdMovingReversal_arg(budget, tmr_max.buy, tmr_max.sell, tmr_max.threshold)[1]
        #mae_max_score_chart = data.simulateMovingAverageEstimate_arg(budget, mae_max.duration, mae_max.difference, mae_max.threshold, mae_max.price)[1]

    #echo " SMD  max: ", smd_max
    #echo " TMD  max: ", tmd_max
    #echo "STMD max: ", stmd_max
    #echo "TTMD max: ", ttmd_max7
    echo " SMR  max: ", smr_max
    echo "ASMR  max: ", asmr_max_score_chart[0]
    #echo " TMR  max: ", tmr_max
    #echo " MAE  max: ", mae_max

    horizon.plotter("", "",
        (data_close, "close"),
        #(smd_max_score_chart, &"SMD (threshold: {smd_max.threshold.int})"),
        #(tmd_max_score_chart, &"TMD (threshold: {tmd_max.threshold.int}, price threshold: {tmd_max.price.truncate(4) * 100}%)"),
        #(ttmd_max_score_chart, &"TTMD (Buy: {ttmd_max.buy}, Sell: {ttmd_max.sell}, Price: {ttmd_max.price.truncate(4) * 100}%)"),
        (smr_max_score_chart, &"SMR (Reverse: {int smr_max.threshold * 100}%)"),
        (asmr_max_score_chart[1], &"ASMR"),
        #(tmr_max_score_chart, &"TMR (Buy: {tmr_max.buy}, Sell: {tmr_max.sell}, Reverse: {int tmr_max.threshold * 100}%)"),
        #(data.simulateThresholdMovingReversal_arg(budget, 500, 500, 0.99)[1], "TMR (Buy: 500, Sell: 500, Reverse: 99%)"),
        #(mae_max_score_chart, &"MAE (duration: {mae_max.duration}, difference: {mae_max.difference}, threshold: {mae_max.threshold * 100}%, price threshold: {mae_max.price * 100}%)"),
    )

    stdout.write "press any key to continue..."
    discard stdin.readChar