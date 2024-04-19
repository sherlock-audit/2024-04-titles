// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {LibZip} from "solady/utils/LibZip.sol";
import {OwnableRoles} from "solady/auth/OwnableRoles.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {SplitFactoryV2} from "splits-v2/splitters/SplitFactoryV2.sol";
import {SplitV2Lib} from "splits-v2/libraries/SplitV2.sol";

import {IEdition} from "src/interfaces/IEdition.sol";
import "src/shared/Common.sol";

/// @title Titles Fee Manager
/// @notice Manages fees for the Titles Protocol
/// @dev The FeeManager contract is responsible for collecting fees associated with protocol actions.
contract FeeManager is OwnableRoles {
    using SafeTransferLib for address;
    using LibZip for bytes;

    /// @notice The payload for creating a {Strategy}.
    /// @param edition The address of the {Edition} to be associated with the {Strategy}.
    /// @param tokenId The ID of the token to be associated with the {Strategy}.
    /// @param strategy The {Strategy} to be created.
    struct StrategyPayload {
        address edition;
        uint256 tokenId;
        Strategy strategy;
    }

    /////////////////////
    // Events & Errors //
    /////////////////////

    /// @notice Emitted when a fee is collected.
    /// @param edition The address of the edition for which the fee was collected.
    /// @param work The ID of the work for which the fee was collected.
    /// @param asset The address of the asset which was collected.
    /// @param fee The amount of the fee collected.
    /// @param referrerShare The portion of the collected fee which was paid to the referrer.
    event FeeCollected(
        address indexed edition, uint256 work, address asset, uint256 fee, uint256 referrerShare
    );

    /// @notice Emitted when the protocol fees are changed.
    /// @param protocolFeeBps The new protocol fee in basis points.
    /// @param protocolFlatFee The new protocol flat fee.
    /// @param mintReferrerRevshareBps The new partner revenue share in basis points.
    event ProtocolFeesChanged(
        uint16 protocolFeeBps, uint128 protocolFlatFee, uint16 mintReferrerRevshareBps
    );

    /// @notice Thrown when an invalid fee configuration is supplied.
    error InvalidFee();

    /// @notice Thrown when a fee cannot be routed.
    error NotRoutable();

    ///////////////////
    // Fee Constants //
    ///////////////////

    /// @dev The maximum basis points (BPS) value. Equivalent to 100%.
    uint16 public constant MAX_BPS = 10_000;

    /// @dev The maximum protocol fee in basis points (BPS). Equivalent to 33.33%.
    uint16 public constant MAX_PROTOCOL_FEE_BPS = 3333;

    /// @dev The maximum protocol fee in wei. Applies to both flat and percentage fees.
    uint64 public constant MAX_PROTOCOL_FEE = 0.1 ether;

    /// @dev The maximum royalty fee in basis points (BPS). Equivalent to 95%.
    uint16 public constant MAX_ROYALTY_BPS = 9500;

    /// @dev The minimum royalty fee in basis points (BPS). Equivalent to 2.5%.
    uint16 public constant MIN_ROYALTY_BPS = 250;

    ///////////////////////
    // Fee Configuration //
    ///////////////////////

    /// @notice The protocol creation fee. This fee is collected when a new {Edition} is created.
    uint128 public protocolCreationFee = 0.0001 ether;

    /// @notice The flat fee for the protocol. This fee is collected on all mint transactions.
    uint128 public protocolFlatFee = 0.0006 ether;

    /// @notice The protocol fee share in basis points (BPS). Only applies to protocol fees collected for unpriced mints.
    uint32 public protocolFeeshareBps = 3333;

    /// @notice The share of protocol fees to be distributed to the direct referrer of the mint, in basis points (BPS).
    uint16 public mintReferrerRevshareBps = 5000;

    /// @notice The share of protocol fees to be distributed to the referrer of the collection, in basis points (BPS).
    uint16 public collectionReferrerRevshareBps = 2500;

    /// @notice The address of the protocol fee receiver.
    address public protocolFeeReceiver;

    /// @notice The {SplitFactoryV2} contract used to create fee splits.
    SplitFactoryV2 public splitFactory;

    /// @notice The mapping of referrers for each {Edition}'s creation.
    mapping(IEdition edition => address referrer) public referrers;

    /// @notice The mapping of fee receivers by ID.
    mapping(bytes32 id => Target receiver) private _feeReceivers;

    /// @notice Initializes the {FeeManager} contract.
    /// @param protocolFeeReceiver_ The address of the protocol fee receiver.
    /// @param splitFactory_ The address of the {SplitFactoryV2} contract.
    constructor(address admin_, address protocolFeeReceiver_, address splitFactory_) {
        _initializeOwner(msg.sender);
        _grantRoles(admin_, ADMIN_ROLE);
        protocolFeeReceiver = protocolFeeReceiver_;
        splitFactory = SplitFactoryV2(splitFactory_);
    }

    /// @notice Creates a new fee route for the given {Edition} and attributions.
    /// @param edition_ The {Edition} for which to create the route.
    /// @param tokenId_ The token ID associated with the route.
    /// @param attributions_ The attributions to be associated with the route.
    /// @param referrer_ The address of the referrer to receive a share of the fee.
    function createRoute(
        IEdition edition_,
        uint256 tokenId_,
        Target[] calldata attributions_,
        address referrer_
    ) external onlyOwnerOrRoles(ADMIN_ROLE) returns (Target memory receiver) {
        Target memory creator = edition_.node(tokenId_).creator;

        if (attributions_.length == 0) {
            // No attributions, pay the creator directly
            receiver = creator;
        } else {
            // Distribute the fee among the creator and attributions
            (address[] memory targets, uint256[] memory revshares) = _buildSharesAndTargets(
                creator, attributions_, edition_.feeStrategy(tokenId_).revshareBps
            );

            // Create the split. The protocol retains "ownership" to enable future use cases.
            receiver = Target({
                target: splitFactory.createSplit(
                    SplitV2Lib.Split({
                        recipients: targets,
                        allocations: revshares,
                        totalAllocation: 1e6,
                        distributionIncentive: 0
                    }),
                    address(this),
                    creator.target
                    ),
                chainId: creator.chainId
            });
        }

        _feeReceivers[getRouteId(edition_, tokenId_)] = receiver;
        referrers[edition_] = referrer_;
    }

    /// @notice Collects the creation fee for a given {Edition}.
    /// @param edition_ The {Edition} for which to collect the creation fee.
    /// @param tokenId_ The token ID associated with the fee.
    /// @param feePayer_ The address of the account paying the fee.
    function collectCreationFee(IEdition edition_, uint256 tokenId_, address feePayer_)
        external
        payable
    {
        Fee memory fee = getCreationFee();
        if (fee.amount == 0) return;

        _route(fee, Target({target: protocolFeeReceiver, chainId: block.chainid}), feePayer_);
        emit FeeCollected(address(edition_), tokenId_, ETH_ADDRESS, fee.amount, 0);
    }

    /// @notice Collects the mint fee for a given {Edition}.
    /// @param edition_ The {Edition} for which to collect the mint fee.
    /// @param tokenId_ The token ID associated with the fee.
    /// @param amount_ The amount of the fee to collect.
    /// @param payer_ The address of the account paying the fee.
    /// @param referrer_ The address of the referrer to receive a share of the fee.
    function collectMintFee(
        IEdition edition_,
        uint256 tokenId_,
        uint256 amount_,
        address payer_,
        address referrer_
    ) external payable {
        _collectMintFee(
            edition_, tokenId_, amount_, payer_, referrer_, getMintFee(edition_, tokenId_, amount_)
        );
    }

    /// @notice Collects the mint fee for a given {Edition} and token ID, routing it as appropriate.
    /// @param edition The {Edition} for which the fee is being collected.
    /// @param tokenId_ The token ID associated with the fee.
    /// @param amount_ The amount of the fee to collect.
    /// @param payer_ The address of the account paying the fee.
    /// @param referrer_ The address of the referrer to receive a share of the fee.
    /// @param strategy_ The {Strategy} to use for computing the fee split.
    function collectMintFee(
        IEdition edition,
        uint256 tokenId_,
        uint256 amount_,
        address payer_,
        address referrer_,
        Strategy calldata strategy_
    ) external payable {
        _collectMintFee(
            edition, tokenId_, amount_, payer_, referrer_, getMintFee(strategy_, amount_)
        );
    }

    /// @notice Gets the fee receiver for a given {Edition}.
    /// @param edition_ The {Edition} for which to get the fee receiver.
    /// @return feeReceiver The {Target} to receive the fee.
    function feeReceiver(IEdition edition_, uint256 tokenId_) public view returns (Target memory) {
        return _feeReceivers[getRouteId(edition_, tokenId_)];
    }

    /// @notice Calculates the fee for creating a new {Edition}.
    /// @return fee The {Fee} for creating a new {Edition}.
    /// @dev The creation fee is a flat fee collected by the protocol when a new {Edition} is created.
    function getCreationFee() public view returns (Fee memory fee) {
        return Fee({asset: ETH_ADDRESS, amount: protocolCreationFee});
    }

    /// @notice Calculates the mint fee for a given {Edition} based on its {Strategy}.
    /// @param edition_ The {Edition} for which to calculate the mint fee.
    /// @return fee The {Fee} for minting the {Edition}.
    /// @dev The mint fee is calculated as the sum of:
    ///      - The mint fee specified by the creator in the {Strategy}.
    ///      - The protocol's base transaction fee (see {protocolFlatFee}).
    function getMintFee(IEdition edition_, uint256 tokenId_, uint256 quantity_)
        public
        view
        returns (Fee memory fee)
    {
        return getMintFee(edition_.feeStrategy(tokenId_), quantity_);
    }

    /// @notice Calculates the mint fee for a given {Strategy} based on the quantity of tokens being minted.
    /// @param strategy_ The {Strategy} for which to calculate the mint fee.
    /// @param quantity_ The quantity of tokens being minted.
    /// @return fee The {Fee} for minting the tokens.
    /// @dev The mint fee is calculated as the sum of:
    ///      - The {Strategy.mintFee}.
    ///      - The {protocolFlatFee}.
    function getMintFee(Strategy memory strategy_, uint256 quantity_)
        public
        view
        returns (Fee memory fee)
    {
        // Return the total fee (creator's mint fee + protocol flat fee)
        return Fee({asset: ETH_ADDRESS, amount: quantity_ * (strategy_.mintFee + protocolFlatFee)});
    }

    /// @notice Calculates the referrer share for a given amount.
    /// @param protocolFee_ The amount from which to calculate the referrer share.
    /// @return referrerShare The mint referrer's share.
    function getMintReferrerShare(uint256 protocolFee_, address referrer_)
        public
        view
        returns (uint256)
    {
        if (referrer_ == address(0)) return 0;
        return protocolFee_ * mintReferrerRevshareBps / MAX_BPS;
    }

    /// @notice Calculates the collection referrer share for a given amount.
    /// @param protocolFee_ The amount from which to calculate the collection referrer share.
    /// @return referrerShare The collection referrer's share.
    function getCollectionReferrerShare(uint256 protocolFee_, address referrer_)
        public
        view
        returns (uint256)
    {
        if (referrer_ == address(0)) return 0;
        return protocolFee_ * collectionReferrerRevshareBps / MAX_BPS;
    }

    /// @notice Gets the route ID for a given {Edition} and token ID.
    /// @param edition_ The {Edition} for which to get the route ID.
    /// @param tokenId_ The token ID for which to get the route ID.
    /// @return id The route ID.
    function getRouteId(IEdition edition_, uint256 tokenId_) public pure returns (bytes32 id) {
        return keccak256(abi.encodePacked(edition_, tokenId_));
    }

    /// @notice Updates the protocol fees which are collected for various actions.
    /// @param protocolCreationFee_ The new protocol creation fee. This fee is collected when a new {Edition} is created. Cannot exceed {MAX_PROTOCOL_FEE}.
    /// @param protocolFlatFee_ The new protocol flat fee. This fee is collected on all mint transactions. Cannot exceed {MAX_PROTOCOL_FEE}.
    /// @param protocolFeeShareBps_ The new protocol fee share in basis points. Cannot exceed {MAX_PROTOCOL_FEE_BPS}.
    /// @param mintReferrerRevshareBps_ The new mint referrer revenue share in basis points. This plus the collection referrer share cannot exceed {MAX_ROYALTY_BPS}.
    /// @param collectionReferrerRevshareBps_ The new collection referrer revenue share in basis points. This plus the mint referrer share cannot exceed {MAX_ROYALTY_BPS}.
    /// @dev This function can only be called by the owner or an admin.
    function setProtocolFees(
        uint64 protocolCreationFee_,
        uint64 protocolFlatFee_,
        uint16 protocolFeeShareBps_,
        uint16 mintReferrerRevshareBps_,
        uint16 collectionReferrerRevshareBps_
    ) external onlyOwnerOrRoles(ADMIN_ROLE) {
        if (
            protocolCreationFee_ > MAX_PROTOCOL_FEE || protocolFlatFee_ > MAX_PROTOCOL_FEE
                || protocolFeeShareBps_ > MAX_PROTOCOL_FEE_BPS
                || (mintReferrerRevshareBps_ + collectionReferrerRevshareBps_) > MAX_BPS
        ) {
            revert InvalidFee();
        }
        protocolCreationFee = protocolCreationFee_;
        protocolFlatFee = protocolFlatFee_;
        protocolFeeshareBps = protocolFeeShareBps_;
        mintReferrerRevshareBps = mintReferrerRevshareBps_;
        collectionReferrerRevshareBps = collectionReferrerRevshareBps_;
    }

    /// @notice Returns a validated {Strategy} based on the given data.
    /// @param strategy_ The {Strategy} to validate.
    /// @return strategy The validated {Strategy}.
    function validateStrategy(Strategy calldata strategy_)
        external
        pure
        returns (Strategy memory strategy)
    {
        // Clamp the revshare to the range of [MIN_ROYALTY_BPS...MAX_ROYALTY_BPS]
        uint16 revshareBps = strategy_.revshareBps > MAX_ROYALTY_BPS
            ? MAX_ROYALTY_BPS
            : strategy_.revshareBps < MIN_ROYALTY_BPS ? MIN_ROYALTY_BPS : strategy_.revshareBps;

        // Clamp the royalty to the range of [0...MAX_ROYALTY_BPS]
        uint16 royaltyBps =
            strategy_.royaltyBps > MAX_ROYALTY_BPS ? MAX_ROYALTY_BPS : strategy_.royaltyBps;

        strategy = Strategy({
            asset: strategy_.asset == address(0) ? ETH_ADDRESS : strategy_.asset,
            mintFee: strategy_.mintFee,
            revshareBps: revshareBps,
            royaltyBps: royaltyBps
        });
    }

    /// @notice Allows the contract to receive ETH.
    receive() external payable {}

    /// @notice An escape hatch to transfer any trapped assets from the contract to the given address.
    /// @param asset_ The address of the asset to withdraw.
    /// @param amount_ The amount of the asset to withdraw.
    /// @param to_ The address to send the asset to.
    /// @dev This is meant to be used in cases where the contract is holding assets that it should not be. This function can only be called by an admin.
    function withdraw(address asset_, uint256 amount_, address to_)
        external
        onlyRolesOrOwner(ADMIN_ROLE)
    {
        _transfer(asset_, amount_, address(this), to_);
    }

    /// @notice Collects the given {Fee} for a given {Edition} and token ID, routing it as appropriate.
    /// @param edition_ The {Edition} for which the fee is being collected.
    /// @param tokenId_ The token ID associated with the fee.
    /// @param amount_ The amount of tokens being minted.
    /// @param payer_ The address of the account paying the fee.
    /// @param referrer_ The address of the referrer to receive a share of the fee.
    /// @param fee_ The {Fee} to collect.
    function _collectMintFee(
        IEdition edition_,
        uint256 tokenId_,
        uint256 amount_,
        address payer_,
        address referrer_,
        Fee memory fee_
    ) internal {
        if (fee_.amount == 0) return;

        // For free mints:
        // - Protocol Share = 1/3 of flat fee
        // - Edition Share = 2/3 of flat fee
        //
        // For priced mints:
        // - Protocol Share = 100% of flat fee, shared as follows:
        // - Edition Share = 100% of creator-specified mint cost, 0% of flat fee
        //
        // In both cases, the protocol and edition shares may be split as follows:
        // - Protocol Share
        //   - If a referred mint, mint referrer gets 50% of the protocol share
        //   - If a referred collection, collection referrer gets 25% of the protcol share
        //   - Protocol fee receiver gets the remainder of the protocol share
        // - Edition Share
        //   - Attributions equally split 25% of the edition share, if applicable
        //   - Creator gets the remainder of the edition share

        uint256 protocolFee = protocolFlatFee * amount_;
        uint256 protocolShare;
        if (fee_.amount == protocolFee) {
            protocolShare = protocolFee * protocolFeeshareBps / MAX_BPS;
        } else {
            protocolShare = protocolFee;
        }

        _route(
            Fee({asset: fee_.asset, amount: fee_.amount - protocolShare}),
            _feeReceivers[getRouteId(edition_, tokenId_)],
            payer_
        );

        uint256 referrerShare =
            _splitProtocolFee(edition_, fee_.asset, protocolShare, payer_, referrer_);
        emit FeeCollected(address(edition_), tokenId_, fee_.asset, fee_.amount, referrerShare);
    }

    function _splitProtocolFee(
        IEdition edition_,
        address asset_,
        uint256 amount_,
        address payer_,
        address referrer_
    ) internal returns (uint256 referrerShare) {
        // The creation and mint referrers earn 25% and 50% of the protocol's share respectively, if applicable
        uint256 mintReferrerShare = getMintReferrerShare(amount_, referrer_);
        uint256 collectionReferrerShare = getCollectionReferrerShare(amount_, referrers[edition_]);
        referrerShare = mintReferrerShare + collectionReferrerShare;

        _route(
            Fee({asset: asset_, amount: amount_ - referrerShare}),
            Target({target: protocolFeeReceiver, chainId: block.chainid}),
            payer_
        );

        _route(
            Fee({asset: asset_, amount: mintReferrerShare}),
            Target({target: referrer_, chainId: block.chainid}),
            payer_
        );

        _route(
            Fee({asset: asset_, amount: collectionReferrerShare}),
            Target({target: referrer_, chainId: block.chainid}),
            payer_
        );
    }

    /// @notice Routes the given {Fee} to the appropriate receiver.
    /// @param fee_ The {Fee} to route.
    /// @param feeReceiver_ The {Target} to receive the fee.
    /// @param feePayer_ The address of the account paying the fee.
    /// @dev If the fee amount is zero, this function will return early. If the receiver is not on the same chain as the payer, this function will revert.
    function _route(Fee memory fee_, Target memory feeReceiver_, address feePayer_) internal {
        // Cross-chain fee routing is not supported yet
        if (block.chainid != feeReceiver_.chainId) revert NotRoutable();
        if (fee_.amount == 0) return;

        _transfer(fee_.asset, fee_.amount, feePayer_, feeReceiver_.target);
    }

    /// @notice Transfers the given amount of the given asset from the sender to the receiver.
    /// @param asset_ The address of the asset to transfer.
    /// @param amount_ The amount of the asset to transfer.
    /// @param from_ The address of the account sending the asset.
    /// @param to_ The address of the account receiving the asset.
    function _transfer(address asset_, uint256 amount_, address from_, address to_) internal {
        if (asset_ == ETH_ADDRESS) {
            to_.safeTransferETH(amount_);
        } else {
            asset_.safeTransferFrom(from_, to_, amount_);
        }
    }

    /// @notice Builds the targets and shares arrays for a given creator and attributions.
    /// @param creator The creator of the work.
    /// @param attributions The attributions for the work.
    /// @param revshareBps The revshare in basis points.
    /// @return targets The array of targets.
    /// @return shares The array of shares.
    /// @dev Note that cross-chain payouts are not currently supported. Rather than reverting, this function assumes that the creator and attributions are on the same network.
    function _buildSharesAndTargets(
        Target memory creator,
        Target[] memory attributions,
        uint32 revshareBps
    ) internal pure returns (address[] memory targets, uint256[] memory shares) {
        uint32 attributionShares = uint32(attributions.length);
        uint32 attributionRevShare = revshareBps * 100 / attributionShares;
        uint32 creatorShare = 1e6 - (attributionRevShare * attributionShares);

        // Build the targets and shares arrays using this layout:
        // - targets: [creator, ...attributions]
        // - shares: [creatorShare, ...attributionShares]
        targets = new address[](attributionShares + 1);
        shares = new uint256[](attributionShares + 1);

        targets[0] = creator.target;
        shares[0] = creatorShare;

        for (uint8 i = 0; i < attributionShares; i++) {
            targets[i + 1] = attributions[i].target;
            shares[i + 1] = attributionRevShare;
        }
    }
}
