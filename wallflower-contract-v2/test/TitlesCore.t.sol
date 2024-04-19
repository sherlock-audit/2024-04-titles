// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {LibZip} from "lib/solady/src/utils/LibZip.sol";

import {
    ETH_ADDRESS, EditionCreated, Metadata, Node, Strategy, Target
} from "src/shared/Common.sol";
import {TitlesCore} from "src/TitlesCore.sol";

contract MockSplitFactory {
    struct Split {
        address[] recipients;
        uint256[] allocations;
        uint256 totalAllocation;
        uint16 distributionIncentive;
    }

    function createSplit(Split memory, address, address) external view returns (address) {
        return address(this);
    }
}

contract TitlesCoreTest is Test {
    TitlesCore public titlesCore;

    function setUp() public {
        titlesCore = new TitlesCore();
        titlesCore.initialize(address(1), address(new MockSplitFactory()));
    }

    function test_createEdition() public {
        address expectedAddress = 0x7FdB3132Ff7D02d8B9e221c61cC895ce9a4bb773;
        vm.expectEmit(true, true, true, true);
        emit EditionCreated(
            expectedAddress,
            address(this),
            100,
            Strategy({asset: ETH_ADDRESS, mintFee: 0.05 ether, revshareBps: 1000, royaltyBps: 250}),
            abi.encode(
                Metadata({
                    label: "Test Edition",
                    uri: "https://ipfs.io/{{hash}}",
                    data: new bytes(0)
                })
            )
        );

        _createEdition();
    }

    // function test_publish() public {
    //     _createEdition();
    //     titlesCore.publish(

    //     );

    function _createEdition() internal {
        _createEdition(
            address(this),
            TitlesCore.WorkPayload({
                creator: Target({target: address(this), chainId: block.chainid}),
                attributions: new Node[](0),
                maxSupply: 100,
                opensAt: uint64(block.timestamp),
                closesAt: uint64(block.timestamp + 3 days),
                strategy: Strategy({
                    asset: ETH_ADDRESS,
                    mintFee: 0.05 ether,
                    revshareBps: 1000,
                    royaltyBps: 250
                }),
                metadata: Metadata({label: "Werk", uri: "https://ipfs.io/{{hash}}", data: new bytes(0)})
            }),
            Metadata({label: "Test Edition", uri: "https://ipfs.io/{{hash}}", data: new bytes(0)})
        );
    }

    function _createEdition(
        address creator,
        TitlesCore.WorkPayload memory workPayload,
        Metadata memory metadata
    ) internal {
        titlesCore.createEdition{value: titlesCore.feeManager().getCreationFee().amount}(
            LibZip.cdCompress(
                abi.encode(TitlesCore.EditionPayload({work: workPayload, metadata: metadata}))
            ),
            address(0)
        );
    }
}
