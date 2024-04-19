# FeeRouter
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/a34b6cf942f7a9fc233bb23fb75c989ce5d0bfaf/src/fees/FeeRouter.sol)

**Inherits:**
Ownable

A [FeeRouter](/src/fees/FeeRouter.sol/contract.FeeRouter.md#feerouter) that uses 0xSplits to route collected fees to their respective destinations.

*This implementation relies on [0xSplits](https://github.com/0xSplits/splits-contracts-monorepo) to handle the distribution.*


## State Variables
### feeManager
The FeeManager contract.


```solidity
FeeManager public feeManager;
```


### splitFactory
The factory used to create fee splitters. See [0xSplits](https://github.com/0xSplits/splits-contracts-monorepo/tree/main/packages/splits-v2).


```solidity
PullSplitFactory public splitFactory;
```


### _route
The mapping of each (Edition, Token ID) to its registered Splits


```solidity
mapping(bytes32 => Route) public _route;
```


## Functions
### constructor

Initializes the FeeRouter with the given SplitFactory.


```solidity
constructor(address splitFactory_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`splitFactory_`|`address`|The address of the SplitFactory contract.|


### createRoute

Creates a new Split for the given {Edition} and token ID.


```solidity
function createRoute(NewRoutePayload calldata payload_) external onlyOwner returns (Route memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`payload_`|`NewRoutePayload`|The payload for creating the new route.|


### route

Routes a given fee to the appropriate destination.


```solidity
function route(FeeRouterPayload memory payload_) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`payload_`|`FeeRouterPayload`|The fee payload to be routed.|


### getRoute

Retrieves the Split for the given {Edition} and token ID.

*This function will revert if there is no registered Split for the given (Edition, Token ID).*


```solidity
function getRoute(IEdition edition_, uint256 tokenId) public view returns (Route memory route_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition_`|`IEdition`|The {Edition} for which to retrieve the Split.|
|`tokenId`|`uint256`|The token ID associated with the Split.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`route_`|`Route`|The route|


### _getRoute


```solidity
function _getRoute(IEdition edition_, uint256 tokenId) internal view returns (Route storage);
```

### _buildSharesAndTargets


```solidity
function _buildSharesAndTargets(
    Target memory creator,
    Target[] memory attributions,
    uint32 protocolRevshareBps,
    uint32 revshareBps
)
    internal
    view
    returns (address[] memory targets, uint256[] memory feeshares, uint256[] memory revshares);
```

### _getRevShares


```solidity
function _getRevShares(uint32 protocolBps, uint32 revshareBps, uint32 attributions)
    internal
    pure
    returns (uint32 creatorShare, uint32 protocolShare, uint32 attributionShare);
```

### _getFeeShares


```solidity
function _getFeeShares(uint32 attributions)
    internal
    pure
    returns (uint32 creatorShare, uint32 protocolShare, uint32 attributionShare);
```

### _payout


```solidity
function _payout(address split_, address asset_, uint256 amount_) internal;
```

## Events
### FeeRouted
Emitted when a fee is routed.


```solidity
event FeeRouted(Target indexed receiver, address asset, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`Target`|The address of the receiver of the fee.|
|`asset`|`address`|The address of the asset which was collected.|
|`amount`|`uint256`|The amount of the fee collected.|

### RouteCreated
Emitted when a new route is created.


```solidity
event RouteCreated(IEdition indexed edition, uint256 indexed tokenId, Route route, bytes data);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`edition`|`IEdition`|The edition for which the route was created.|
|`tokenId`|`uint256`|The token ID for which the route was created.|
|`route`|`Route`|The created route (feeReceiver, revshareReceiver).|
|`data`|`bytes`|Additional data associated with the route.|

## Errors
### NotRoutable
Throws if there is no available route for a given request.


```solidity
error NotRoutable();
```

## Structs
### FeeRouterPayload

```solidity
struct FeeRouterPayload {
    IEdition edition;
    uint256 tokenId;
    Fee fee;
}
```

### NewRoutePayload

```solidity
struct NewRoutePayload {
    IEdition edition;
    uint256 tokenId;
    Target creator;
    Target[] attributions;
}
```

