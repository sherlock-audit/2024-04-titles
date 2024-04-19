// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SafeTransferLib} from "lib/solady/src/utils/SafeTransferLib.sol";

////////////////////
// Standard Roles //
////////////////////

// Global Roles
uint256 constant ADMIN_ROLE = 1 << 0;
uint256 constant CONTROLLER_ROLE = 1 << 1;
uint256 constant ROLE_MANAGER_ROLE = 1 << 2;
uint256 constant FEE_OVERRIDE_ROLE = 1 << 3;
uint256 constant SIGNER_ROLE = 1 << 4;

// Edition Roles
uint256 constant EDITION_MANAGER_ROLE = 1 << 11;
uint256 constant EDITION_MINTER_ROLE = 1 << 12;
uint256 constant EDITION_PUBLISHER_ROLE = 1 << 13;

// Graph Roles
uint256 constant GRAPH_MANAGER_ROLE = 1 << 21;
uint256 constant GRAPH_NODE_CREATOR_ROLE = 1 << 22;
uint256 constant GRAPH_EDGE_CREATOR_ROLE = 1 << 23;

///////////////
// Constants //
///////////////

address constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

/////////////////////
// Standard Errors //
/////////////////////

error MaxSupplyReached();
error NotOpen(uint64 opensAt_, uint64 closesAt_);
error NotImplemented();
error Unauthorized();

/////////////////////
// Standard Events //
/////////////////////

/// @notice Emitted when a new Edition is created.
event EditionCreated(
    address indexed edition,
    address indexed creator,
    uint256 maxSupply,
    Strategy strategy,
    bytes data
);

/// @notice Emitted when a Work is minted with a comment.
event Comment(
    address indexed edition, uint256 indexed tokenId, address indexed author, string comment
);

/// @notice Emitted when a fee strategy is updated for an Edition.
event FeeStrategyUpdated(address indexed edition, uint256 indexed tokenId, Strategy strategy);

/// @notice Emitted when a Work's open and close times are updated.
event TimeframeUpdated(
    address indexed edition, uint256 indexed tokenId, uint64 opensAt, uint64 closesAt
);

/// @notice Emitted when a Work is minted within an Edition.
event Minted(
    address indexed edition, uint256 indexed tokenId, address indexed to, uint256 amount, bytes data
);

/// @notice Emitted when a Work is published within an Edition.
event Published(address indexed edition, uint256 indexed tokenId);

/// @notice Emitted when a Work's creator transfers control of the Work to another account.
event WorkTransferred(address indexed edition, uint256 indexed tokenId, address indexed to);

/// @notice NodeType represents the different types of nodes in the graph.
/// @dev The node types indicate the type of the {Target}. For example, an `ACCOUNT` node type indicates that the target is a wallet, while an `ERC20` node type indicates that the target is an ERC20 token contract.
enum NodeType {
    ACCOUNT,
    COLLECTION_ERC721,
    COLLECTION_ERC1155,
    TOKEN_ERC721,
    TOKEN_ERC1155,
    TOKEN_ERC20
}

/// @notice Fee represents a fee for a given asset.
/// @param asset The address of the asset.
/// @param amount The total amount of the fee (in wei).
struct Fee {
    address asset;
    uint256 amount;
}

/// @notice Edge represents the connection between two nodes in the graph.
/// @param from The source node of the edge.
/// @param to The target node of the edge.
/// @param acknowledged Whether the edge has been acknowledged.
/// @param data The data associated with the edge.
/// @dev The data field is used to store additional information about the edge. The edge's {EdgeManager} is responsible for interpreting this data.
struct Edge {
    Node from;
    Node to;
    bool acknowledged;
    bytes data;
}

/// @notice Node represents a node in the graph.
/// @param nodeType The type of the node.
/// @param entity The on-chain entity represented by the node.
/// @param creator The creator of the work represented by the node.
/// @param data The data associated with the node.
/// @dev The data field is used to store additional information about the node. The node's {EdgeManager} is responsible for interpreting this data.
struct Node {
    NodeType nodeType;
    Target entity;
    Target creator;
    bytes data;
}

/// @notice Metadata represents the metadata associated with an arbitrary entity.
/// @param label The label (or name) of the entity.
/// @param uri The URI associated with the entity.
/// @param data Additional data associated with the entity.
struct Metadata {
    string label;
    string uri;
    bytes data;
}

/// @notice The route for a given (Edition, Token ID).
/// @param feeReceiver The address of the fee receiver.
/// @param revshareReceiver The address of the revshare receiver.
struct Route {
    address feeReceiver;
    address revshareReceiver;
}

/// @notice Strategy represents a fee strategy.
/// @param asset The address of the asset to be used for fees.
/// @param mintFee The fee for minting an asset (in wei).
/// @param revshareBps The royalty revshare (in basis points).
/// @param royaltyBps The ERC2981 secondary sales royalty fee (in basis points).
/// @dev The royalty revshare is a percentage of the collected mint fee that is paid to attributed creators. It is expressed in basis points (1/100th of a percent). For example, a 100 bps (1%) royalty fee on a 1 ETH mint fee would result in a 0.01 ETH royalty fee.
struct Strategy {
    address asset;
    uint112 mintFee;
    uint16 revshareBps;
    uint16 royaltyBps;
}

/// @notice Target represents a target address on a given chain.
/// @param chainId The chain ID of the target.
/// @param target The address of the target.
struct Target {
    uint256 chainId;
    address target;
}
