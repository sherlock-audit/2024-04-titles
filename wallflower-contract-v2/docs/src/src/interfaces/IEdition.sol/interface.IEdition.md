# IEdition
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/190d4e66726023743d2d6974c49be143469e59b9/src/interfaces/IEdition.sol)

**Inherits:**
IERC165


## Functions
### publish

Publishes a new work within the edition on behalf of `creator` with the given configuration.


```solidity
function publish(
    address creator,
    uint256 maxSupply,
    uint64 opensAt,
    uint64 closesAt,
    Node[] calldata attributions,
    Strategy calldata strategy,
    Metadata calldata metadata
) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`creator`|`address`|The creator of the work.|
|`maxSupply`|`uint256`|The maximum supply of the work.|
|`opensAt`|`uint64`|The timestamp after which the work is mintable.|
|`closesAt`|`uint64`|The timestamp after which the work is no longer mintable.|
|`attributions`|`Node[]`|The attributions for the work.|
|`strategy`|`Strategy`|The fee strategy for the work.|
|`metadata`|`Metadata`|The metadata for the work.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The token ID of the work.|


### creator

Get the creator of the Edition. Alias for [owner](/src/interfaces/IEdition.sol/interface.IEdition.md#owner).


```solidity
function creator() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The creator of the Edition.|


### creator

Get the creator of the given work (token ID).


```solidity
function creator(uint256 tokenId) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID of the Edition.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The creator of the Edition.|


### mint

Mints `amount` of the given `tokenId` to the `to` address.


```solidity
function mint(address to, uint256 tokenId, uint256 amount, address referrer, bytes calldata data)
    external
    payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to mint the token to.|
|`tokenId`|`uint256`|The token ID to mint.|
|`amount`|`uint256`|The amount of tokens to mint.|
|`referrer`|`address`|The referrer of the mint.|
|`data`|`bytes`|Additional data to pass to the receiver.|


### feeStrategy

Get the fee strategy for the given token ID.


```solidity
function feeStrategy(uint256 tokenId) external view returns (Strategy memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID to get the fee strategy for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Strategy`|The fee strategy for the token ID.|


### maxSupply

Get the max supply for the given token ID.


```solidity
function maxSupply(uint256 tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID to get the max supply for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The max supply for the token ID.|


### name

Get the name of the Edition.


```solidity
function name() external view returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The name of the Edition.|


### node

Get the {Node} for the collection.


```solidity
function node() external view returns (Node memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Node`|The node for the edition.|


### node

Get the {Node} for the given work.


```solidity
function node(uint256 tokenId) external view returns (Node memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID of the work.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Node`|The node for the work.|


### owner

Get the owner of the Edition.


```solidity
function owner() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The owner of the Edition.|


### totalSupply

Get the total supply for the given token ID.


```solidity
function totalSupply(uint256 tokenId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID to get the total supply for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The total supply for the token ID.|


### uri

Get the URI for the given token ID


```solidity
function uri(uint256 tokenId) external view returns (string memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID to get the URI for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The URI for the token ID.|


### supportsInterface

Determine if the contract supports the given interface.


```solidity
function supportsInterface(bytes4 interfaceId) external view override returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interfaceId`|`bytes4`|The interface ID to check for support.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the contract supports the interface, false otherwise.|


