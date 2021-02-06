import math, system, strformat, math, sugar
import ../types, ../library, ../wrapper/liquid


func close*(data: seq[chart]): seq[float] =
    collect(newSeq):
        for d in data:
            d.close

func difference*[T](data: seq[T]): seq[T] =
    collect(newSeq):
        for i in 1..<data.len:
            data[i] - data[i - 1]


when isMainModule:
    const
        count = 15
        spread = 0.0005
        sell = 2
        budget = 5000
    let
        data = getChart("btcjpy", "1min", 5760)
        differences = data.getDifference
    
    var
        up_count = newSeq[float](count)
        down_count = newSeq[float](count)
        up_score_sum = newSeq[float](count)
        down_score_sum = newSeq[float](count)
        trend = if differences[0] > 0: true else: false
        trend_index = 0
    
    for i in 1..<differences.len:
        if not trend:
            if differences[i] > 0:
                down_count[i - trend_index - 1] += 1

                let score = collect(newSeq):
                        for d in data[trend_index..i - 1]:
                            d.close - data[trend_index].close

                down_score_sum[i - trend_index - 1] += score.sum
                trend = true
                trend_index = i
        else:
            if differences[i] < 0:
                up_count[i - trend_index - 1] += 1

                let score = collect(newSeq):
                        for d in data[trend_index..i - 1]:
                            d.close - data[trend_index].close

                up_score_sum[i - trend_index - 1] += score.sum
                trend = false
                trend_index = i
    
    var
        up_score_average = collect(newSeq):
            for i in 0..<up_count.len:
                if up_count[i] != 0:
                    int round up_score_sum[i] / up_count[i]
                else:
                    0
    
        down_score_average = collect(newSeq):
            for i in 0..<down_count.len:
                if down_count[i] != 0:
                    int round down_score_sum[i] / down_count[i]
                else:
                    0
        
        updown_average = collect(newSeq):
            for i in 0..<up_score_average.len:
                up_score_average[i] + down_score_average[i]

        up_percentage = collect(newSeq):
            for u in up_count:
                round(u / up_count.sum * 1000) / 10

        down_percentage = collect(newSeq):
            for d in down_count:
                round(d / down_count.sum * 1000) / 10
        
        up_probe = collect(newSeq):
            for i in 0..<count:
                if down_percentage[i] != 0:
                    round(down_percentage[i] / down_percentage[i..<count].sum * 1000) / 10
                else:
                    0


        d2b_count = newSeq[int](count)
        sim_score = newSeq[float](count)

    for d2b in 1..<d2b_count.len:
        var
            buy_flag = false
            diff = 0
            reserve = 0.0
            trend_index = 0
        
        sim_score[d2b - 1] = budget

        echo "*** down to buy count: ", d2b, " ***"
        for i in 1..<differences.len:
            if not trend:
                if differences[i] > 0:
                    trend = true
                    trend_index = i

                    if buy_flag == true:
                        d2b_count[d2b - 1] += int differences[i]
                        #echo "  up at ", i, "\tdiff: ", -(diff - d2b_count[d2b - 1])
                        #[ buy_flag = false
                        echo "sell at ", i, "\tdiff: ", -(diff - d2b_count[d2b - 1]), "\td2b: ", d2b_count[d2b - 1] ]#
                
                else:
                    if buy_flag == true:
                        d2b_count[d2b - 1] += int differences[i]
                        #echo "down at ", i, "\tdiff: ", -(diff - d2b_count[d2b - 1])

                    elif i - trend_index == d2b:
                        buy_flag = true
                        d2b_count[d2b - 1] -= int data[i + 1].close * spread
                        diff = d2b_count[d2b - 1]

                        if reserve == 0:
                            reserve = (sim_score[d2b - 1]) / (data[i + 1].close * (1 + spread)) # Buy Operation
                            sim_score[d2b - 1] -= reserve * (data[i + 1].close * (1 + spread))
                            echo " buy at ", i,
                                "\tdiff: ", diff - d2b_count[d2b - 1],
                                " \td2b: ", d2b_count[d2b - 1],
                                " \tsim_score: ", sim_score[d2b - 1],
                                "\tsell   diff: ", int(reserve * data[i + 1].close)

            else:
                if differences[i] < 0:
                    trend = false
                    trend_index = i
                
                else:
                    if i - trend_index == sell and buy_flag == true:
                        d2b_count[d2b - 1] += int differences[i]
                        buy_flag = false

                        if reserve != 0:
                            sim_score[d2b - 1] += reserve * data[i + 1].close # Sell Operation
                            echo "sell at ", i,
                                "\tdiff: ", -(diff - d2b_count[d2b - 1]),
                                "\td2b: ", d2b_count[d2b - 1],
                                " \tsim_score: ", sim_score[d2b - 1],
                                "\tsell amount: ", int(reserve * data[i + 1].close)
                            reserve = 0

                    elif buy_flag == true:
                        d2b_count[d2b - 1] += int differences[i]
                        #echo "  up at ", i, "\tdiff: ", -(diff - d2b_count[d2b - 1])
            
        if reserve != 0:
            sim_score[d2b - 1] += reserve * data[data.len - 1].close - budget
    
    for i in 0..<sim_score.len:
        sim_score[i] = (sim_score[i] - budget) / budget

    up_probe = up_probe
    let horizon = newSeqFromCount[float](count)
    echo " up : ", up_percentage
    echo "down: ", down_percentage
    echo "up probability: ", up_probe
    echo "  up score average: ", up_score_average, " sum: ",up_score_average.sum
    echo "down score average: ", down_score_average, " sum: ", down_score_average.sum
    echo "    updown average: ", updown_average
    echo " down to buy score: ", d2b_count
    echo "  simulation score: ", sim_score
    
    horizon.plotter("duration", "count",
        (up_percentage, "up (%)"),
        (down_percentage, "down (%)"),
        (up_probe, "up probability")
    )

    #[ var
        real_data = collect(newSeq):
            for c in data.close:
                c - data[0].close
        first_diff = data.close.difference
        second_diff = first_diff.difference
        third_diff = second_diff.difference
        horizon = newSeqFromCount[float](data.len)
    
    first_diff = newSeq[float](1) & first_diff
    second_diff = newSeq[float](2) & second_diff
    third_diff = newSeq[float](3) & third_diff
    
    echo "       data len: ", data.len
    echo " first diff len: ", first_diff.len
    echo "second diff len: ", second_diff.len
    echo " third diff len: ", third_diff.len
    
    horizon.plotter("time", "difference",
        (real_data, "real data"),
        (first_diff, "1st degree difference"),
        (second_diff, "2nd degree difference"),
        (third_diff, "3rd degree difference"),
    ) ]#

    stdout.write "press any key to continue..."
    discard stdin.readChar