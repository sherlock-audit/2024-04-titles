# Node
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/3def97b53d8f2e1ca0a59e2027614383ba598af9/src/shared/Common.sol)

Node represents a node in the graph.

*The data field is used to store additional information about the node. The node's {EdgeManager} is responsible for interpreting this data.*


```solidity
struct Node {
    NodeType nodeType;
    Target entity;
    Target creator;
    bytes data;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`nodeType`|`NodeType`|The type of the node.|
|`entity`|`Target`|The on-chain entity represented by the node.|
|`creator`|`Target`|The creator of the work represented by the node.|
|`data`|`bytes`|The data associated with the node.|

