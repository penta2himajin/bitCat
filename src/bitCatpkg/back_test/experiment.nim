import options, httpclient, times, json, os, tables, math, strutils, system


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


when isMainModule:
    echo 0.009668110000000001.trunc_str 8
    echo 3.14159265358979.trunc_str 8