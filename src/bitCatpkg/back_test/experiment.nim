import times, math, system, os, strformat, math
import ../types, ../library, ../wrapper/liquid

proc sleepTimer*(unixfloatnow: float, time: int) =
    sleep(floor((unixfloatnow + time.float - now().toTime.toUnixFloat) * 1000).int)

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


when isMainModule:
    const budget = 8000

    if not existsFile("duration.csv"):
        let f = open("duration.csv", fmWrite)
        f.writeLine "timestamp, data, score"
        f.close

    while true:
        let 
            unixfloatnow = now().toTime.toUnixFloat
            f = open("duration.csv", fmAppend)
            data = getChart("btcjpy", "1min", 5760)
            timestamp = unixfloatnow.fromUnixFloat.format("yyyy-MM-dd HH:mm:ss")
            max_score = data.simulateSimpleMovingAverage budget
            duration = max_score.duration
            score = floor(max_score.score.float / budget * 100).int

        f.writeLine &"{timestamp}, {duration}, {score}"
        echo &"timestamp: {timestamp}, duration: {duration}, score: {score}%"

        f.close
        unixfloatnow.sleepTimer 60