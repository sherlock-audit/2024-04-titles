// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {LibZip} from "lib/solady/src/utils/LibZip.sol";

import {ETH_ADDRESS, Metadata, Node, Strategy, Target} from "src/shared/Common.sol";
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
        uint256 creationCost = titlesCore.feeManager().getCreationFee().amount;
        titlesCore.createEdition{value: creationCost}(
            LibZip.cdCompress(
                abi.encode(
                    TitlesCore.EditionPayload({
                        work: TitlesCore.WorkPayload({
                            creator: Target({target: address(this), chainId: block.chainid}),
                            attributions: new Node[](0),
                            maxSupply: 100,
                            opensAt: 0,
                            closesAt: 0,
                            strategy: Strategy({
                                asset: ETH_ADDRESS,
                                mintFee: 0,
                                revshareBps: 0,
                                royaltyBps: 0
                            }),
                            metadata: Metadata({label: "Werk", uri: "test-werk", data: new bytes(0)})
                        }),
                        metadata: Metadata({
                            label: "Test Edition",
                            uri: "test-edition",
                            data: new bytes(0)
                        })
                    })
                )
            ),
            address(0)
        );

        assertEq(address(1).balance, creationCost);
    }
}
