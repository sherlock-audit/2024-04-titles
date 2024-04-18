// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "src/shared/Common.sol";

/// @title IEdgeManager
/// @notice Interface for EdgeManager
/// @dev An EdgeManager is responsible for managing the relationship between {Node}s (i.e. {Edge}s) in the graph.
interface IEdgeManager {
    /// @notice Emitted when an {Edge} is acknowledged.
    /// @param edge The acknowledged {Edge}.
    /// @param acknowledger The address of the acknowledger.
    /// @param data The data associated with the acknowledgment.
    event EdgeAcknowledged(Edge edge, address acknowledger, bytes data);

    /// @notice Emitted when an {Edge} is unacknowledged.
    /// @param edge The unacknowledged {Edge}.
    /// @param acknowledger The address of the acknowledger.
    /// @param data The data associated with the unacknowledgment.
    event EdgeUnacknowledged(Edge edge, address acknowledger, bytes data);

    /// @notice Acknowledges an {Edge} with the given data.
    /// @param edgeId_ The ID of the {Edge} to acknowledge.
    /// @param data_ The data associated with the acknowledgment.
    /// @return edge The acknowledged {Edge}.
    function acknowledgeEdge(bytes32 edgeId_, bytes calldata data_)
        external
        returns (Edge memory edge);

    /// @notice Unacknowledges an {Edge} with the given data.
    /// @param edgeId_ The ID of the {Edge} to unacknowledge.
    /// @param data_ The data associated with the unacknowledgment.
    /// @return edge The unacknowledged {Edge}.
    function unacknowledgeEdge(bytes32 edgeId_, bytes calldata data_)
        external
        returns (Edge memory edge);
}
