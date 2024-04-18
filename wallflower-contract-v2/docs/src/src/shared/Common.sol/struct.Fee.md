# Fee
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/3def97b53d8f2e1ca0a59e2027614383ba598af9/src/shared/Common.sol)

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

