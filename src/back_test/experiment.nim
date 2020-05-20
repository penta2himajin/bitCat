import options, httpclient, times, json, os
import types, library


proc simulateTrendingMovingDifferenceAverage(data: seq[chart], budget: float): score =
    let difference = data.getDifference
    var max_score: score = (
            duration: 0,
            threshold: 0.0,
            score: 0
        )
    
    for duration in countup(2, #[ toInt (data.len - 1)/10 ]# 2):
        var 
            span_score = 0
            trend_option: Option[bool]
            trend_index = 0
        
        while trend_option.isNone:
            trend_index += 1
            if data[trend_index].high > data[trend_index - 1].high and
                data[trend_index].low > data[trend_index - 1].low:
                trend_option = option(true)
            elif data[trend_index].high < data[trend_index - 1].high and
                data[trend_index].low < data[trend_index - 1].low:
                trend_option = option(false) 
    
        var 
            reserve = 0.0
            trend = trend_option.get()
            threshold = data[trend_index].hlc
            extreme_point = difference[trend_index]

        for span in countup(trend_index, data.len - duration):
            let
                now = difference[span..span + duration - 2].sum
                price = data[span].close

            if trend:
                if price < threshold:
                    trend = false
                    extreme_point = now
                    threshold = data[span].hlc
                    if reserve != 0.0: # Sell Operation
                        span_score += int (price * reserve) - budget
                        reserve = 0.0
                        #[ echo "SEL:  ", span_score + int budget, "   score:  ", span_score ]#
                elif extreme_point < now:
                    extreme_point = now
                    threshold = data[span].hlc
            else:
                if threshold < price:
                    trend = true
                    extreme_point = now
                    threshold = data[span].hlc
                    if reserve == 0.0: # Buy Operation
                        reserve = truncate((budget + float span_score) / price, 4)
                        span_score -= int truncate(reserve * price, 4) - budget
                        #[ echo "BUY:  ", int truncate(price * reserve, 4), " score: ", span_score ]#
                elif now < extreme_point:
                    extreme_point = now
                    threshold = data[span].hlc
        
        if reserve != 0:
            span_score += int data[data.len - 1].close * reserve - budget

        if max_score.score < span_score:
            max_score.score = span_score
            max_score.duration = duration
        
        #[ if span_score > 0:
            echo "_____________________________"
            echo "duration: ", duration
            echo "score: ", span_score

    echo "_____________________________" ]#
    max_score

func getParabolicStopAndReverse(data: seq[chart], init_acceleration_factor: float = 0.02, acceleration_factor_step: float = 0.02, max_acceleration_factor: float = 0.2): int =
    var 
        trend_index = 1
        trend_option: Option[bool]
    
    while trend_option.isNone():
        if data[trend_index].high > data[trend_index - 1].high and
            data[trend_index].low > data[trend_index - 1].low:
            trend_option = option(true)
        elif data[trend_index].high < data[trend_index - 1].high and
            data[trend_index].low < data[trend_index - 1].low:
            trend_option = option(false) 
        trend_index += 1
    
    var 
        trend = trend_option.get()
        parabolic_sar =
            if trend:
                data[trend_index - 1].low
            else:
                data[trend_index - 1].high
        extreme_point =
            if trend:
                data[trend_index].high
            else:
                data[trend_index].low
        acceleration_factor = init_acceleration_factor

    for index in countup(trend_index + 2, data.len() - 1):
        if trend:
            if data[index].low < parabolic_sar:
                trend = false
                parabolic_sar = extreme_point
                acceleration_factor = init_acceleration_factor
                extreme_point = data[index].low
            else:
                parabolic_sar = parabolic_sar + acceleration_factor * (data[index - 1].high - parabolic_sar)
                if extreme_point < data[index].high:
                    acceleration_factor = min(acceleration_factor + acceleration_factor_step, max_acceleration_factor)
                let temp_low =
                        if data[index - 1].low >= data[index - 2].low:
                            data[index - 2].low
                        else:
                            data[index - 1].low
                if parabolic_sar > temp_low:
                    parabolic_sar = temp_low
        else:
            if data[index].high > parabolic_sar:
                trend = true
                parabolic_sar = extreme_point
                acceleration_factor = init_acceleration_factor
                extreme_point = data[index].high
            else:
                parabolic_sar = parabolic_sar + acceleration_factor * (data[index - 1].low - parabolic_sar)
                if data[index].low < extreme_point:
                    acceleration_factor = min(acceleration_factor + acceleration_factor_step, max_acceleration_factor)
                let temp_high =
                        if data[index - 1].high >= data[index - 2].high:
                            data[index - 1].high
                        else:
                            data[index - 2].high
                if parabolic_sar < temp_high:
                    parabolic_sar = temp_high

    int parabolic_sar