// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "lib/solady/src/utils/Initializable.sol";
import {OwnableRoles} from "lib/solady/src/auth/OwnableRoles.sol";
import {Ownable} from "lib/solady/src/auth/Ownable.sol";
import {ERC2981} from "lib/solady/src/tokens/ERC2981.sol";
import {SafeTransferLib} from "lib/solady/src/utils/SafeTransferLib.sol";

import {ERC1155} from "solady/tokens/ERC1155.sol";
import {IEdition} from "src/interfaces/IEdition.sol";
import {FeeManager} from "src/fees/FeeManager.sol";
import {TitlesGraph} from "src/graph/TitlesGraph.sol";
import {Node, NodeType, Target, Strategy} from "src/shared/Common.sol";

import {
    EDITION_MANAGER_ROLE,
    EDITION_MINTER_ROLE,
    EDITION_PUBLISHER_ROLE,
    Metadata,
    Node,
    Strategy,
    Comment,
    FeeStrategyUpdated,
    MaxSupplyReached,
    Minted,
    NotImplemented,
    NotOpen,
    Published,
    TimeframeUpdated,
    WorkTransferred
} from "src/shared/Common.sol";

/// @title Edition
/// @notice An ERC1155 contract representing a collection of related works. Each work is represented by a token ID.
contract Edition is IEdition, ERC1155, ERC2981, Initializable, OwnableRoles {
    using SafeTransferLib for address;

    /// @notice An individual work within the Edition.
    /// @param creator The creator of the work.
    /// @param maxSupply The maximum number of mintable tokens for the work.
    /// @param totalSupply The total number of minted tokens for the work.
    /// @param opensAt The timestamp after which the work is mintable.
    /// @param closesAt The timestamp after which the work is no longer mintable. If `0`, there is no closing time.
    /// @param strategy The fee strategy for the work.
    struct Work {
        address creator;
        uint256 maxSupply;
        uint256 totalSupply;
        uint64 opensAt;
        uint64 closesAt;
        Strategy strategy;
    }

    /// @notice The total number of works in the Edition. Also the ID of the latest work.
    uint256 public totalWorks;

    /// @notice The collection of works in the Edition.
    mapping(uint256 => Work) public works;

    /// @notice The metadata for the Edition and its works.
    /// @dev The Edition key is 0, while the work keys are the token IDs.
    mapping(uint256 => Metadata) public _metadata;

    /// @notice The fee manager contract.
    FeeManager public FEE_MANAGER;

    /// @notice The TitlesGraph contract.
    TitlesGraph public GRAPH;

    /// @notice Initialize the Edition contract.
    /// @param feeManager_ The fee manager contract.
    /// @param graph_ The TitlesGraph contract.
    /// @param owner_ The owner of the Edition contract.
    /// @param controller_ The controller of the Edition contract.
    /// @dev This function is called by the {EditionFactory} when creating a new Edition to set the fee manager and owner.
    /// @dev The controller is granted the {EDITION_MANAGER_ROLE} to allow management of the Edition contract.
    function initialize(
        FeeManager feeManager_,
        TitlesGraph graph_,
        address owner_,
        address controller_,
        Metadata calldata metadata_
    ) external initializer {
        _initializeOwner(owner_);
        FEE_MANAGER = feeManager_;
        GRAPH = graph_;

        _grantRoles(controller_, EDITION_MANAGER_ROLE);
        _grantRoles(owner_, EDITION_PUBLISHER_ROLE);

        _metadata[0] = metadata_;
    }

    /// @notice Create a new work in the Edition.
    /// @param creator_ The creator of the work.
    /// @param maxSupply_ The maximum number of mintable tokens for the work.
    /// @param opensAt_ The timestamp after which the work is mintable.
    /// @param closesAt_ The timestamp after which the work is no longer mintable.
    /// @param attributions_ The attributions for the work.
    /// @param strategy_ The fee strategy for the work.
    /// @param metadata_ The metadata for the work.
    function publish(
        address creator_,
        uint256 maxSupply_,
        uint64 opensAt_,
        uint64 closesAt_,
        Node[] calldata attributions_,
        Strategy calldata strategy_,
        Metadata calldata metadata_
    ) external override onlyRoles(EDITION_MANAGER_ROLE) returns (uint256 tokenId) {
        tokenId = ++totalWorks;

        _metadata[tokenId] = metadata_;
        works[tokenId] = Work({
            creator: creator_,
            totalSupply: 0,
            maxSupply: maxSupply_,
            opensAt: opensAt_,
            closesAt: closesAt_,
            strategy: FEE_MANAGER.validateStrategy(strategy_)
        });

        Node memory _node = node(tokenId);
        for (uint256 i = 0; i < attributions_.length; i++) {
            // wake-disable-next-line reentrancy, unchecked-return-value
            GRAPH.createEdge(_node, attributions_[i], attributions_[i].data);
        }

        emit Published(address(this), tokenId);
    }

    /// @notice Get the name of the Edition.
    /// @return The name of the Edition.
    function name() public view override returns (string memory) {
        return _metadata[0].label;
    }

    /// @notice Get the name for a given Work.
    /// @param tokenId The ID of the work.
    /// @return The name of the work.
    function name(uint256 tokenId) public view returns (string memory) {
        return _metadata[tokenId].label;
    }

    /// @notice Get the owner of the Edition.
    /// @return The owner of the Edition.
    /// @dev The owner of the Edition contract has the right to manage roles.
    function owner() public view override(IEdition, Ownable) returns (address) {
        return super.owner();
    }

    function uri() public view returns (string memory) {
        return _metadata[0].uri;
    }

    /// @notice Get the URI for the given token ID.
    /// @param tokenId_ The ID of the token.
    /// @return The URI for the token.
    function uri(uint256 tokenId_)
        public
        view
        virtual
        override(IEdition, ERC1155)
        returns (string memory)
    {
        return _metadata[tokenId_].uri;
    }

    /// @notice Get the creator of the Edition. Alias for {owner}.
    /// @return The creator of the Edition.
    function creator() public view override returns (address) {
        return owner();
    }

    /// @notice Get the creator of the given work.
    /// @param tokenId The ID of the work.
    /// @return The creator of the work.
    function creator(uint256 tokenId) public view override returns (address) {
        return works[tokenId].creator;
    }

    /// @notice Get the {Node} for the collection.
    /// @return The node for the edition.
    function node() public view returns (Node memory) {
        return Node({
            nodeType: NodeType.COLLECTION_ERC1155,
            creator: Target({target: owner(), chainId: block.chainid}),
            entity: Target({target: address(this), chainId: block.chainid}),
            data: ""
        });
    }

    /// @notice Get the {Node} for the given work.
    /// @param tokenId The token ID of the work.
    /// @return The node for the work.
    function node(uint256 tokenId) public view returns (Node memory) {
        return Node({
            nodeType: NodeType.TOKEN_ERC1155,
            creator: Target({target: works[tokenId].creator, chainId: block.chainid}),
            entity: Target({target: address(this), chainId: block.chainid}),
            data: abi.encode(tokenId)
        });
    }

    /// @notice Get the mint fee for one token for the given work.
    /// @param tokenId_ The ID of the work.
    /// @return The mint fee for the token.
    function mintFee(uint256 tokenId_) public view returns (uint256) {
        return mintFee(tokenId_, 1);
    }

    /// @notice Get the mint fee for an `amount` of tokens for the given work.
    /// @param tokenId_ The ID of the work.
    /// @param amount_ The amount of tokens to mint.
    /// @return The mint fee for the tokens.
    function mintFee(uint256 tokenId_, uint256 amount_) public view returns (uint256) {
        if (tokenId_ == 0 || tokenId_ > totalWorks) return 0;
        return FEE_MANAGER.getMintFee(works[tokenId_].strategy, amount_).amount;
    }

    /// @notice Mint a new token for the given work.
    /// @param to_ The address to mint the token to.
    /// @param tokenId_ The ID of the work to mint.
    /// @param amount_ The amount of tokens to mint.
    /// @param referrer_ The address of the referrer.
    /// @param data_ The data associated with the mint. Reserved for future use.
    function mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        address referrer_,
        bytes calldata data_
    ) external payable override {
        // wake-disable-next-line reentrancy
        FEE_MANAGER.collectMintFee{value: msg.value}(
            this, tokenId_, amount_, msg.sender, referrer_, works[tokenId_].strategy
        );

        _issue(to_, tokenId_, amount_, data_);
        _refundExcess();
    }

    /// @notice Mint a new token for the given work with a public comment.
    /// @param to_ The address to mint the token to.
    /// @param tokenId_ The ID of the work to mint.
    /// @param amount_ The amount of tokens to mint.
    /// @param referrer_ The address of the referrer.
    /// @param data_ The data associated with the mint. Reserved for future use.
    /// @param comment_ The public comment associated with the mint. Emitted as an event.
    /// @dev This function is used to mint a token with a public comment, allowing the mint to be associated with a message which will be emitted as an event.
    function mintWithComment(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        address referrer_,
        bytes calldata data_,
        string calldata comment_
    ) external payable {
        Strategy memory strategy = works[tokenId_].strategy;
        // wake-disable-next-line reentrancy
        FEE_MANAGER.collectMintFee{value: msg.value}(
            this, tokenId_, amount_, msg.sender, referrer_, strategy
        );

        _issue(to_, tokenId_, amount_, data_);
        _refundExcess();

        emit Comment(address(this), tokenId_, to_, comment_);
    }

    /// @notice Mint multiple tokens for the given works.
    /// @param to_ The address to mint the tokens to.
    /// @param tokenIds_ The IDs of the works to mint.
    /// @param amounts_ The amounts of each work to mint.
    /// @param data_ The data associated with the mint. Reserved for future use.
    function mintBatch(
        address to_,
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_,
        bytes calldata data_
    ) external payable {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            Work storage work = works[tokenIds_[i]];

            // wake-disable-next-line reentrancy
            FEE_MANAGER.collectMintFee{value: msg.value}(
                this, tokenIds_[i], amounts_[i], msg.sender, address(0), work.strategy
            );

            _checkTime(work.opensAt, work.closesAt);
            _updateSupply(work, amounts_[i]);
        }

        _batchMint(to_, tokenIds_, amounts_, data_);
        _refundExcess();
    }

    /// @notice Mint a token to a set of receivers for the given work.
    /// @param receivers_ The addresses to mint the tokens to.
    /// @param tokenId_ The ID of the work to mint.
    /// @param amount_ The amount of tokens to mint.
    /// @param data_ The data associated with the mint. Reserved for future use.
    function mintBatch(
        address[] calldata receivers_,
        uint256 tokenId_,
        uint256 amount_,
        bytes calldata data_
    ) external payable {
        // wake-disable-next-line reentrancy
        FEE_MANAGER.collectMintFee{value: msg.value}(
            this, tokenId_, amount_, msg.sender, address(0), works[tokenId_].strategy
        );

        for (uint256 i = 0; i < receivers_.length; i++) {
            _issue(receivers_[i], tokenId_, amount_, data_);
        }

        _refundExcess();
    }

    /// @notice Mint a token from the given work to a set of receivers.
    /// @param receivers_ The addresses to mint the tokens to.
    /// @param tokenId_ The ID of the work to mint.
    /// @param data_ The data associated with the mint. Reserved for future use.
    /// @dev This function is used to mint one token for each receiver of a given work, bypassing mint fees. It is intended for promotional purposes.
    function promoMint(address[] calldata receivers_, uint256 tokenId_, bytes calldata data_)
        external
        onlyOwnerOrRoles(EDITION_MANAGER_ROLE | EDITION_MINTER_ROLE)
    {
        for (uint256 i = 0; i < receivers_.length; i++) {
            _issue(receivers_[i], tokenId_, 1, data_);
        }
    }

    /// @notice Get the metadata for the given ID.
    /// @param id_ The ID of the work, or `0` for the Edition.
    /// @return The metadata for the ID.
    function metadata(uint256 id_) external view returns (Metadata memory) {
        return _metadata[id_];
    }

    /// @notice Get the maximum supply for the given work.
    /// @param tokenId_ The ID of the work.
    /// @return The maximum supply for the work.
    function maxSupply(uint256 tokenId_) external view override returns (uint256) {
        return works[tokenId_].maxSupply;
    }

    /// @notice Get the total supply for the given work.
    /// @param tokenId_ The ID of the work.
    /// @return The total supply for the work.
    function totalSupply(uint256 tokenId_) external view override returns (uint256) {
        return works[tokenId_].totalSupply;
    }

    /// @notice Get the fee strategy for the given work.
    /// @param tokenId_ The ID of the work.
    /// @return The fee strategy for the work.
    function feeStrategy(uint256 tokenId_) external view override returns (Strategy memory) {
        return works[tokenId_].strategy;
    }

    /// @notice Set the fee strategy for the given work.
    /// @param tokenId_ The ID of the work.
    /// @param strategy_ The fee strategy for the work.
    /// @dev This function only updates the strategy locally and will NOT change the fee route.
    function setFeeStrategy(uint256 tokenId_, Strategy calldata strategy_) external {
        if (msg.sender != works[tokenId_].creator) revert Unauthorized();
        works[tokenId_].strategy = FEE_MANAGER.validateStrategy(strategy_);
    }

    /// @notice Set the metadata for a given ID.
    /// @param id_ The ID of the work, or `0` for the Edition
    /// @param metadata_ The new metadata.
    function setMetadata(uint256 id_, Metadata calldata metadata_) external {
        // Only the owner can update the Edition metadata
        if (id_ == 0 && msg.sender != owner()) revert Unauthorized();

        // Only the creator can update the work metadata
        if (id_ > 0 && msg.sender != works[id_].creator) revert Unauthorized();

        _metadata[id_] = metadata_;
    }

    /// @notice Set the ERC2981 royalty target for the given work.
    /// @param tokenId The ID of the work.
    /// @param target The address to receive royalties.
    function setRoyaltyTarget(uint256 tokenId, address target)
        external
        onlyRoles(EDITION_MANAGER_ROLE)
    {
        _setTokenRoyalty(tokenId, target, works[tokenId].strategy.royaltyBps);
    }

    /// @notice Sets the open and close times for the given work.
    /// @param tokenId The ID of the work.
    /// @param opensAt The timestamp after which the work is mintable.
    /// @param closesAt The timestamp after which the work is no longer mintable.
    /// @dev Only the creator of the work can call this function.
    function setTimeframe(uint256 tokenId, uint64 opensAt, uint64 closesAt) external {
        Work storage work = works[tokenId];
        if (msg.sender != work.creator) revert Unauthorized();

        // Update the open and close times for the work
        work.opensAt = opensAt;
        work.closesAt = closesAt;

        emit TimeframeUpdated(address(this), tokenId, opensAt, closesAt);
    }

    function transferWork(address to_, uint256 tokenId_) external {
        Work storage work = works[tokenId_];
        if (msg.sender != work.creator) revert Unauthorized();

        // Transfer the work to the new creator
        work.creator = to_;

        emit WorkTransferred(address(this), tokenId_, to_);
    }

    /// @inheritdoc OwnableRoles
    function grantRoles(address user_, uint256 roles_)
        public
        payable
        override
        onlyRoles(EDITION_MANAGER_ROLE)
    {
        _grantRoles(user_, roles_);
    }

    /// @inheritdoc OwnableRoles
    function revokeRoles(address user_, uint256 roles_)
        public
        payable
        override
        onlyRoles(EDITION_MANAGER_ROLE)
    {
        _removeRoles(user_, roles_);
    }

    /// @notice Grant the publisher role to the given address, allowing it to publish new works within the Edition.
    /// @param publisher_ The address to grant the role to.
    /// @dev This function is used by the owner or manager to grant the {EDITION_PUBLISHER_ROLE} to an address, allowing it to publish new works within the Edition.
    function grantPublisherRole(address publisher_)
        external
        onlyRolesOrOwner(EDITION_MANAGER_ROLE)
    {
        _grantRoles(publisher_, EDITION_PUBLISHER_ROLE);
    }

    /// @notice Revoke the publisher role from the given address, preventing it from publishing new works. Does not affect existing works.
    /// @param publisher_ The address to revoke the role from.
    /// @dev This function is used by the owner or manager to revoke the {EDITION_PUBLISHER_ROLE} from an address, preventing it from publishing new works within the Edition.
    function revokePublisherRole(address publisher_)
        external
        onlyRolesOrOwner(EDITION_MANAGER_ROLE)
    {
        _removeRoles(publisher_, EDITION_PUBLISHER_ROLE);
    }

    /// @notice Check if the contract supports the given interface.
    /// @param interfaceId The interface ID to check.
    /// @return True if the contract supports the interface, false otherwise.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IEdition, ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Issue tokens for the given work.
    /// @param to_ The address to issue the tokens to.
    /// @param tokenId_ The ID of the work to issue.
    /// @param amount_ The amount of tokens to issue.
    /// @param data_ The data associated with the issuance. Reserved for future use.
    /// @dev This function is used by the {mint} and {mintBatch} functions to mint tokens and reverts if the new total supply would exceed the maximum supply.
    function _issue(address to_, uint256 tokenId_, uint256 amount_, bytes calldata data_)
        internal
    {
        Work storage work = works[tokenId_];
        _checkTime(work.opensAt, work.closesAt);
        _updateSupply(work, amount_);
        _mint(to_, tokenId_, amount_, data_);
        emit Minted(address(this), tokenId_, to_, amount_, data_);
    }

    /// @notice Update the total supply for the given work.
    /// @param work The work to update.
    /// @param amount_ The amount to add to the total supply.
    /// @dev This function increments the total supply for a given work and reverts if the new total exceeds the maximum supply.
    function _updateSupply(Work storage work, uint256 amount_) internal {
        if ((work.totalSupply += amount_) > work.maxSupply) {
            revert MaxSupplyReached();
        }
    }

    /// @notice Checks that the current block time falls within the given range.
    /// @param start_ The timestamp after which the work is mintable.
    /// @param end_ The timestamp after which the work is no longer mintable.
    /// @dev This function is used to check that the current block time falls within the given range and reverts if not.
    function _checkTime(uint64 start_, uint64 end_) internal view {
        if (block.timestamp < start_ || (end_ != 0 && block.timestamp > end_)) {
            revert NotOpen(start_, end_);
        }
    }

    /// @notice Refund any excess ETH sent to the contract.
    /// @dev This function is called after minting tokens to refund any ETH left in the contract after all fees have been collected.
    function _refundExcess() internal {
        if (msg.value > 0 && address(this).balance > 0) {
            msg.sender.safeTransferETH(address(this).balance);
        }
    }
}
