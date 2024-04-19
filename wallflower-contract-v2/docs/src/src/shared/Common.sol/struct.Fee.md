# Fee
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/190d4e66726023743d2d6974c49be143469e59b9/src/shared/Common.sol)

Fee represents a fee for a given asset.


```solidity
struct Fee {
    address asset;
    uint256 amount;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The address of the asset.|
|`amount`|`uint256`|The total amount of the fee (in wei).|

