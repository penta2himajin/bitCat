import strutils, strformat, math, sequtils, sugar, times, os, algorithm
import wrapper/types


func close*(data: seq[Chart]): seq[float] =
  collect(newSeq):
      for d in data:
        d.close

func diff_logarithmic*[T](data: openArray[T]): seq[float] =
  collect(newSeq):
    for i in 1..<data.len:
      ln(data[i] / data[i - 1])

func `==`[L](left: L, right: type): bool =
  left.type.name == right.type.name

func change_point*[T](data: openArray[T]): seq[int] =
  var ret: seq[int]
  for i in 1..<data.len:
    if (data[i - 1] < 0 and 0 < data[i]) or (0 < data[i - 1] and data[i] < 0):
      ret.add i
  
  ret

func filled*[T](a: var seq[T], value: T): seq[T] =
  a.fill(value)
  a

proc newSeqFromCount*[T](head: T, foot: T, diff: T = 1.T, precision: int = 0, visualize: bool = false): seq[T] =
  var ret = newSeq[T](int (max(head, foot) - min(head, foot)) / diff + 1)

  ret[0] = head.float.formatFloat(ffDecimal, precision).parseFloat.T
  for i in 1..<ret.len:
    ret[i] = (ret[i - 1] + diff).float.formatFloat(ffDecimal, precision).parseFloat.T
  
  ret.deduplicate

proc down_count_distribution*[T](data: openArray[T], precision: int = 10): (seq[int], seq[float]) =
  var
    count = 0
    ret = newSeq[float](15)

  for i in 1..<data.len:
    if data[i] - data[i - 1] > 0:
      if count != 0:
        ret[count - 1] += 1
        count = 0
    
    else:
      if count == 0:
        count = 1
      else:
        count += 1

  while ret[ret^1] == 0:
    ret.delete(ret^1, ret^1)
  
  let sum = ret.sum
  for i in 0..<ret.len:
    ret[i] = (ret[i] / sum).formatFloat(ffDecimal, precision).parseFloat
  
  (newSeqFromCount[int](1, ret.len), ret)

proc distribution*[T](data: var openArray[T], precision: int = 0, visualize: bool = false): (seq[T], seq[float]) =
  data.sort(system.cmp[float])

  let
    under = data[0].formatFloat(ffDecimal, precision).parseFloat
    top = data[data^1].formatFloat(ffDecimal, precision).parseFloat
    precision_digit = 1/10^precision

  var
    count = newSeqFromCount[T](under, top, precision_digit, precision)
    ret = newSeq[float](count.len)

  for d in data:
    ret[min(int (max(under, d + (1 / (2 * 10 ^ precision))) - min(under, d + (1 / (2 * 10 ^ precision)))) / precision_digit, ret^1)] += 1
  
  let sum = ret.sum
  for i in 0..<ret.len:
    ret[i] = (ret[i] / sum).formatFloat(ffDecimal, precision).parseFloat

  (count, ret)

proc expectation*[T](prob_dist: (openArray[T], openArray[T]), precision: int = 16): float =
  var ret: float
  for i in 0..<prob_dist[0].len:
    ret += prob_dist[0][i] * float prob_dist[1][i]

  (ret/prob_dist[1].sum.float).formatFloat(ffDecimal, precision).parseFloat

proc sleepTimer*(sleep: TimeInterval) =
  sleep(floor(((now() - now().second.seconds + sleep).toTime.toUnixFloat - getTime().toUnixFloat) * 1000).int)

func average*[T](data: openArray[T]): float =
  var ret: float
  for d in data:
    ret += float d
  
  ret / data.len.float

func variance*[T](data: openArray[T]): float =
  let average = data.average()
  var sigma: float

  for d in data:
    sigma += (d.float - average)^2

  sigma / float(data.len - 1)

func gaussian*(average: float, standard_deviation: float, x: float): float =
  let variance = standard_deviation ^ 2
  (1 / sqrt(2 * PI * variance) * exp(-((x - average)^2 / (2 * variance))))

func cdf*(mu: float, sigma: float, x: float): float =
  erfc(mu - x / (sqrt(2.0) * sigma)) / 2

func last_count*[T](data: openArray[T]): int =
  var ret = 1
  if 0 < data[data.len - 1]:
    while data.len - ret >= 0 and 0 < data[data.len - ret]:
      ret += 1
    
    return ret - 1

  else:
    while data.len - ret >= 0 and data[data.len - ret] < 0:
      ret += 1
    
    return ret - 1


func MA*[T](data: openArray[T], period: int): seq[T] =
  collect(newSeq):
      for i in 0..data.len - period:
        data[i..<i+period].sum / period.T

func TMA*[T](data: openArray[T], period: int): seq[T] =
  data.MA(period).MA(period)

func WMA*[T](data: openArray[T], period: int): seq[T] =
  collect(newSeq):
    for i in 0..data.len - period:
      let wma = collect(newSeq):
        for j in i..<i+period:
          data[j] * (j - i + 1).T
      wma.sum / toSeq(1..period).sum.T

