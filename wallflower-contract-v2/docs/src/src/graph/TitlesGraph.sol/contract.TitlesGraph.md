# TitlesGraph
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/190d4e66726023743d2d6974c49be143469e59b9/src/graph/TitlesGraph.sol)

**Inherits:**
[IOpenGraph](/src/interfaces/IOpenGraph.sol/interface.IOpenGraph.md), [IEdgeManager](/src/interfaces/IEdgeManager.sol/interface.IEdgeManager.md), OwnableRoles, EIP712, UUPSUpgradeable

Titles.xyz implementation of the OpenGraph standard

*The TitlesGraph contract implements the OpenGraph standard and is responsible for managing the creation and acknowledgment of {Node}s and {Edge}s in the graph.*


## State Variables
### _edgeIds
The set of edge IDs in the graph. Enumerable to enable on-chain graph traversal in the future.


```solidity
EnumerableSet.Bytes32Set private _edgeIds;
```


### edges
Edges are relationships between two nodes in the graph.


```solidity
mapping(bytes32 id => Edge edge) public edges;
```


### _isUsed
An internal mapping to prevent signature reuse.


```solidity
mapping(bytes32 signature => bool used) private _isUsed;
```


### ACK_TYPEHASH

```solidity
bytes32 public constant ACK_TYPEHASH = keccak256("Ack(bytes32 edgeId,bytes data)");
```


### DOMAIN_TYPEHASH

```solidity
bytes32 public constant DOMAIN_TYPEHASH = _DOMAIN_TYPEHASH;
```


## Functions
### checkSignature

Modified to check the signature for a proxied acknowledgment.


```solidity
modifier checkSignature(bytes32 edgeId, bytes calldata data, bytes calldata signature);
```

### constructor


```solidity
constructor(address owner_, address admin_);
```

### createEdge

Create a new {Edge} between two {Node}s in the graph.

*This function is used to create a new edge between two nodes in the graph and will revert if not unique or if called by any address other than the contract referenced as the `from` node. A {NodeTouched} event is emitted for each node and an {EdgeCreated} event is emitted for the edge itself.*


```solidity
function createEdge(Node calldata from_, Node calldata to_, bytes calldata data_)
    external
    override
    returns (Edge memory edge);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from_`|`Node`|The {Node} from which the edge originates.|
|`to_`|`Node`|The {Node} to which the edge points.|
|`data_`|`bytes`|Metadata associated with the edge.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`edge`|`Edge`|The created edge.|


### createEdges

Create multiple edges within the graph.

*This function is used to create multiple edges within the graph and will revert if any of the edges are not unique. It emits a {NodeTouched} event for each node and an {EdgeCreated} event for each edge.*


```solidity
function createEdges(Edge[] calldata edges_) external onlyRolesOrOwner(ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edges_`|`Edge[]`|The edges to create.|


### _createEdge


```solidity
function _createEdge(Node memory from_, Node memory to_, bytes memory data_)
    internal
    returns (Edge memory edge);
```

### acknowledgeEdge

Acknowledge an edge.

*This function is used to acknowledge an edge that was previously created and will revert if the edge does not exist. It emits an {EdgeAcknowledged} event for the edge.*


```solidity
function acknowledgeEdge(bytes32 edgeId_, bytes calldata data_)
    external
    override
    returns (Edge memory edge);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edgeId_`|`bytes32`|The ID of the edge to acknowledge.|
|`data_`|`bytes`|Additional data to include with the acknowledgment.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`edge`|`Edge`|The acknowledged edge.|


### acknowledgeEdge

Acknowledge an edge using an ECDSA signature.

*The request is valid if the given signature was produced using the edge ID as the message and the creator of the `to` node as the signer.*

*This function is used to acknowledge an edge that was previously created and will revert if the edge does not exist or if the signature is invalid. It emits an {EdgeAcknowledged} event for the edge.*


```solidity
function acknowledgeEdge(bytes32 edgeId_, bytes calldata data_, bytes calldata signature_)
    external
    checkSignature(edgeId_, data_, signature_)
    returns (Edge memory edge);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edgeId_`|`bytes32`|The ID of the edge to acknowledge.|
|`data_`|`bytes`|Additional data to include with the acknowledgment.|
|`signature_`|`bytes`|The ECDSA signature to verify.|


### unacknowledgeEdge

Unacknowledge an edge.

*This function is used to unacknowledge an edge that was previously acknowledged.*


```solidity
function unacknowledgeEdge(bytes32 edgeId_, bytes calldata data_)
    external
    override
    returns (Edge memory edge);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edgeId_`|`bytes32`|The ID of the edge to unacknowledge.|
