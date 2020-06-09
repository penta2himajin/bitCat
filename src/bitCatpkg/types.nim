import tables

type
    # API types 
    api* = tuple
        key: string
        secret: string

    product* = tuple
        id: int
        symbol: string
        ask: float
        bid: float
        spread: float
        last_traded_price: float
        timestamp: int

    chart* = tuple
        timestamp: int
        open: float
        high: float
        low: float
        close: float
        hl: float
        hlc: float
        ohlc: float

    order* = tuple
        price: float
        amount: float
    
    board* = tuple
        timestamp: int
        bids: seq[order]
        asks: seq[order]
    
    account* = Table[
        string,
        float
    ]

    # Simulator types
    score* = tuple
        duration: int
        difference: int
        threshold: float
        buy: int
        sell: int
        price: float
        score: int