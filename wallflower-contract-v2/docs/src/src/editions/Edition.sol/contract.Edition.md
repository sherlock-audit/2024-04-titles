# Edition
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/190d4e66726023743d2d6974c49be143469e59b9/src/editions/Edition.sol)

**Inherits:**
[IEdition](/src/interfaces/IEdition.sol/interface.IEdition.md), ERC1155, ERC2981, Initializable, OwnableRoles

An ERC1155 contract representing a collection of related works. Each work is represented by a token ID.


## State Variables
### totalWorks
The total number of works in the Edition. Also the ID of the latest work.


```solidity
uint256 public totalWorks;
```


### works
The collection of works in the Edition.


```solidity
mapping(uint256 => Work) public works;
```


### _metadata
The metadata for the Edition and its works.

*The Edition key is 0, while the work keys are the token IDs.*


```solidity
mapping(uint256 => Metadata) public _metadata;
```


### FEE_MANAGER
The fee manager contract.


```solidity
FeeManager public FEE_MANAGER;
```


### GRAPH
The TitlesGraph contract.


```solidity
TitlesGraph public GRAPH;
```


## Functions
### initialize

Initialize the Edition contract.

*This function is called by the {EditionFactory} when creating a new Edition to set the fee manager and owner.*

*The controller is granted the {EDITION_MANAGER_ROLE} to allow management of the Edition contract.*


```solidity
function initialize(
    FeeManager feeManager_,
    TitlesGraph graph_,
    address owner_,
    address controller_,
    Metadata calldata metadata_
) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeManager_`|`FeeManager`|The fee manager contract.|
|`graph_`|`TitlesGraph`|The TitlesGraph contract.|
|`owner_`|`address`|The owner of the Edition contract.|
|`controller_`|`address`|The controller of the Edition contract.|
|`metadata_`|`Metadata`||


### publish

Create a new work in the Edition.


```solidity
function publish(
    address creator_,
    uint256 maxSupply_,
    uint64 opensAt_,
    uint64 closesAt_,
    Node[] calldata attributions_,
    Strategy calldata strategy_,
    Metadata calldata metadata_
) external override onlyRoles(EDITION_MANAGER_ROLE) returns (uint256 tokenId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`creator_`|`address`|The creator of the work.|
|`maxSupply_`|`uint256`|The maximum number of mintable tokens for the work.|
|`opensAt_`|`uint64`|The timestamp after which the work is mintable.|
|`closesAt_`|`uint64`|The timestamp after which the work is no longer mintable.|
|`attributions_`|`Node[]`|The attributions for the work.|
|`strategy_`|`Strategy`|The fee strategy for the work.|
|`metadata_`|`Metadata`|The metadata for the work.|


### name

Get the name of the Edition.


```solidity
function name() public view override returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The name of the Edition.|


### name

Get the name for a given Work.


```solidity
function name(uint256 tokenId) public view returns (string memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The ID of the work.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The name of the work.|


### owner

Get the owner of the Edition.

*The owner of the Edition contract has the right to manage roles.*


```solidity
function owner() public view override(IEdition, Ownable) returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The owner of the Edition.|


### uri


```solidity
function uri() public view returns (string memory);
```

### uri

Get the URI for the given token ID.


```solidity
function uri(uint256 tokenId_)
    public
    view
    virtual
    override(IEdition, ERC1155)
    returns (string memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId_`|`uint256`|The ID of the token.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The URI for the token.|


### creator

