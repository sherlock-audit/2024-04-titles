# FeeManager
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/190d4e66726023743d2d6974c49be143469e59b9/src/fees/FeeManager.sol)

**Inherits:**
OwnableRoles

Manages fees for the Titles Protocol

*The FeeManager contract is responsible for collecting fees associated with protocol actions.*


## State Variables
### MAX_BPS
*The maximum basis points (BPS) value. Equivalent to 100%.*


```solidity
uint16 public constant MAX_BPS = 10_000;
```


### MAX_PROTOCOL_FEE_BPS
*The maximum protocol fee in basis points (BPS). Equivalent to 33.33%.*


```solidity
uint16 public constant MAX_PROTOCOL_FEE_BPS = 3333;
```


### MAX_PROTOCOL_FEE
*The maximum protocol fee in wei. Applies to both flat and percentage fees.*


```solidity
uint64 public constant MAX_PROTOCOL_FEE = 0.1 ether;
```


### MAX_ROYALTY_BPS
*The maximum royalty fee in basis points (BPS). Equivalent to 95%.*


```solidity
uint16 public constant MAX_ROYALTY_BPS = 9500;
```


### MIN_ROYALTY_BPS
*The minimum royalty fee in basis points (BPS). Equivalent to 2.5%.*


```solidity
uint16 public constant MIN_ROYALTY_BPS = 250;
```


### protocolCreationFee
The protocol creation fee. This fee is collected when a new {Edition} is created.


```solidity
uint128 public protocolCreationFee = 0.0001 ether;
```


### protocolFlatFee
The flat fee for the protocol. This fee is collected on all mint transactions.


```solidity
uint128 public protocolFlatFee = 0.0006 ether;
```


### protocolFeeshareBps
The protocol fee share in basis points (BPS). Only applies to protocol fees collected for unpriced mints.


```solidity
uint32 public protocolFeeshareBps = 3333;
```


### mintReferrerRevshareBps
The share of protocol fees to be distributed to the direct referrer of the mint, in basis points (BPS).


```solidity
uint16 public mintReferrerRevshareBps = 5000;
```


### collectionReferrerRevshareBps
The share of protocol fees to be distributed to the referrer of the collection, in basis points (BPS).


```solidity
uint16 public collectionReferrerRevshareBps = 2500;
```


### protocolFeeReceiver
The address of the protocol fee receiver.


```solidity
address public protocolFeeReceiver;
```


### splitFactory
The {SplitFactoryV2} contract used to create fee splits.


```solidity
SplitFactoryV2 public splitFactory;
```


### referrers
The mapping of referrers for each {Edition}'s creation.


```solidity
mapping(IEdition edition => address referrer) public referrers;
```


### _feeReceivers
The mapping of fee receivers by ID.


```solidity
mapping(bytes32 id => Target receiver) private _feeReceivers;
```


## Functions
### constructor

