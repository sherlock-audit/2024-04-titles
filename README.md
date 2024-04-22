
# TITLES contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the issue page in your private contest repo (label issues as med or high)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

### Q: On what chains are the smart contracts going to be deployed?
Ethereum, Base, OP, Zora, Blast, Arbitrum, zkSync, Degen
___

### Q: If you are integrating tokens, are you allowing only whitelisted tokens to work with the codebase or any complying with the standard? Are they assumed to have certain properties, e.g. be non-reentrant? Are there any types of <a href="https://github.com/d-xo/weird-erc20" target="_blank" rel="noopener noreferrer">weird tokens</a> you want to integrate?
The current version supports native ETH and any standard ERC20 tokens.
___

### Q: Are the admins of the protocols your contracts integrate with (if any) TRUSTED or RESTRICTED? If these integrations are trusted, should auditors also assume they are always responsive, for example, are oracles trusted to provide non-stale information, or VRF providers to respond within a designated timeframe?
The only third-party integration we utilize at this time is 0xSplits, and there are no critical roles involved.  Any issues directly related to 0xSplits own implementation is NOT in scope, consider the protocol to be trusted for the purpose of this audit.
___

### Q: Are there any protocol roles? Please list them and provide whether they are TRUSTED or RESTRICTED, or provide a more comprehensive description of what a role can and can't do/impact.
There are a few roles in the system with varying levels of power. 

ADMIN_ROLE (Trusted) => Granted by the deployer to internal, trusted addresses only.
  On TitlesCore, this role can:
    1) Change the ERC-1155 Edition implementation contract to an arbitrary address (`setEditionImplementation`). No post-auth validation is performed.
    2) Upgrade the contract to an arbitrary new implementation (via `_authorizeUpgrade`, inherited and overridden with auth check from Solady's `UUPSUpgradeable`)

  On TitlesGraph, this role can:
    1) Create new Edges at will (`createEdges`). No post-auth validation is applied, except the typical uniqueness checks.
    2) Upgrade the contract to an arbitrary new implementation (via `_authorizeUpgrade`, inherited and overridden with auth check from Solady's `UUPSUpgradeable`)
    3) Grant or revoke any role to/from any address (`grantRole`, `revokeRole`).

  On FeeManager, this role can:
    1) Set the protocol fees (`setProtocolFees`). All fees are constrained to a constant range.
    2) Create or change a fee route for any work within any Edition (`createRoute`). This is the only way to change the fee route for a work after publication.
    3) Withdraw any funds locked in the contract (`withdraw`). This is the only way to withdraw funds from the contract.
    3) Grant or revoke any role to/from any address (`grantRole`, `revokeRole`).

EDITION_MANAGER_ROLE (Restricted) =>
  On an Edition, this role can:
    1) Publish a new work with any desired configuration (`publish`). This is the only way to create new works after the Edition is created.
    2) Mint promotional copies of any work (`promoMint`). There are no limitations on this action aside from the work's supply cap and minting period.
    3) Set the Edition's ERC2981 royalty receiver (`setRoyaltyTarget`). This is the only way to change the royalty receiver for the Edition.
    4) Grant or revoke any role to/from any address (`grantRole`, `revokeRole`).

EDITION_PUBLISHER_ROLE (Restricted) =>
  On TitlesCore, this role can:
    1) Publish a new work under any Edition for which they have been granted the role (i.e. `edition.hasAnyRole(msg.sender, EDITION_PUBLISHER_ROLE)` is true) (`publish`). After auth, the request is passed to the Edition contract for further handling.

EDITION_MINTER_ROLE (Restricted) =>
  On an Edition, this role can:
    1) Mint promotional copies of any work (`promoMint`). There are no limitations on this action aside from the work's supply cap and minting period.

Other roles which don't have specific role IDs:
  - Editions have an Ownable `owner` who can:
    1) Mint promotional copies of any work (`promoMint`). There are no limitations on this action aside from the work's supply cap and minting period.
    2) Grant or revoke EDITION_PUBLISHER_ROLE to/from any address (`grantPublisherRole`, `revokePublisherRole`).
    3) Manage the ERC1155 contract in typical ways (e.g. transfer ownership). Notably, the owner CANNOT manage roles other than EDITION_PUBLISHER_ROLE.

  - Works within an Edition have a `creator` who can:
    1) Update the minting period for the work (`setTimeframe`). This is the only way to change the minting period for a work after publication.
    2) Set the fee strategy for any work within the Edition (`setFeeStrategy`). This is the only way to change the fee strategy for a work after publication. The fee strategy is validated by the Fee Manager, and the final strategy (which may have been modified during validation) is applied immediately.
    3) Set the metadata for their own works. This is the only way to change the metadata for a work after publication.
    4) Transfer full ownership of the work to a new address (`transferWork`). This is the only way to change the creator for a work.

  - FeeManager has an Ownable `owner` (essentially synonymous with `ADMIN_ROLE`, held by TitlesCore) who can:
    1) Set the protocol fees (`setProtocolFees`). All fees are constrained to a constant range. This role is granted to the TitlesCore contract whose currently scoped version does not have a mechanism for leveraging this permission directly.
    2) Create or change a fee route for any work within any Edition (`createRoute`). This is the only way to change the fee route for a work after publication.
___