Get the creator of the Edition. Alias for [owner](/src/editions/Edition.sol/contract.Edition.md#owner).


```solidity
function creator() public view override returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The creator of the Edition.|


### creator

Get the creator of the given work.


```solidity
function creator(uint256 tokenId) public view override returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The ID of the work.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The creator of the work.|


### node

Get the {Node} for the collection.


```solidity
function node() public view returns (Node memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Node`|The node for the edition.|


### node

Get the {Node} for the given work.


```solidity
function node(uint256 tokenId) public view returns (Node memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The token ID of the work.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Node`|The node for the work.|


### mintFee

Get the mint fee for one token for the given work.


```solidity
function mintFee(uint256 tokenId_) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId_`|`uint256`|The ID of the work.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The mint fee for the token.|


### mintFee

Get the mint fee for an `amount` of tokens for the given work.


```solidity
function mintFee(uint256 tokenId_, uint256 amount_) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId_`|`uint256`|The ID of the work.|
|`amount_`|`uint256`|The amount of tokens to mint.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The mint fee for the tokens.|


### mint

Mint a new token for the given work.


```solidity
function mint(
    address to_,
    uint256 tokenId_,
    uint256 amount_,
    address referrer_,
    bytes calldata data_
) external payable override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to_`|`address`|The address to mint the token to.|
|`tokenId_`|`uint256`|The ID of the work to mint.|
|`amount_`|`uint256`|The amount of tokens to mint.|
|`referrer_`|`address`|The address of the referrer.|
|`data_`|`bytes`|The data associated with the mint. Reserved for future use.|


### mintWithComment

Mint a new token for the given work with a public comment.

*This function is used to mint a token with a public comment, allowing the mint to be associated with a message which will be emitted as an event.*


```solidity
function mintWithComment(
    address to_,
    uint256 tokenId_,
    uint256 amount_,
    address referrer_,
    bytes calldata data_,
    string calldata comment_
) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to_`|`address`|The address to mint the token to.|
|`tokenId_`|`uint256`|The ID of the work to mint.|
|`amount_`|`uint256`|The amount of tokens to mint.|
|`referrer_`|`address`|The address of the referrer.|
|`data_`|`bytes`|The data associated with the mint. Reserved for future use.|
|`comment_`|`string`|The public comment associated with the mint. Emitted as an event.|


### mintBatch

Mint multiple tokens for the given works.


```solidity
function mintBatch(
    address to_,
    uint256[] calldata tokenIds_,
    uint256[] calldata amounts_,
    bytes calldata data_
) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to_`|`address`|The address to mint the tokens to.|
|`tokenIds_`|`uint256[]`|The IDs of the works to mint.|
|`amounts_`|`uint256[]`|The amounts of each work to mint.|
|`data_`|`bytes`|The data associated with the mint. Reserved for future use.|


### mintBatch

Mint a token to a set of receivers for the given work.


```solidity
function mintBatch(
    address[] calldata receivers_,
    uint256 tokenId_,
    uint256 amount_,
    bytes calldata data_
) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receivers_`|`address[]`|The addresses to mint the tokens to.|
|`tokenId_`|`uint256`|The ID of the work to mint.|
|`amount_`|`uint256`|The amount of tokens to mint.|
|`data_`|`bytes`|The data associated with the mint. Reserved for future use.|


### promoMint

Mint a token from the given work to a set of receivers.

*This function is used to mint one token for each receiver of a given work, bypassing mint fees. It is intended for promotional purposes.*


```solidity
function promoMint(address[] calldata receivers_, uint256 tokenId_, bytes calldata data_)
    external
    onlyOwnerOrRoles(EDITION_MANAGER_ROLE | EDITION_MINTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receivers_`|`address[]`|The addresses to mint the tokens to.|
|`tokenId_`|`uint256`|The ID of the work to mint.|
|`data_`|`bytes`|The data associated with the mint. Reserved for future use.|


### metadata

Get the metadata for the given ID.


```solidity
function metadata(uint256 id_) external view returns (Metadata memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id_`|`uint256`|The ID of the work, or `0` for the Edition.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Metadata`|The metadata for the ID.|


### maxSupply

Get the maximum supply for the given work.


```solidity
function maxSupply(uint256 tokenId_) external view override returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId_`|`uint256`|The ID of the work.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The maximum supply for the work.|


### totalSupply

Get the total supply for the given work.


```solidity
function totalSupply(uint256 tokenId_) external view override returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId_`|`uint256`|The ID of the work.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The total supply for the work.|


### feeStrategy

Get the fee strategy for the given work.


```solidity
function feeStrategy(uint256 tokenId_) external view override returns (Strategy memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId_`|`uint256`|The ID of the work.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Strategy`|The fee strategy for the work.|


### setFeeStrategy

Set the fee strategy for the given work.

*This function only updates the strategy locally and will NOT change the fee route.*


```solidity
function setFeeStrategy(uint256 tokenId_, Strategy calldata strategy_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId_`|`uint256`|The ID of the work.|
|`strategy_`|`Strategy`|The fee strategy for the work.|


### setMetadata

Set the metadata for a given ID.


```solidity
function setMetadata(uint256 id_, Metadata calldata metadata_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id_`|`uint256`|The ID of the work, or `0` for the Edition|
|`metadata_`|`Metadata`|The new metadata.|


### setRoyaltyTarget

Set the ERC2981 royalty target for the given work.


```solidity
function setRoyaltyTarget(uint256 tokenId, address target)
    external
    onlyRoles(EDITION_MANAGER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The ID of the work.|
|`target`|`address`|The address to receive royalties.|


### setTimeframe

Sets the open and close times for the given work.

*Only the creator of the work can call this function.*


```solidity
function setTimeframe(uint256 tokenId, uint64 opensAt, uint64 closesAt) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The ID of the work.|
|`opensAt`|`uint64`|The timestamp after which the work is mintable.|
|`closesAt`|`uint64`|The timestamp after which the work is no longer mintable.|


### transferWork


```solidity
function transferWork(address to_, uint256 tokenId_) external;
```

### grantRoles

*Allows the owner to grant `user` `roles`.
If the `user` already has a role, then it will be an no-op for the role.*


```solidity
function grantRoles(address user_, uint256 roles_)
    public
    payable
    override
    onlyRoles(EDITION_MANAGER_ROLE);
```

### revokeRoles

*Allows the owner to remove `user` `roles`.
If the `user` does not have a role, then it will be an no-op for the role.*


```solidity
function revokeRoles(address user_, uint256 roles_)
    public
    payable
    override
    onlyRoles(EDITION_MANAGER_ROLE);
```

### grantPublisherRole

Grant the publisher role to the given address, allowing it to publish new works within the Edition.

*This function is used by the owner or manager to grant the {EDITION_PUBLISHER_ROLE} to an address, allowing it to publish new works within the Edition.*


```solidity
function grantPublisherRole(address publisher_) external onlyRolesOrOwner(EDITION_MANAGER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`publisher_`|`address`|The address to grant the role to.|


### revokePublisherRole

Revoke the publisher role from the given address, preventing it from publishing new works. Does not affect existing works.

*This function is used by the owner or manager to revoke the {EDITION_PUBLISHER_ROLE} from an address, preventing it from publishing new works within the Edition.*


```solidity
function revokePublisherRole(address publisher_) external onlyRolesOrOwner(EDITION_MANAGER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`publisher_`|`address`|The address to revoke the role from.|


### supportsInterface

Check if the contract supports the given interface.


```solidity
function supportsInterface(bytes4 interfaceId)
    public
    view
    override(IEdition, ERC1155, ERC2981)
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interfaceId`|`bytes4`|The interface ID to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the contract supports the interface, false otherwise.|


### _issue

Issue tokens for the given work.

*This function is used by the [mint](/src/editions/Edition.sol/contract.Edition.md#mint) and {mintBatch} functions to mint tokens and reverts if the new total supply would exceed the maximum supply.*


```solidity
function _issue(address to_, uint256 tokenId_, uint256 amount_, bytes calldata data_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to_`|`address`|The address to issue the tokens to.|
|`tokenId_`|`uint256`|The ID of the work to issue.|
|`amount_`|`uint256`|The amount of tokens to issue.|
|`data_`|`bytes`|The data associated with the issuance. Reserved for future use.|


### _updateSupply

Update the total supply for the given work.

*This function increments the total supply for a given work and reverts if the new total exceeds the maximum supply.*


```solidity
function _updateSupply(Work storage work, uint256 amount_) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`work`|`Work`|The work to update.|
|`amount_`|`uint256`|The amount to add to the total supply.|


### _checkTime

Checks that the current block time falls within the given range.

*This function is used to check that the current block time falls within the given range and reverts if not.*


```solidity
function _checkTime(uint64 start_, uint64 end_) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`start_`|`uint64`|The timestamp after which the work is mintable.|
|`end_`|`uint64`|The timestamp after which the work is no longer mintable.|


### _refundExcess

Refund any excess ETH sent to the contract.

*This function is called after minting tokens to refund any ETH left in the contract after all fees have been collected.*


```solidity
function _refundExcess() internal;
```

## Structs
### Work
An individual work within the Edition.


```solidity
struct Work {
    address creator;
    uint256 maxSupply;
    uint256 totalSupply;
    uint64 opensAt;
    uint64 closesAt;
    Strategy strategy;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`creator`|`address`|The creator of the work.|
|`maxSupply`|`uint256`|The maximum number of mintable tokens for the work.|
|`totalSupply`|`uint256`|The total number of minted tokens for the work.|
|`opensAt`|`uint64`|The timestamp after which the work is mintable.|
|`closesAt`|`uint64`|The timestamp after which the work is no longer mintable. If `0`, there is no closing time.|
|`strategy`|`Strategy`|The fee strategy for the work.|

