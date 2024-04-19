# IOpenGraph
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/190d4e66726023743d2d6974c49be143469e59b9/src/interfaces/IOpenGraph.sol)

Interface for OpenGraph standard

*The OpenGraph standard defines the interface and events related to creating {Node}s and {Edge}s in the graph, but it has no opinion on how or whether the data should be stored on-chain.*


## Functions
### createEdge

Creates an {Edge} with the given data.


```solidity
function createEdge(Node memory from_, Node memory to_, bytes calldata data_)
    external
    returns (Edge memory edge);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from_`|`Node`|The {Node} from which the relationship originates|
|`to_`|`Node`|The {Node} to which the relationship points|
|`data_`|`bytes`|The serialized data payload for the {Edge} `(Node, Node, bytes)`|


## Events
### NodeTouched
Emitted when a {Node} is touched.


```solidity
event NodeTouched(Node node, bytes data);
```

### EdgeCreated
Emitted when an {Edge} is created.


```solidity
event EdgeCreated(Edge edge, bytes data);
```

