# Route
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/190d4e66726023743d2d6974c49be143469e59b9/src/shared/Common.sol)

The route for a given (Edition, Token ID).


```solidity
struct Route {
    address feeReceiver;
    address revshareReceiver;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`feeReceiver`|`address`|The address of the fee receiver.|
|`revshareReceiver`|`address`|The address of the revshare receiver.|

