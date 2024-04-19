# TitlesCore
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/190d4e66726023743d2d6974c49be143469e59b9/src/TitlesCore.sol)

**Inherits:**
OwnableRoles, Initializable, UUPSUpgradeable, Receiver

Core contract for the Titles Protocol


## State Variables
### editionImplementation

```solidity
address public editionImplementation = address(new Edition());
```


### feeManager

```solidity
FeeManager public feeManager;
```


### graph

```solidity
TitlesGraph public graph;
```


## Functions
### initialize

Initializes the protocol.


```solidity
function initialize(address feeReceiver_, address splitFactory_) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeReceiver_`|`address`|The address to receive fees.|
|`splitFactory_`|`address`|The address of the split factory.|


### createEdition

Creates an {Edition} with the given payload.


```solidity
function createEdition(bytes calldata payload_, address referrer_)
    external
    payable
    returns (Edition edition);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`payload_`|`bytes`|The compressed payload for creating the {Edition}. See {EditionPayload}.|
|`referrer_`|`address`|The address of the referrer.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`edition`|`Edition`|The new {Edition}.|


### publish

Publishes a new Work in the given {Edition} using the given payload.


```solidity
function publish(Edition edition_, bytes calldata payload_, address referrer_)
    external
    payable
    returns (uint256 tokenId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition_`|`Edition`|The {Edition} to publish the Work in.|
|`payload_`|`bytes`|The compressed payload for publishing the Work. See [WorkPayload](/src/TitlesCore.sol/contract.TitlesCore.md#workpayload).|
|`referrer_`|`address`|The address of the referrer.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID of the new Work.|


### _publish

Publishes a new Work in the given {Edition} using the given payload.


```solidity
function _publish(Edition edition_, WorkPayload memory work_, address referrer_)
    internal
    returns (uint256 tokenId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition_`|`Edition`|The {Edition} to publish the Work in.|
|`work_`|`WorkPayload`|The payload for publishing the Work. See [EditionPayload](/src/TitlesCore.sol/contract.TitlesCore.md#editionpayload).|
|`referrer_`|`address`|The address of the referrer.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID of the new Work.|


### setEditionImplementation

Sets the implementation address to be cloned for each new {Edition}.

*Only the owner can call this function.*


```solidity
function setEditionImplementation(address implementation_) external onlyOwnerOrRoles(ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`implementation_`|`address`|The new implementation address.|


### _authorizeUpgrade

*This function is overridden to restrict access to the owner/admin. No other logic required.*


```solidity
function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwnerOrRoles(ADMIN_ROLE);
```

### _attributionTargets

Returns the targets of the given attributions.


```solidity
function _attributionTargets(Node[] memory attributions_)
    internal
    pure
    returns (Target[] memory targets);
```

## Structs
### WorkPayload
The payload for creating a Work within an {Edition}.


```solidity
struct WorkPayload {
    Target creator;
    Node[] attributions;
    uint256 maxSupply;
    uint64 opensAt;
    uint64 closesAt;
    Strategy strategy;
    Metadata metadata;
}
```

### EditionPayload
The payload for creating an {Edition}.


```solidity
struct EditionPayload {
    WorkPayload work;
    Metadata metadata;
}
```

