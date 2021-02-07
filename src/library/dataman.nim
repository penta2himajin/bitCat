import sugar, strutils

type Data = tuple
  timestamp: int
  ask: int
  pv: int
  bid: int

export Data


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

proc loadData*(filename: string): seq[Data] =
  var ret = newSeq[Data]()

  block:
    let file = open(filename, fmRead)
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
    let file = open(filename, fmAppend)
    defer:
      close(file)
    
    for i in 0..<self.len:
      file.writeLine $self[i].timestamp & ", " & $self[i].ask & ", " & $self[i].pv & ", " & $self[i].bid