# Strategy
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/190d4e66726023743d2d6974c49be143469e59b9/src/shared/Common.sol)

Strategy represents a fee strategy.

*The royalty revshare is a percentage of the collected mint fee that is paid to attributed creators. It is expressed in basis points (1/100th of a percent). For example, a 100 bps (1%) royalty fee on a 1 ETH mint fee would result in a 0.01 ETH royalty fee.*


```solidity
struct Strategy {
    address asset;
    uint112 mintFee;
    uint16 revshareBps;
    uint16 royaltyBps;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset to be used for fees.|
|`mintFee`|`uint112`|The fee for minting an asset (in wei).|
|`revshareBps`|`uint16`|The royalty revshare (in basis points).|
|`royaltyBps`|`uint16`|The ERC2981 secondary sales royalty fee (in basis points).|

