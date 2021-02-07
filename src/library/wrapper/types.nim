import tables, sugar

export tables

type 
  Api* = tuple
    key: string
    secret: string

  Product* = tuple
    id: int
    symbol: string
    ask: float
    bid: float
    last_traded_price: float
    timestamp: int

  Chart* = tuple
    timestamp: int
    open: float
    high: float
    low: float
    close: float

  Order* = tuple
    price: float
    amount: float
  
  Board* = tuple
    timestamp: int
    bids: seq[Order]
    asks: seq[Order]
  
  Account* = Table[
    string,
    float
  ]


func closes*(self: seq[Chart]): seq[float] =
  collect(newSeq):
    for chart in self:
      chart.close