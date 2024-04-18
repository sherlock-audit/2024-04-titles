# Metadata
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/3def97b53d8f2e1ca0a59e2027614383ba598af9/src/shared/Common.sol)

Metadata represents the metadata associated with an arbitrary entity.


```solidity
struct Metadata {
    string label;
    string uri;
    bytes data;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`label`|`string`|The label (or name) of the entity.|
|`uri`|`string`|The URI associated with the entity.|
|`data`|`bytes`|Additional data associated with the entity.|