|`data_`|`bytes`|Additional data to include with the unacknowledgment.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`edge`|`Edge`|The unacknowledged {Edge}.|


### unacknowledgeEdge

Unacknowledge an edge using an ECDSA signature.

*The request is valid if the given signature was produced using the edge ID as the message and the creator of the `to` node as the signer.*

*This function is used to unacknowledge an edge that was previously acknowledged and will revert if the edge does not exist or if the signature is invalid. It emits an {EdgeUnacknowledged} event for the edge.*


```solidity
function unacknowledgeEdge(bytes32 edgeId_, bytes calldata data_, bytes calldata signature_)
    external
    checkSignature(edgeId_, data_, signature_)
    returns (Edge memory edge);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edgeId_`|`bytes32`|The ID of the edge to unacknowledge.|
|`data_`|`bytes`|Additional data to include with the unacknowledgment.|
|`signature_`|`bytes`|The ECDSA signature to verify.|


### grantRoles

Override the {OwnableRoles} implementation to extend access to the `ADMIN_ROLE`.

*This function is used to grant roles to an address and will revert if the caller is not the owner and does not have the `ADMIN_ROLE`.*


```solidity
function grantRoles(address guy, uint256 roles)
    public
    payable
    override
    onlyOwnerOrRoles(ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`guy`|`address`|The address to grant the roles.|
|`roles`|`uint256`|The roles to grant.|


### revokeRoles

Override the {OwnableRoles} implementation to extend access to the `ADMIN_ROLE`.

*This function is used to revoke roles from an address and will revert if the caller is not the owner and does not have the `ADMIN_ROLE`.*


```solidity
function revokeRoles(address guy, uint256 roles)
    public
    payable
    override
    onlyOwnerOrRoles(ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`guy`|`address`|The address from which to revoke the roles.|
|`roles`|`uint256`|The roles to revoke.|


### getEdgeId

Get the ID of an edge given the source and target nodes.


```solidity
function getEdgeId(Node memory from_, Node memory to_) public pure returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from_`|`Node`|The source node of the edge.|
|`to_`|`Node`|The target node of the edge.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|edgeId The ID of the edge (i.e. the keccak256 hash of the `from` and `to` nodes).|


### getEdgeId

Get the ID of an edge.


```solidity
function getEdgeId(Edge memory edge_) public pure returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edge_`|`Edge`|The edge for which to get the ID.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|edgeId The ID of the edge (i.e. the keccak256 hash of the `from` and `to` nodes).|


### _setAcknowledged

Set the acknowledged status of an edge.


```solidity
function _setAcknowledged(bytes32 edgeId_, bytes calldata data_, bool acknowledged_)
    internal
    returns (Edge memory edge);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edgeId_`|`bytes32`|The ID of the edge to set the acknowledged status for.|
|`data_`|`bytes`|Additional data to include with the acknowledgment.|
|`acknowledged_`|`bool`|The new acknowledged status of the edge.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`edge`|`Edge`|The edge with the updated acknowledged status.|


### _authorizeUpgrade

Allows the admin to upgrade the contract.

*This function overrides the {UUPSUpgradeable} implementation to restrict upgrade rights to the graph owner.*


```solidity
function _authorizeUpgrade(address) internal view override onlyOwnerOrRoles(ADMIN_ROLE);
```

### _domainNameAndVersion

Returns the domain name and version for EIP-712.


```solidity
function _domainNameAndVersion()
    internal
    pure
    override
    returns (string memory name, string memory version);
```

### _isCreator

Checks if the given address is the creator of a node.


```solidity
function _isCreator(Node memory node, address guy) internal pure returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`node`|`Node`|The node to check.|
|`guy`|`address`|The address to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the address is the creator of the node, false otherwise.|


### _isEntity

Checks if the given address is the on-chain entity represented by a node.


```solidity
function _isEntity(Node memory node, address guy) internal pure returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`node`|`Node`|The node to check.|
|`guy`|`address`|The address to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the address is the entity of the node, false otherwise.|


### _isCreatorOrEntity

Checks if the given address is either the creator or on-chain entity represented by a node.


```solidity
function _isCreatorOrEntity(Node memory node, address guy) internal pure returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`node`|`Node`|The node to check.|
|`guy`|`address`|The address to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the address is the creator or entity of the node, false otherwise.|


## Errors
### Exists

```solidity
error Exists();
```

### NotFound

```solidity
error NotFound();
```

