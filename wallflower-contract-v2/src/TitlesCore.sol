// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LibClone} from "lib/solady/src/utils/LibClone.sol";
import {LibZip} from "lib/solady/src/utils/LibZip.sol";
import {OwnableRoles} from "lib/solady/src/auth/OwnableRoles.sol";
import {Receiver} from "lib/solady/src/accounts/Receiver.sol";
import {Initializable} from "lib/solady/src/utils/Initializable.sol";
import {SafeTransferLib} from "lib/solady/src/utils/SafeTransferLib.sol";
import {UUPSUpgradeable} from "lib/solady/src/utils/UUPSUpgradeable.sol";

import {EnumerableMap} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";
import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import {Edition} from "src/editions/Edition.sol";
import {FeeManager} from "src/fees/FeeManager.sol";

import {
    ADMIN_ROLE,
    EDITION_PUBLISHER_ROLE,
    EditionCreated,
    FeeStrategyUpdated,
    Metadata,
    Node,
    Strategy,
    Target
} from "src/shared/Common.sol";
import {TitlesGraph} from "src/graph/TitlesGraph.sol";

/// @title Titles Core
/// @notice Core contract for the Titles Protocol
contract TitlesCore is OwnableRoles, Initializable, UUPSUpgradeable, Receiver {
    using LibClone for address;
    using LibZip for bytes;
    using SafeTransferLib for address;

    address public editionImplementation = address(new Edition());
    FeeManager public feeManager;
    TitlesGraph public graph;

    /// @notice Initializes the protocol.
    /// @param feeReceiver_ The address to receive fees.
    /// @param splitFactory_ The address of the split factory.
    function initialize(address feeReceiver_, address splitFactory_) external initializer {
        _initializeOwner(msg.sender);

        feeManager = new FeeManager(msg.sender, feeReceiver_, splitFactory_);
        graph = new TitlesGraph(address(this), msg.sender);
    }

    /// @notice The payload for creating a Work within an {Edition}.
    struct WorkPayload {
        Target creator;
        Node[] attributions;
        uint256 maxSupply;
        uint64 opensAt;
        uint64 closesAt;
        Strategy strategy;
        Metadata metadata;
    }

    /// @notice The payload for creating an {Edition}.
    struct EditionPayload {
        WorkPayload work;
        Metadata metadata;
    }

    /// @notice Creates an {Edition} with the given payload.
    /// @param payload_ The compressed payload for creating the {Edition}. See {EditionPayload}.
    /// @param referrer_ The address of the referrer.
    /// @return edition The new {Edition}.
    function createEdition(bytes calldata payload_, address referrer_)
        external
        payable
        returns (Edition edition)
    {
        EditionPayload memory payload = abi.decode(payload_.cdDecompress(), (EditionPayload));

        edition = Edition(editionImplementation.clone());

        // wake-disable-next-line reentrancy
        edition.initialize(
            feeManager, graph, payload.work.creator.target, address(this), payload.metadata
        );

        // wake-disable-next-line unchecked-return-value
        _publish(edition, payload.work, referrer_);

        emit EditionCreated(
            address(edition),
            payload.work.creator.target,
            payload.work.maxSupply,
            payload.work.strategy,
            abi.encode(payload.metadata)
        );
    }

    /// @notice Publishes a new Work in the given {Edition} using the given payload.
    /// @param edition_ The {Edition} to publish the Work in.
    /// @param payload_ The compressed payload for publishing the Work. See {WorkPayload}.
    /// @param referrer_ The address of the referrer.
    /// @return tokenId The token ID of the new Work.
    function publish(Edition edition_, bytes calldata payload_, address referrer_)
        external
        payable
        returns (uint256 tokenId)
    {
        if (!edition_.hasAnyRole(msg.sender, EDITION_PUBLISHER_ROLE)) {
            revert Unauthorized();
        }
        WorkPayload memory payload = abi.decode(payload_.cdDecompress(), (WorkPayload));
        return _publish(edition_, payload, referrer_);
    }

    /// @notice Publishes a new Work in the given {Edition} using the given payload.
    /// @param edition_ The {Edition} to publish the Work in.
    /// @param work_ The payload for publishing the Work. See {EditionPayload}.
    /// @param referrer_ The address of the referrer.
    /// @return tokenId The token ID of the new Work.
    function _publish(Edition edition_, WorkPayload memory work_, address referrer_)
        internal
        returns (uint256 tokenId)
    {
        // Publish the new Work in the Edition
        // wake-disable-next-line reentrancy
        tokenId = edition_.publish(
            work_.creator.target,
            work_.maxSupply,
            work_.opensAt,
            work_.closesAt,
            work_.attributions,
            work_.strategy,
            work_.metadata
        );

        // Collect the creation fee
        // wake-disable-next-line reentrancy
        feeManager.collectCreationFee{value: msg.value}(edition_, tokenId, msg.sender);

        // Create the fee route for the new Work
        // wake-disable-next-line reentrancy
        Target memory feeReceiver = feeManager.createRoute(
            edition_, tokenId, _attributionTargets(work_.attributions), referrer_
        );

        // Set the royalty target for the new Work
        // wake-disable-next-line reentrancy
        edition_.setRoyaltyTarget(tokenId, feeReceiver.target);
    }

    /// @notice Sets the implementation address to be cloned for each new {Edition}.
    /// @param implementation_ The new implementation address.
    /// @dev Only the owner can call this function.
    function setEditionImplementation(address implementation_)
        external
        onlyOwnerOrRoles(ADMIN_ROLE)
    {
        editionImplementation = implementation_;
    }

    /// @inheritdoc UUPSUpgradeable
    /// @dev This function is overridden to restrict access to the owner/admin. No other logic required.
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwnerOrRoles(ADMIN_ROLE)
    {}

    /// @notice Returns the targets of the given attributions.
    function _attributionTargets(Node[] memory attributions_)
        internal
        pure
        returns (Target[] memory targets)
    {
        targets = new Target[](attributions_.length);
        for (uint256 i = 0; i < attributions_.length; i++) {
            targets[i] = attributions_[i].creator;
        }
    }
}