Initializes the [FeeManager](/src/fees/FeeManager.sol/contract.FeeManager.md#feemanager) contract.


```solidity
constructor(address admin_, address protocolFeeReceiver_, address splitFactory_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`admin_`|`address`||
|`protocolFeeReceiver_`|`address`|The address of the protocol fee receiver.|
|`splitFactory_`|`address`|The address of the {SplitFactoryV2} contract.|


### createRoute

Creates a new fee route for the given {Edition} and attributions.


```solidity
function createRoute(
    IEdition edition_,
    uint256 tokenId_,
    Target[] calldata attributions_,
    address referrer_
) external onlyOwnerOrRoles(ADMIN_ROLE) returns (Target memory receiver);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition_`|`IEdition`|The {Edition} for which to create the route.|
|`tokenId_`|`uint256`|The token ID associated with the route.|
|`attributions_`|`Target[]`|The attributions to be associated with the route.|
|`referrer_`|`address`|The address of the referrer to receive a share of the fee.|


### collectCreationFee

Collects the creation fee for a given {Edition}.


```solidity
function collectCreationFee(IEdition edition_, uint256 tokenId_, address feePayer_)
    external
    payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition_`|`IEdition`|The {Edition} for which to collect the creation fee.|
|`tokenId_`|`uint256`|The token ID associated with the fee.|
|`feePayer_`|`address`|The address of the account paying the fee.|


### collectMintFee

Collects the mint fee for a given {Edition}.


```solidity
function collectMintFee(
    IEdition edition_,
    uint256 tokenId_,
    uint256 amount_,
    address payer_,
    address referrer_
) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition_`|`IEdition`|The {Edition} for which to collect the mint fee.|
|`tokenId_`|`uint256`|The token ID associated with the fee.|
|`amount_`|`uint256`|The amount of the fee to collect.|
|`payer_`|`address`|The address of the account paying the fee.|
|`referrer_`|`address`|The address of the referrer to receive a share of the fee.|


### collectMintFee

Collects the mint fee for a given {Edition} and token ID, routing it as appropriate.


```solidity
function collectMintFee(
    IEdition edition,
    uint256 tokenId_,
    uint256 amount_,
    address payer_,
    address referrer_,
    Strategy calldata strategy_
) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition`|`IEdition`|The {Edition} for which the fee is being collected.|
|`tokenId_`|`uint256`|The token ID associated with the fee.|
|`amount_`|`uint256`|The amount of the fee to collect.|
|`payer_`|`address`|The address of the account paying the fee.|
|`referrer_`|`address`|The address of the referrer to receive a share of the fee.|
|`strategy_`|`Strategy`|The {Strategy} to use for computing the fee split.|


### feeReceiver

Gets the fee receiver for a given {Edition}.


```solidity
function feeReceiver(IEdition edition_, uint256 tokenId_) public view returns (Target memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition_`|`IEdition`|The {Edition} for which to get the fee receiver.|
|`tokenId_`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Target`|feeReceiver The {Target} to receive the fee.|


### getCreationFee

Calculates the fee for creating a new {Edition}.

*The creation fee is a flat fee collected by the protocol when a new {Edition} is created.*


```solidity
function getCreationFee() public view returns (Fee memory fee);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`Fee`|The {Fee} for creating a new {Edition}.|


### getMintFee

Calculates the mint fee for a given {Edition} based on its {Strategy}.

*The mint fee is calculated as the sum of:
- The mint fee specified by the creator in the {Strategy}.
- The protocol's base transaction fee (see {protocolFlatFee}).*


```solidity
function getMintFee(IEdition edition_, uint256 tokenId_, uint256 quantity_)
    public
    view
    returns (Fee memory fee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition_`|`IEdition`|The {Edition} for which to calculate the mint fee.|
|`tokenId_`|`uint256`||
|`quantity_`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`Fee`|The {Fee} for minting the {Edition}.|


### getMintFee

Calculates the mint fee for a given {Strategy} based on the quantity of tokens being minted.

*The mint fee is calculated as the sum of:
- The {Strategy.mintFee}.
- The {protocolFlatFee}.*


```solidity
function getMintFee(Strategy memory strategy_, uint256 quantity_)
    public
    view
    returns (Fee memory fee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy_`|`Strategy`|The {Strategy} for which to calculate the mint fee.|
|`quantity_`|`uint256`|The quantity of tokens being minted.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`Fee`|The {Fee} for minting the tokens.|


### getMintReferrerShare

Calculates the referrer share for a given amount.


```solidity
function getMintReferrerShare(uint256 protocolFee_, address referrer_)
    public
    view
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`protocolFee_`|`uint256`|The amount from which to calculate the referrer share.|
|`referrer_`|`address`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|referrerShare The mint referrer's share.|


### getCollectionReferrerShare

Calculates the collection referrer share for a given amount.


```solidity
function getCollectionReferrerShare(uint256 protocolFee_, address referrer_)
    public
    view
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`protocolFee_`|`uint256`|The amount from which to calculate the collection referrer share.|
|`referrer_`|`address`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|referrerShare The collection referrer's share.|


### getRouteId

Gets the route ID for a given {Edition} and token ID.


```solidity
function getRouteId(IEdition edition_, uint256 tokenId_) public pure returns (bytes32 id);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition_`|`IEdition`|The {Edition} for which to get the route ID.|
|`tokenId_`|`uint256`|The token ID for which to get the route ID.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|The route ID.|


### setProtocolFees

Updates the protocol fees which are collected for various actions.

*This function can only be called by the owner or an admin.*


```solidity
function setProtocolFees(
    uint64 protocolCreationFee_,
    uint64 protocolFlatFee_,
    uint16 protocolFeeShareBps_,
    uint16 mintReferrerRevshareBps_,
    uint16 collectionReferrerRevshareBps_
) external onlyOwnerOrRoles(ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`protocolCreationFee_`|`uint64`|The new protocol creation fee. This fee is collected when a new {Edition} is created. Cannot exceed {MAX_PROTOCOL_FEE}.|
|`protocolFlatFee_`|`uint64`|The new protocol flat fee. This fee is collected on all mint transactions. Cannot exceed {MAX_PROTOCOL_FEE}.|
|`protocolFeeShareBps_`|`uint16`|The new protocol fee share in basis points. Cannot exceed {MAX_PROTOCOL_FEE_BPS}.|
|`mintReferrerRevshareBps_`|`uint16`|The new mint referrer revenue share in basis points. This plus the collection referrer share cannot exceed {MAX_ROYALTY_BPS}.|
|`collectionReferrerRevshareBps_`|`uint16`|The new collection referrer revenue share in basis points. This plus the mint referrer share cannot exceed {MAX_ROYALTY_BPS}.|


### validateStrategy

Returns a validated {Strategy} based on the given data.


```solidity
function validateStrategy(Strategy calldata strategy_)
    external
    pure
    returns (Strategy memory strategy);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategy_`|`Strategy`|The {Strategy} to validate.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`strategy`|`Strategy`|The validated {Strategy}.|


### receive

Allows the contract to receive ETH.


```solidity
receive() external payable;
```

### withdraw

An escape hatch to transfer any trapped assets from the contract to the given address.

*This is meant to be used in cases where the contract is holding assets that it should not be. This function can only be called by an admin.*


```solidity
function withdraw(address asset_, uint256 amount_, address to_)
    external
    onlyRolesOrOwner(ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset_`|`address`|The address of the asset to withdraw.|
|`amount_`|`uint256`|The amount of the asset to withdraw.|
|`to_`|`address`|The address to send the asset to.|


### _collectMintFee

Collects the given {Fee} for a given {Edition} and token ID, routing it as appropriate.


```solidity
function _collectMintFee(
    IEdition edition_,
    uint256 tokenId_,
    uint256 amount_,
    address payer_,
    address referrer_,
    Fee memory fee_
) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition_`|`IEdition`|The {Edition} for which the fee is being collected.|
|`tokenId_`|`uint256`|The token ID associated with the fee.|
|`amount_`|`uint256`|The amount of tokens being minted.|
|`payer_`|`address`|The address of the account paying the fee.|
|`referrer_`|`address`|The address of the referrer to receive a share of the fee.|
|`fee_`|`Fee`|The {Fee} to collect.|


### _splitProtocolFee


```solidity
function _splitProtocolFee(
    IEdition edition_,
    address asset_,
    uint256 amount_,
    address payer_,
    address referrer_
) internal returns (uint256 referrerShare);
```

### _route

Routes the given {Fee} to the appropriate receiver.

*If the fee amount is zero, this function will return early. If the receiver is not on the same chain as the payer, this function will revert.*


```solidity
function _route(Fee memory fee_, Target memory feeReceiver_, address feePayer_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee_`|`Fee`|The {Fee} to route.|
|`feeReceiver_`|`Target`|The {Target} to receive the fee.|
|`feePayer_`|`address`|The address of the account paying the fee.|


### _transfer

Transfers the given amount of the given asset from the sender to the receiver.


```solidity
function _transfer(address asset_, uint256 amount_, address from_, address to_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset_`|`address`|The address of the asset to transfer.|
|`amount_`|`uint256`|The amount of the asset to transfer.|
|`from_`|`address`|The address of the account sending the asset.|
|`to_`|`address`|The address of the account receiving the asset.|


### _buildSharesAndTargets

Builds the targets and shares arrays for a given creator and attributions.

*Note that cross-chain payouts are not currently supported. Rather than reverting, this function assumes that the creator and attributions are on the same network.*


```solidity
function _buildSharesAndTargets(
    Target memory creator,
    Target[] memory attributions,
    uint32 revshareBps
) internal pure returns (address[] memory targets, uint256[] memory shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`creator`|`Target`|The creator of the work.|
|`attributions`|`Target[]`|The attributions for the work.|
|`revshareBps`|`uint32`|The revshare in basis points.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`targets`|`address[]`|The array of targets.|
|`shares`|`uint256[]`|The array of shares.|


## Events
### FeeCollected
Emitted when a fee is collected.


```solidity
event FeeCollected(
    address indexed edition, uint256 work, address asset, uint256 fee, uint256 referrerShare
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition`|`address`|The address of the edition for which the fee was collected.|
|`work`|`uint256`|The ID of the work for which the fee was collected.|
|`asset`|`address`|The address of the asset which was collected.|
|`fee`|`uint256`|The amount of the fee collected.|
|`referrerShare`|`uint256`|The portion of the collected fee which was paid to the referrer.|

### ProtocolFeesChanged
Emitted when the protocol fees are changed.


```solidity
event ProtocolFeesChanged(
    uint16 protocolFeeBps, uint128 protocolFlatFee, uint16 mintReferrerRevshareBps
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`protocolFeeBps`|`uint16`|The new protocol fee in basis points.|
|`protocolFlatFee`|`uint128`|The new protocol flat fee.|
|`mintReferrerRevshareBps`|`uint16`|The new partner revenue share in basis points.|

## Errors
### InvalidFee
Thrown when an invalid fee configuration is supplied.


```solidity
error InvalidFee();
```

### NotRoutable
Thrown when a fee cannot be routed.


```solidity
error NotRoutable();
```

## Structs
### StrategyPayload
The payload for creating a {Strategy}.


```solidity
struct StrategyPayload {
    address edition;
    uint256 tokenId;
    Strategy strategy;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`edition`|`address`|The address of the {Edition} to be associated with the {Strategy}.|
|`tokenId`|`uint256`|The ID of the token to be associated with the {Strategy}.|
|`strategy`|`Strategy`|The {Strategy} to be created.|

