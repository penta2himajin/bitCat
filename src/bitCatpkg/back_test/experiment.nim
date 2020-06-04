import times, math, system, os, strformat, math, sugar
import ../types, ../library, ../wrapper/liquid


when isMainModule:
    let
        data = getChart("btcjpy", "1min", 5760)
        differences = data.getDifference
    
    var
        up_count = newSeq[float](15)
        down_count = newSeq[float](15)
        trend = if differences[0] > 0: true else: false
        trend_index = 0
    
    for i in 1..<differences.len:
        if not trend:
            if differences[i] > 0:
                down_count[i - trend_index - 1] += 1
                trend = true
                trend_index = i
        else:
            if differences[i] < 0:
                up_count[i - trend_index - 1] += 1
                trend = false
                trend_index = i
    
    var
        up_sum = up_count.sum
        up_percentage = collect(newSeq):
            for u in up_count:
                int round(u / up_sum * 100)
        down_sum = down_count.sum
        down_percentage = collect(newSeq):
            for d in down_count:
                int round(d / down_sum * 100)
        horizon = newSeqFromCount[int](15)
    
    echo " up : ", up_percentage
    echo "down: ", down_percentage
    
    horizon.plotter("duration", "count",
        (up_percentage, "up (%)"),
        (down_percentage, "down (%)")
    )

    echo "press any key to continue..."
    discard stdin.readChar