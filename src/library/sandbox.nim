type Wallet* = tuple
    fiat: float
    crypto: float

export Wallet


func order*(self: Wallet, side: string, price: float, quantity: float): Wallet =
  if side == "buy" and self.fiat - (price * quantity) >= 0:
    (
      fiat: self.fiat - (price * quantity),
      crypto: self.crypto + quantity
    )
  
  elif side == "sell" and self.crypto - quantity >= 0:
    (
      fiat: self.fiat + (price * quantity),
      crypto: self.crypto - quantity
    )
  
  else:
    self

func full_amount*(self: Wallet, crypto_price: float): float =
  self.fiat + (self.crypto * crypto_price)