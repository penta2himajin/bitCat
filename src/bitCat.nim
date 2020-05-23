import bitCatpkg/library, bitCatpkg/types, bitCatpkg/wrapper/liquid, token


when isMainModule:
  api_token.tradeSimpleThresholdPolarReversal(getProduct, getChart, postOrder, getAccount, period_string="1min", threshold=57)

#[ 

Directory Tree

bitCat
  |- src
    |- bitCatpkg
      |- bitCat.nim         (as main project file)
      |- library.nim        (some trading function and any other useful functions)
      |- simulator.nim      (trading function's simulator)
      |- API                (exchange's API is here)
        |- liquid.nim       (Liquid by QUOINE API)
        |- huobi_japan.nim  (Huobi Japan API)
        etc...
      |- types.nim          (types using at main, library, simulator, APIs)
    |- tests
      |- bitCat.nimble      (basically, there are some test file eg: test.nim)

 ]#