// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC165} from "lib/forge-std/src/interfaces/IERC165.sol";
import {Edge, Metadata, Node, Strategy, Target} from "src/shared/Common.sol";

interface IEdition is IERC165 {
    /// @notice Publishes a new work within the edition on behalf of `creator` with the given configuration.
    /// @param creator The creator of the work.
    /// @param maxSupply The maximum supply of the work.
    /// @param opensAt The timestamp after which the work is mintable.
    /// @param closesAt The timestamp after which the work is no longer mintable.
    /// @param attributions The attributions for the work.
    /// @param strategy The fee strategy for the work.
    /// @param metadata The metadata for the work.
    /// @return The token ID of the work.
    function publish(
        address creator,
        uint256 maxSupply,
        uint64 opensAt,
        uint64 closesAt,
        Node[] calldata attributions,
        Strategy calldata strategy,
        Metadata calldata metadata
    ) external returns (uint256);

    /// @notice Get the creator of the Edition. Alias for {owner}.
    /// @return The creator of the Edition.
    function creator() external view returns (address);

    /// @notice Get the creator of the given work (token ID).
    /// @param tokenId The token ID of the Edition.
    /// @return The creator of the Edition.
    function creator(uint256 tokenId) external view returns (address);

    /// @notice Mints `amount` of the given `tokenId` to the `to` address.
    /// @param to The address to mint the token to.
    /// @param tokenId The token ID to mint.
    /// @param amount The amount of tokens to mint.
    /// @param referrer The referrer of the mint.
    /// @param data Additional data to pass to the receiver.
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        address referrer,
        bytes calldata data
    ) external payable;

    /// @notice Get the fee strategy for the given token ID.
    /// @param tokenId The token ID to get the fee strategy for.
    /// @return The fee strategy for the token ID.
    function feeStrategy(uint256 tokenId) external view returns (Strategy memory);

    /// @notice Get the max supply for the given token ID.
    /// @param tokenId The token ID to get the max supply for.
    /// @return The max supply for the token ID.
    function maxSupply(uint256 tokenId) external view returns (uint256);

    /// @notice Get the name of the Edition.
    /// @return The name of the Edition.
    function name() external view returns (string memory);

    /// @notice Get the {Node} for the collection.
    /// @return The node for the edition.
    function node() external view returns (Node memory);

    /// @notice Get the {Node} for the given work.
    /// @param tokenId The token ID of the work.
    /// @return The node for the work.
    function node(uint256 tokenId) external view returns (Node memory);

    /// @notice Get the owner of the Edition.
    /// @return The owner of the Edition.
    function owner() external view returns (address);

    /// @notice Get the total supply for the given token ID.
    /// @param tokenId The token ID to get the total supply for.
    /// @return The total supply for the token ID.
    function totalSupply(uint256 tokenId) external view returns (uint256);

    /// @notice Get the URI for the given token ID
    /// @param tokenId The token ID to get the URI for.
    /// @return The URI for the token ID.
    function uri(uint256 tokenId) external view returns (string memory);

    /// @notice Determine if the contract supports the given interface.
    /// @param interfaceId The interface ID to check for support.
    /// @return True if the contract supports the interface, false otherwise.
    function supportsInterface(bytes4 interfaceId) external view override returns (bool);
}