func BWMA*[T](data: openArray[T], period: int): seq[T] =
  collect(newSeq):
    for i in 0..data.len - period:
      let wma = collect(newSeq):
        for j in i..<i+period:
          data[j] * (period - (j - i)).T
      wma.sum / toSeq(1..period).sum.T

func DWMA*[T](data: openArray[T], period: int, diff: int): seq[T] =
  let weight = (toSeq(1..period - diff) & toSeq(countdown(period - diff - 1, period - diff*2)))
  collect(newSeq):
    for i in 0..data.len - period:
      let wma = collect(newSeq):
        for j in i..<i+period:
          data[j] * weight[j - i].T
      wma.sum / weight.sum.T

func EMA*[T](data: openArray[T], period: int): seq[T] =
  var ret = newSeq[T](data.len - period + 1)
  for i in 0..data.len - period:
    if i == 0:
      ret[0] = data[i..<i + period].MA(period)[0]
    else:
      ret[i] = ret[i - 1] * (1 - (2/(period + 1))) + data[i + period - 1] * (2/(period + 1))
  
  ret

func MWMA*[T](data: openArray[T], period: int): seq[T] =
  const x = 1.05
  var
    ret = newSeq[T](data.len - period + 1)
    deno = 0.0
  for i in 0..data.len - period:
    if i == 0:
      for j in 0..<period:
        ret[i] += data[j] * float x^j
        deno += float x^j
      ret[i] /= deno
    else:
      ret[i] = ret[i - 1] / float(x^(period - 1)) + data[i + period - 1]

  ret

func MMA*[T](data: openArray[T], period: int): seq[T] =
  var ret = newSeq[T](data.len - period + 1)
  for i in 0..data.len - period:
    if i == 0:
      ret[i] = data[0..<period].MA(period)[0]
    else:
      ret[i] = ((period - 1).T * ret[i - 1] + data[i + period - 1]) / period.T
  
  ret

func EWMA*[T](data: openArray[T], period: int): seq[float] =
  collect(newSeq):
    for o in 0..data.len - period:
      var dsum: int
      for i, d in data[o..o+period-2]:
        dsum += d.int * 2^i

      (dsum + data[o+period-1].int * 2^(period - 1)) / (2^(period) - 1)


func Seasonal*[T](data: openArray[T], period: int): seq[T] =
  collect(newSeq):
    for i in 0..<data.len - period:
      data[i + period] - data[i]

func Autocorrelation*[T](data: openArray[T], period: int): float =
  let autocorr = collect(newSeq):
    for i in 0..data.len - (period + 1):
      data[i] * data[i + period]
  
  autocorr.average

func Spectra*[T](data: openArray[T], max: int): seq[float] =
  collect(newSeq):
    for i in 1..max:
      data.Autocorrelation(i).ln.T


func percent_K*(data: openArray[Chart], period: int): float =
  var
    min = data[data.len - 1].low
    max = data[data.len - 1].high

  for i in 2..period:
    min = min(min, data[data.len - i].low)
    max = max(max, data[data.len - i].high)

  (data[data.len - 1].close - min) / (max - min)


func LU_solve*[T](t: (seq[seq[T]], seq[T])): seq[float] =
  let
    (A, b) = t
    DIM = b.len
  var
    sum: float
    L, U = newSeq[seq[float]](DIM)
    x, y = newSeq[float](DIM)
  L.fill newSeq[float](DIM)
  U.fill newSeq[float](DIM)

  for i in 0..<DIM:
    L[i][i] = 1.0

  for i in 0..<DIM:
    for j in 0..<DIM:
      if i <= j:
        sum = 0.0

        for k in 0..<i:
          sum += L[i][k] * U[k][j]

        U[i][j] = A[i][j].float - sum

      elif i > j:
        sum = 0.0

        for k in 0..<j:
          sum += L[i][k] * U[k][j]

        L[i][j] = (A[i][j].float - sum) / U[j][j]

  for i in 0..<DIM:
    y[i] = float b[i]
  
  for j in 0..<DIM - 1:
    for i in j+1..<DIM:
      y[i] -= y[j].float * L[i][j]

  for i in 0..<DIM:
    x[i] = y[i]

  for j in countdown(DIM-1, 0):
    x[j] /= U[j][j]
    for i in 0..<j:
      x[i] -= U[i][j] * x[j].float

  x

func reg*[T](y: openArray[T], degree: int): (seq[seq[T]], seq[T]) =
  var
    x = toSeq(1..y.len)
    A = newSeq[seq[T]](degree + 1)
    b = newSeq[T](degree + 1)
  A.fill newSeq[T](degree + 1)
  
  for i in 0..degree:
    for k, x_i in x:
      b[i] += x_i.T^i * y[k]
    
    for j in 0..degree:
      for x_i in x:
        if (i + j) == 0:
          A[0][0] = float y.len
        else:
          A[i][j] += T x_i^(i + j)

  (A, b)

func coef_gen*[T](coef: openArray[T], length: int): seq[float] =
  let
    x = toSeq(1..length)
    ret = collect(newSeq):
      for i in 0..<length:
        var s: float
        for j, coef_j in coef:
          s += coef_j.float * x[i].float ^ j
        s

  ret