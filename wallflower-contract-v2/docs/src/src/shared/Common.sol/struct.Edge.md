# Edge
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/3def97b53d8f2e1ca0a59e2027614383ba598af9/src/shared/Common.sol)

Edge represents the connection between two nodes in the graph.

*The data field is used to store additional information about the edge. The edge's {EdgeManager} is responsible for interpreting this data.*


```solidity
struct Edge {
    Node from;
    Node to;
    bool acknowledged;
    bytes data;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`from`|`Node`|The source node of the edge.|
|`to`|`Node`|The target node of the edge.|
|`acknowledged`|`bool`|Whether the edge has been acknowledged.|
|`data`|`bytes`|The data associated with the edge.|

