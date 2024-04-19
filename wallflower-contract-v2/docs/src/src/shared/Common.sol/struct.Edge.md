# Edge
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/190d4e66726023743d2d6974c49be143469e59b9/src/shared/Common.sol)

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

