import gnuplot, sugar, strutils, sequtils, strformat
import ../types, ../library, ../wrapper/liquid


proc plotter*[T](horizontal_axis: seq[T], x_label: string = "", y_label:string = "", args: varargs[(seq[T], string)]) =
    if x_label != "": cmd &"set xlabel '{x_label}'"
    if x_label != "": cmd &"set ylabel '{y_label}'"
    cmd "set grid"

    for (arg, title) in args:
        if horizontal_axis.len != arg.len:
            var e: ref RangeError
            new e
            e.msg = "horizontal_axis length not equal to arg length: " & $horizontal_axis.len & " == " & $arg.len
            raise e
        
        plot horizontal_axis, arg, title


when isMainModule:
    stdout.write "symbol: "
    let symbol = stdin.readLine

    stdout.write "period: "
    let period: string = stdin.readLine

    stdout.write "data size: "
    let size = stdin.readLine.parseInt - 1

    let
        data = getChart(symbol, period, size)
        close = collect(newSeq):
            for chart in data:
                chart.close
        close_from_zero = collect(newSeq):
            for c in close:
                c - close[0]
        differences = newSeq[float](data.len - data.getDifference.len).concat data.getDifference
        h_axis = collect(newSeq):
            for i in countup(1, data.len): i.float
    echo "data diff len: ", data.getDifference.len
    h_axis.plotter("price diffrence", "time series (minute)", (close_from_zero, "close"), (differences, "difference"))

    echo "press any key to continue..."
    discard stdin.readChar