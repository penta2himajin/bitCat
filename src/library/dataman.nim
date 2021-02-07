import sugar, strutils, os, times

type Data = tuple
  timestamp: int
  ask: int
  pv: int
  bid: int

export Data


#[ Tool ]#
func timestamps*(self: seq[Data]): seq[int] =
  collect(newSeq):
    for data in self:
      data.timestamp

func asks*(self: seq[Data]): seq[int] =
  collect(newSeq):
    for data in self:
      data.ask

func pvs*(self: seq[Data]): seq[int] =
  collect(newSeq):
    for data in self:
      data.pv

func bids*(self: seq[Data]): seq[int] =
  collect(newSeq):
    for data in self:
      data.bid

#[ Data ]#
proc loadData*(filename: string): seq[Data] =
  var ret = newSeq[Data]()

  block:
    let file = filename.open fmRead
    defer:
      close(file)
    
    discard file.readLine
    
    while not file.endOfFile:
      let line = collect(newSeq):
        for d in file.readLine.string.split(", "):
          d.parseInt

      ret.add Data((
        timestamp: line[0],
        ask: line[1],
        pv: line[2],
        bid: line[3]
      ))
  
  ret

proc storeData*(self: seq[Data], filename: string) =
  block:
    let file = filename.open fmAppend
    defer:
      close(file)
    
    for i in 0..<self.len:
      file.writeLine $self[i].timestamp & ", " & $self[i].ask & ", " & $self[i].pv & ", " & $self[i].bid

proc log*(str: string) =
  let path = "bitCat.log"
  if not fileExists path:
    block:
      let file = path.open fmReadWrite
      defer: close file
      
      file.writeLine "bitCat cryptcurrency full-auto trading system logging file"
      file.writeLine "This log file is created at " & now().format("yyyy-MM-dd HH:mm:ss")
      file.writeLine "--------------------------------------------------"

  else:
    block:
      let file = path.open fmAppend
      defer: close file

      file.writeLine str