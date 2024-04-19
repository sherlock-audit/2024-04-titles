# IEdgeManager
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/190d4e66726023743d2d6974c49be143469e59b9/src/interfaces/IEdgeManager.sol)

Interface for EdgeManager

*An EdgeManager is responsible for managing the relationship between {Node}s (i.e. {Edge}s) in the graph.*


## Functions
### acknowledgeEdge

Acknowledges an {Edge} with the given data.


```solidity
function acknowledgeEdge(bytes32 edgeId_, bytes calldata data_)
    external
    returns (Edge memory edge);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edgeId_`|`bytes32`|The ID of the {Edge} to acknowledge.|
|`data_`|`bytes`|The data associated with the acknowledgment.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`edge`|`Edge`|The acknowledged {Edge}.|


### unacknowledgeEdge

Unacknowledges an {Edge} with the given data.


```solidity
function unacknowledgeEdge(bytes32 edgeId_, bytes calldata data_)
    external
    returns (Edge memory edge);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edgeId_`|`bytes32`|The ID of the {Edge} to unacknowledge.|
|`data_`|`bytes`|The data associated with the unacknowledgment.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`edge`|`Edge`|The unacknowledged {Edge}.|


## Events
### EdgeAcknowledged
Emitted when an {Edge} is acknowledged.


```solidity
event EdgeAcknowledged(Edge edge, address acknowledger, bytes data);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edge`|`Edge`|The acknowledged {Edge}.|
|`acknowledger`|`address`|The address of the acknowledger.|
|`data`|`bytes`|The data associated with the acknowledgment.|

### EdgeUnacknowledged
Emitted when an {Edge} is unacknowledged.


```solidity
event EdgeUnacknowledged(Edge edge, address acknowledger, bytes data);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edge`|`Edge`|The unacknowledged {Edge}.|
|`acknowledger`|`address`|The address of the acknowledger.|
|`data`|`bytes`|The data associated with the unacknowledgment.|

