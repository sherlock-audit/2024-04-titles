// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {OwnableRoles} from "lib/solady/src/auth/OwnableRoles.sol";
import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {EIP712} from "lib/solady/src/utils/EIP712.sol";
import {SignatureCheckerLib} from "lib/solady/src/utils/SignatureCheckerLib.sol";
import {UUPSUpgradeable} from "lib/solady/src/utils/UUPSUpgradeable.sol";

import {IOpenGraph} from "src/interfaces/IOpenGraph.sol";
import {IEdgeManager} from "src/interfaces/IEdgeManager.sol";
import {ADMIN_ROLE, Edge, Node, Unauthorized} from "src/shared/Common.sol";

/// @title TitlesGraph
/// @notice Titles.xyz implementation of the OpenGraph standard
/// @dev The TitlesGraph contract implements the OpenGraph standard and is responsible for managing the creation and acknowledgment of {Node}s and {Edge}s in the graph.
contract TitlesGraph is IOpenGraph, IEdgeManager, OwnableRoles, EIP712, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SignatureCheckerLib for address;

    error Exists();
    error NotFound();

    /// @notice The set of edge IDs in the graph. Enumerable to enable on-chain graph traversal in the future.
    EnumerableSet.Bytes32Set private _edgeIds;

    /// @notice Edges are relationships between two nodes in the graph.
    mapping(bytes32 id => Edge edge) public edges;

    /// @notice An internal mapping to prevent signature reuse.
    mapping(bytes32 signature => bool used) private _isUsed;

    // @notice The hash of the acknowledgement struct. Used for EIP-712.
    bytes32 public constant ACK_TYPEHASH = keccak256("Ack(bytes32 edgeId,bytes data)");

    // @notice The EIP-712 domain type hash. (Exposed here for convenience.)
    bytes32 public constant DOMAIN_TYPEHASH = _DOMAIN_TYPEHASH;

    /// @notice Modified to check the signature for a proxied acknowledgment.
    modifier checkSignature(bytes32 edgeId, bytes calldata data, bytes calldata signature) {
        bytes32 digest = _hashTypedData(keccak256(abi.encode(ACK_TYPEHASH, edgeId, data)));
        if (
            !edges[edgeId].to.creator.target.isValidSignatureNowCalldata(digest, signature)
                || _isUsed[keccak256(signature)]
        ) {
            revert Unauthorized();
        }
        _;
        _isUsed[keccak256(signature)] = true;
    }

    constructor(address owner_, address admin_) {
        _initializeOwner(owner_);
        _grantRoles(admin_, ADMIN_ROLE);
    }

    /// @inheritdoc IOpenGraph
    /// @notice Create a new {Edge} between two {Node}s in the graph.
    /// @param from_ The {Node} from which the edge originates.
    /// @param to_ The {Node} to which the edge points.
    /// @param data_ Metadata associated with the edge.
    /// @return edge The created edge.
    /// @dev This function is used to create a new edge between two nodes in the graph and will revert if not unique or if called by any address other than the contract referenced as the `from` node. A {NodeTouched} event is emitted for each node and an {EdgeCreated} event is emitted for the edge itself.
    function createEdge(Node calldata from_, Node calldata to_, bytes calldata data_)
        external
        override
        returns (Edge memory edge)
    {
        if (!_isEntity(from_, msg.sender)) revert Unauthorized();
        return _createEdge(from_, to_, data_);
    }

    /// @notice Create multiple edges within the graph.
    /// @param edges_ The edges to create.
    /// @dev This function is used to create multiple edges within the graph and will revert if any of the edges are not unique. It emits a {NodeTouched} event for each node and an {EdgeCreated} event for each edge.
    function createEdges(Edge[] calldata edges_) external onlyRolesOrOwner(ADMIN_ROLE) {
        for (uint256 i = 0; i < edges_.length; i++) {
            _createEdge(edges_[i].from, edges_[i].to, edges_[i].data);
        }
    }

    function _createEdge(Node memory from_, Node memory to_, bytes memory data_)
        internal
        returns (Edge memory edge)
    {
        bytes32 edgeId = keccak256(abi.encode(from_, to_));
        if (!_edgeIds.add(edgeId)) revert Exists();

        edge = Edge({from: from_, to: to_, acknowledged: false, data: data_});
        edges[edgeId] = edge;

        emit NodeTouched(from_, data_);
        emit NodeTouched(to_, data_);
        emit EdgeCreated(edge, data_);
    }

    /// @inheritdoc IEdgeManager
    /// @notice Acknowledge an edge.
    /// @param edgeId_ The ID of the edge to acknowledge.
    /// @param data_ Additional data to include with the acknowledgment.
    /// @return edge The acknowledged edge.
    /// @dev This function is used to acknowledge an edge that was previously created and will revert if the edge does not exist. It emits an {EdgeAcknowledged} event for the edge.
    function acknowledgeEdge(bytes32 edgeId_, bytes calldata data_)
        external
        override
        returns (Edge memory edge)
    {
        if (!_isCreatorOrEntity(edges[edgeId_].to, msg.sender)) revert Unauthorized();
        return _setAcknowledged(edgeId_, data_, true);
    }

    /// @notice Acknowledge an edge using an ECDSA signature.
    /// @param edgeId_ The ID of the edge to acknowledge.
    /// @param data_ Additional data to include with the acknowledgment.
    /// @param signature_ The ECDSA signature to verify.
    /// @dev The request is valid if the given signature was produced using the edge ID as the message and the creator of the `to` node as the signer.
    /// @dev This function is used to acknowledge an edge that was previously created and will revert if the edge does not exist or if the signature is invalid. It emits an {EdgeAcknowledged} event for the edge.
    function acknowledgeEdge(bytes32 edgeId_, bytes calldata data_, bytes calldata signature_)
        external
        checkSignature(edgeId_, data_, signature_)
        returns (Edge memory edge)
    {
        return _setAcknowledged(edgeId_, data_, true);
    }

    /// @inheritdoc IEdgeManager
    /// @notice Unacknowledge an edge.
    /// @param edgeId_ The ID of the edge to unacknowledge.
    /// @param data_ Additional data to include with the unacknowledgment.
    /// @dev This function is used to unacknowledge an edge that was previously acknowledged.
    function unacknowledgeEdge(bytes32 edgeId_, bytes calldata data_)
        external
        override
        returns (Edge memory edge)
    {
        if (!_isCreatorOrEntity(edges[edgeId_].to, msg.sender)) revert Unauthorized();
        return _setAcknowledged(edgeId_, data_, false);
    }

    /// @notice Unacknowledge an edge using an ECDSA signature.
    /// @param edgeId_ The ID of the edge to unacknowledge.
    /// @param data_ Additional data to include with the unacknowledgment.
    /// @param signature_ The ECDSA signature to verify.
    /// @dev The request is valid if the given signature was produced using the edge ID as the message and the creator of the `to` node as the signer.
    /// @dev This function is used to unacknowledge an edge that was previously acknowledged and will revert if the edge does not exist or if the signature is invalid. It emits an {EdgeUnacknowledged} event for the edge.
    function unacknowledgeEdge(bytes32 edgeId_, bytes calldata data_, bytes calldata signature_)
        external
        checkSignature(edgeId_, data_, signature_)
        returns (Edge memory edge)
    {
        return _setAcknowledged(edgeId_, data_, false);
    }

    /// @notice Override the {OwnableRoles} implementation to extend access to the `ADMIN_ROLE`.
    /// @param guy The address to grant the roles.
    /// @param roles The roles to grant.
    /// @dev This function is used to grant roles to an address and will revert if the caller is not the owner and does not have the `ADMIN_ROLE`.
    function grantRoles(address guy, uint256 roles)
        public
        payable
        override
        onlyOwnerOrRoles(ADMIN_ROLE)
    {
        _grantRoles(guy, roles);
    }

    /// @notice Override the {OwnableRoles} implementation to extend access to the `ADMIN_ROLE`.
    /// @param guy The address from which to revoke the roles.
    /// @param roles The roles to revoke.
    /// @dev This function is used to revoke roles from an address and will revert if the caller is not the owner and does not have the `ADMIN_ROLE`.
    function revokeRoles(address guy, uint256 roles)
        public
        payable
        override
        onlyOwnerOrRoles(ADMIN_ROLE)
    {
        _removeRoles(guy, roles);
    }

    /// @notice Get the ID of an edge given the source and target nodes.
    /// @param from_ The source node of the edge.
    /// @param to_ The target node of the edge.
    /// @return edgeId The ID of the edge (i.e. the keccak256 hash of the `from` and `to` nodes).
    function getEdgeId(Node memory from_, Node memory to_) public pure returns (bytes32) {
        return keccak256(abi.encode(from_, to_));
    }

    /// @notice Get the ID of an edge.
    /// @param edge_ The edge for which to get the ID.
    /// @return edgeId The ID of the edge (i.e. the keccak256 hash of the `from` and `to` nodes).
    function getEdgeId(Edge memory edge_) public pure returns (bytes32) {
        return getEdgeId(edge_.from, edge_.to);
    }

    /// @notice Set the acknowledged status of an edge.
    /// @param edgeId_ The ID of the edge to set the acknowledged status for.
    /// @param data_ Additional data to include with the acknowledgment.
    /// @param acknowledged_ The new acknowledged status of the edge.
    /// @return edge The edge with the updated acknowledged status.
    function _setAcknowledged(bytes32 edgeId_, bytes calldata data_, bool acknowledged_)
        internal
        returns (Edge memory edge)
    {
        if (!_edgeIds.contains(edgeId_)) revert NotFound();
        edge = edges[edgeId_];
        edge.acknowledged = acknowledged_;

        if (acknowledged_) {
            emit EdgeAcknowledged(edge, msg.sender, data_);
        } else {
            emit EdgeUnacknowledged(edge, msg.sender, data_);
        }
    }

    /// @notice Allows the admin to upgrade the contract.
    /// @dev This function overrides the {UUPSUpgradeable} implementation to restrict upgrade rights to the graph owner.
    function _authorizeUpgrade(address) internal view override onlyOwnerOrRoles(ADMIN_ROLE) {
        // The modifier handles the authorization.
    }

    /// @notice Returns the domain name and version for EIP-712.
    function _domainNameAndVersion()
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = "TitlesGraph";
        version = "1";
    }

    /// @notice Checks if the given address is the creator of a node.
    /// @param node The node to check.
    /// @param guy The address to check.
    /// @return True if the address is the creator of the node, false otherwise.
    function _isCreator(Node memory node, address guy) internal pure returns (bool) {
        return node.creator.target == guy;
    }

    /// @notice Checks if the given address is the on-chain entity represented by a node.
    /// @param node The node to check.
    /// @param guy The address to check.
    /// @return True if the address is the entity of the node, false otherwise.
    function _isEntity(Node memory node, address guy) internal pure returns (bool) {
        return node.entity.target == guy;
    }

    /// @notice Checks if the given address is either the creator or on-chain entity represented by a node.
    /// @param node The node to check.
    /// @param guy The address to check.
    /// @return True if the address is the creator or entity of the node, false otherwise.
    function _isCreatorOrEntity(Node memory node, address guy) internal pure returns (bool) {
        return _isCreator(node, guy) || _isEntity(node, guy);
    }
}
