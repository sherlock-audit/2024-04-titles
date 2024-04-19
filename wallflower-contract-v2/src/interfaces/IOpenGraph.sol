// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "src/shared/Common.sol";

/// @title IOpenGraph
/// @notice Interface for OpenGraph standard
/// @dev The OpenGraph standard defines the interface and events related to creating {Node}s and {Edge}s in the graph, but it has no opinion on how or whether the data should be stored on-chain.
interface IOpenGraph {
    /// @notice Emitted when a {Node} is touched.
    event NodeTouched(Node node, bytes data);

    /// @notice Emitted when an {Edge} is created.
    event EdgeCreated(Edge edge, bytes data);

    /// @notice Creates an {Edge} with the given data.
    /// @param from_ The {Node} from which the relationship originates
    /// @param to_ The {Node} to which the relationship points
    /// @param data_ The serialized data payload for the {Edge} `(Node, Node, bytes)`
    function createEdge(Node memory from_, Node memory to_, bytes calldata data_)
        external
        returns (Edge memory edge);
}
