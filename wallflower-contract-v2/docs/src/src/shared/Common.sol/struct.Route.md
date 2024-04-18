# Route
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/3def97b53d8f2e1ca0a59e2027614383ba598af9/src/shared/Common.sol)

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

