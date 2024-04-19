# Metadata
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/190d4e66726023743d2d6974c49be143469e59b9/src/shared/Common.sol)

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