### Q: For permissioned functions, please list all checks and requirements that will be made before calling the function.
TitlesCore:
  - `initialize` => initializer, cannot be run twice
  - `publish` => checks that the caller has the EDITION_PUBLISHER_ROLE on the given Edition. 
  - `setEditionImplementation` => checks that the caller is the owner or has the ADMIN_ROLE

FeeManager:
  - `createRoute` => checks that the caller is the owner or has the ADMIN_ROLE
  - `setProtocolFees` => checks that the caller is the owner or has the ADMIN_ROLE
  - `withdraw` => checks that the caller is the owner or has the ADMIN_ROLE

TitlesGraph:
  - `createEdge` => checks that the caller is the contract identified by the `from` node (the `node.entity.target`).
  - `createEdges` => checks that the caller is the owner or has the ADMIN_ROLE
  - `acknowledgeEdge` (standard flow) => checks that the caller is either the creator of the contract identified by the `to` node, or that contract itself.
  - `unacknowledgeEdge` (standard flow) => checks that the caller is either the creator of the contract identified by the `to` node, or that contract itself.
  - `acknowledgeEdge` (signature flow) => checks that the given signature is valid for the `to` node's creator (supports both ECDSA and ERC1271 signers), that the signed hash matches (based on the edge ID and data provided), and that the signature has not been previously used.
  - `unacknowledgeEdge` (signature flow) => checks that the given signature is valid for the `to` node's creator (supports both ECDSA and ERC1271 signers), that the signed hash matches (based on the edge ID and data provided), and that the signature has not been previously used.

Edition:
  - `initialize` => initializer, cannot be run twice
  - `publish` => checks that the caller has the EDITION_MANAGER_ROLE
  - `promoMint` => checks that the caller is the owner of the Edition or holds the EDITION_MANAGER_ROLE or EDITION_MINTER_ROLE
  - `setFeeStrategy` => checks that the caller is the creator of the work for which the strategy is being set.
  - `setMetadata` => checks that the caller is the owner if ID is 0 (representing the Edition itself), or the creator of the specified work otherwise.
  - `setTimeframe` => checks that the caller is the creator of the work for which the timeframe is being set.
  - `transferWork` => checks that the caller is the creator of the work being transferred.
  - `grantRoles`/`revokeRoles` => checks that the caller has the EDITION_MANAGER_ROLE
  - `grantPublisherRole`/`revokePublisherRole` => checks that the caller is the owner of the Edition or has the EDITION_MANAGER_ROLE
___

### Q: Is the codebase expected to comply with any EIPs? Can there be/are there any deviations from the specification?
strict implementation of EIPs
1271 (Graph), 712 (Graph, Edition), 2981 (Edition), 1155 (Edition)
___

### Q: Are there any off-chain mechanisms or off-chain procedures for the protocol (keeper bots, arbitrage bots, etc.)?
N/A
___

### Q: Are there any hardcoded values that you intend to change before (some) deployments?
The exact amounts of the fees controlled by FeeManager may change before deployment, but only within the bounds of the current fee constants.
___

### Q: If the codebase is to be deployed on an L2, what should be the behavior of the protocol in case of sequencer issues (if applicable)? Should Sherlock assume that the Sequencer won't misbehave, including going offline?
Out of scope
___

### Q: Should potential issues, like broken assumptions about function behavior, be reported if they could pose risks in future integrations, even if they might not be an issue in the context of the scope? If yes, can you elaborate on properties/invariants that should hold?
Yes.
___

### Q: Please discuss any design choices you made.
Fund Management: We chose to delegate fee payouts to 0xSplits v2. The protocol aims to avoid any direct TVL in this release.

Graph: This is a new concept with a vast future design space, so we've erred on the side of a minimal implementation with low complexity. We intend to further standardize the OpenGraph model in the future.
___

### Q: Please list any known issues/acceptable risks that should not result in a valid finding.
N/A
___

### Q: We will report issues where the core protocol functionality is inaccessible for at least 7 days. Would you like to override this value?
No
___

### Q: Please provide links to previous audits (if any).
N/A
___

### Q: Please list any relevant protocol resources.
Run `forge doc` or check out the /docs directory in the repo for pretty comprehensive auto-generated docs from the natspec. 
___

### Q: Additional audit information.
In addition to the security of funds, we would also like there to be focus on the sanctity of the data in the TitlesGraph and the permissioning around it (only the appropriate people/contracts can signal reference and acknowledgement of reference). 
___



# Audit scope


[wallflower-contract-v2 @ d23c44def46ce4fd74f3daae36df0135acae7505](https://github.com/titlesnyc/wallflower-contract-v2/tree/d23c44def46ce4fd74f3daae36df0135acae7505)
- [wallflower-contract-v2/src/TitlesCore.sol](wallflower-contract-v2/src/TitlesCore.sol)
- [wallflower-contract-v2/src/editions/Edition.sol](wallflower-contract-v2/src/editions/Edition.sol)
- [wallflower-contract-v2/src/fees/FeeManager.sol](wallflower-contract-v2/src/fees/FeeManager.sol)
- [wallflower-contract-v2/src/graph/TitlesGraph.sol](wallflower-contract-v2/src/graph/TitlesGraph.sol)
- [wallflower-contract-v2/src/shared/Common.sol](wallflower-contract-v2/src/shared/Common.sol)

