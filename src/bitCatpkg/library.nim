import httpclient, times, json, sugar, math, os, tables, gnuplot, strformat, strutils
import types
from sequtils import zip



#[ type method ]#
proc close*(chart: seq[chart]): seq[float] =
    collect(newSeq):
        for data in chart:
            data.close

#[ Library functions ]#
func sum*[T](a: seq[T]): T =
    var sum: T
    for i in a:
        sum += i
    sum

func average*[T](a: seq[T]): T =
    T a.sum / float a.len

func truncate*(num: float, digit: int): float =
    int(num * 10.0 ^ digit) / int(10.0 ^ digit)

func getDifference*(data: seq[chart]): seq[float] =
    collect(newSeq):
        for (old, now) in zip(data[0 .. data.len - 2], data[1 .. data.len - 1]):
            now.close - old.close

func getMovingAverage*(data: seq[chart], duration: int): seq[float] =
    collect(newSeq):
        for index in 0..data.len - duration:
            let c = collect(newSeq):
                for d in data[index..index + duration - 1]:
                    d.close
            c.average

proc sleepTimer*(unixfloatnow: float, time: int) =
    sleep(floor((unixfloatnow + time.float - now().toTime.toUnixFloat) * 1000).int)

proc plotter*[T](horizontal_axis: seq[T], x_label: string = "", y_label:string = "", args: varargs[(seq[T], string)]) =
    if x_label != "": cmd &"set xlabel '{x_label}' tc rgb \"white\""
    if x_label != "": cmd &"set ylabel '{y_label}' tc rgb \"white\""
    cmd "set object 1 rect behind from screen 0,0 to screen 1,1 fc rgb \"#333631\" fillstyle solid 1.0"
    cmd "set border lc rgb \"white\""
    cmd "set key tc rgb \"white\""
    cmd "set grid"

    for (arg, title) in args:
        if horizontal_axis.len != arg.len:
            var e: ref RangeError
            new e
            e.msg = "horizontal_axis length not equal to arg length: " & $horizontal_axis.len & " == " & $arg.len
            raise e
        
        plot horizontal_axis, arg, title

proc newSeqFromCount*[T](length: int): seq[T] =
    collect(newSeq):
        for i in countup(1, length): i.T

proc `*`*(left: string, right: int): string =
    var ret: string
    for i in 1..right:
        ret.add left
    
    ret

proc trunc_str*(num: float, digit: int): string =
    var
        num_str = int(num * 10.0 ^ digit).intToStr
        num = if num_str.len - digit > 0:
                num_str.insert(".", num_str.len - digit)
                num_str
            else:
                "0." & "0" * (digit - num_str.len) & num_str

    num