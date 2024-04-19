// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MockERC721} from "forge-std/mocks/MockERC721.sol";

import {SplitsWarehouse} from
    "lib/splits-contracts-monorepo/packages/splits-v2/src/SplitsWarehouse.sol";
import {SplitV2Lib} from
    "lib/splits-contracts-monorepo/packages/splits-v2/src/libraries/SplitV2.sol";
import {PullSplitFactory} from
    "lib/splits-contracts-monorepo/packages/splits-v2/src/splitters/pull/PullSplitFactory.sol";
import {PullSplit} from
    "lib/splits-contracts-monorepo/packages/splits-v2/src/splitters/pull/PullSplit.sol";

import {Receiver} from "lib/solady/src/accounts/Receiver.sol";
import {LibZip} from "lib/solady/src/utils/LibZip.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

import {TitlesCore} from "src/TitlesCore.sol";
import {Edition} from "src/editions/Edition.sol";
import {
    ETH_ADDRESS, Metadata, NodeType, Node, Route, Strategy, Target
} from "src/shared/Common.sol";

contract Bucket is Receiver {
    function balance() public view returns (uint256) {
        return address(this).balance;
    }
}

contract TitlesE2E is Test, Receiver {
    using LibZip for bytes;

    PullSplitFactory public splitFactory =
        new PullSplitFactory(address(new SplitsWarehouse("Efeweum", "ETH")));

    Bucket public bucket;
    TitlesCore public titles;
    Node[] public _attributions;

    Edition public PRICED_EDITION;

    function setUp() public {
        bucket = new Bucket();
        titles = new TitlesCore();

        // Initialize with Bucket as the fee receiver
        titles.initialize(address(bucket), address(splitFactory));

        _attributions.push(
            Node({
                nodeType: NodeType.COLLECTION_ERC1155,
                creator: Target({target: address(0xdeadbeef1), chainId: block.chainid}),
                entity: Target({target: address(1), chainId: block.chainid}),
                data: abi.encode(0)
            })
        );

        _attributions.push(
            Node({
                nodeType: NodeType.TOKEN_ERC721,
                creator: Target({target: address(0xdeadbeef2), chainId: block.chainid}),
                entity: Target({target: address(2), chainId: block.chainid}),
                data: abi.encode(0)
            })
        );

        PRICED_EDITION = _createEdition(0.01 ether);
    }

    function test_createEdition() public {
        uint256 creationCost = titles.feeManager().getCreationFee().amount;
        uint256 balanceBefore = bucket.balance();
        _createEdition(0);
        uint256 balanceAfter = bucket.balance();
        // Check the bucket (should have changed by 1x creation fee)
        assertEq(balanceAfter - balanceBefore, creationCost);
    }

    function test_createEdition_noAttributions() public {
        uint256 creationCost = titles.feeManager().getCreationFee().amount;
        uint256 balanceBefore = bucket.balance();
        _createEditionWithoutAttributions(0);
        uint256 balanceAfter = bucket.balance();
        // Check the bucket (should have changed by 1x creation fee)
        assertEq(balanceAfter - balanceBefore, creationCost);
    }

    function test_createAndMint_pricedEdition_withAttributions() public {
        uint256 expectedBalance = bucket.balance();

        address[] memory targets = new address[](3);
        targets[0] = address(0xc0ffee); // creator
        targets[1] = _attributions[0].creator.target; // first attribution
        targets[2] = _attributions[1].creator.target; // second attribution

        uint256[] memory shares = new uint256[](3);
        shares[0] = 750_000; // 100% - 25% royalty = 75%
        shares[1] = 125_000; // 25% / 2 = 12.5%
        shares[2] = 125_000; // 25% / 2 = 12.5%

        vm.expectCall(
            address(splitFactory),
            abi.encodeCall(
                splitFactory.createSplit,
                (
                    SplitV2Lib.Split({
                        recipients: targets,
                        allocations: shares,
                        totalAllocation: 1e6,
                        distributionIncentive: 0
                    }),
                    address(titles.feeManager()),
                    address(0xc0ffee)
                )
            )
        );

        // Create the edition
        Edition edition = _createEdition(0.01 ether);
        Target memory feeReceiver = titles.feeManager().feeReceiver(edition, 1);
        uint256 mintFee = titles.feeManager().getMintFee(edition, 1, 1).amount;
        uint256 creationFee = titles.feeManager().getCreationFee().amount;
        uint256 protocolFlatFee = titles.feeManager().protocolFlatFee();
        uint256 pricedMintAmount = mintFee - protocolFlatFee;

        // Sanity check the fees
        assertEq(mintFee, 0.0106 ether);
        assertEq(creationFee, 0.0001 ether);
        assertEq(protocolFlatFee, 0.0006 ether);
        assertEq(pricedMintAmount, 0.01 ether);

        // Check the bucket (should increase by 1x creation fee)
        expectedBalance += creationFee;
        assertEq(bucket.balance(), expectedBalance);

        // Mint a token
        edition.mint{value: mintFee}(address(this), 1, 1, address(0), "");

        // Check the mint fee distribution, which should be:
        // += 0.01 eth (creator's mint fee) => creator + attributions (split)
        assertEq(address(feeReceiver.target).balance, pricedMintAmount);

        // += 0.0006 eth (protocol flat fee) => protocol + referrers (direct)
        expectedBalance += protocolFlatFee;
        assertEq(bucket.balance(), expectedBalance);

        // Mint 4 more directly from the edition
        edition.mint{value: mintFee * 4}(address(this), 1, 4, address(0), "");

        // Check the distribution again, which should be:
        // += 0.04 eth (4x creator's mint fee) => creator + attributions (split)
        assertEq(address(feeReceiver.target).balance, pricedMintAmount * 5);

        // += 0.0024 eth (4x protocol flat fee) => protocol + referrers (direct)
        expectedBalance += (protocolFlatFee * 4);
        assertEq(bucket.balance(), expectedBalance);

        // Now that there are some fees in the split, let's distribute them
        PullSplit split = PullSplit(feeReceiver.target);
        SplitsWarehouse warehouse = SplitsWarehouse(address(split.SPLITS_WAREHOUSE()));
        uint256 ethTokenId = warehouse.NATIVE_TOKEN_ID();

        split.distribute(
            SplitV2Lib.Split({
                recipients: targets,
                allocations: shares,
                totalAllocation: 1e6,
                distributionIncentive: 0
            }),
            ETH_ADDRESS,
            address(0)
        );

        // The protocol should have no share of the mint fees and therefore zero balance
        assertEq(warehouse.balanceOf(address(bucket), ethTokenId), 0 ether);

        // The creator should have earned 75% of their priced mint costs
        // += 0.01 * 5 * 75% = 0.0375 eth (less 1 wei due to 0xSplits logic)
        assertEq(warehouse.balanceOf(address(0xc0ffee), ethTokenId), 0.0375 ether - 1 wei);

        // The attributions should have earned 25% of the priced mint costs (12.5% each)
        // += 0.01 * 5 * 25% / 2 = 0.00625 eth (less 1 wei due to 0xSplits logic)
        assertEq(
            warehouse.balanceOf(_attributions[0].creator.target, ethTokenId), 0.00625 ether - 1 wei
        );
        assertEq(
            warehouse.balanceOf(_attributions[1].creator.target, ethTokenId), 0.00625 ether - 1 wei
        );
    }

    function test_createAndMint_freeEdition_withAttributions() public {
        uint256 expectedBalance = bucket.balance();

        address[] memory targets = new address[](3);
        targets[0] = address(0xc0ffee); // creator
        targets[1] = _attributions[0].creator.target; // first attribution
        targets[2] = _attributions[1].creator.target; // second attribution

        uint256[] memory shares = new uint256[](3);
        shares[0] = 750_000; // 100% - 25% revshare = 75%
        shares[1] = 125_000; // 25% / 2 = 12.5%
        shares[2] = 125_000; // 25% / 2 = 12.5%

        vm.expectCall(
            address(splitFactory),
            abi.encodeCall(
                splitFactory.createSplit,
                (
                    SplitV2Lib.Split({
                        recipients: targets,
                        allocations: shares,
                        totalAllocation: 1e6,
                        distributionIncentive: 0
                    }),
                    address(titles.feeManager()),
                    address(0xc0ffee)
                )
            )
        );

        // Create the edition
        Edition edition = _createEdition(0);
        Target memory feeReceiver = titles.feeManager().feeReceiver(edition, 1);
        uint256 mintFee = titles.feeManager().getMintFee(edition, 1, 1).amount;
        uint256 creationFee = titles.feeManager().getCreationFee().amount;
        uint256 protocolFlatFee = titles.feeManager().protocolFlatFee();

        // Calculate the protocol share of the mint fee:
        // 33.3333% of the flat fee ≈ 0.0002 eth (0.00019998 to be exact)
        uint256 protocolShare = protocolFlatFee * titles.feeManager().protocolFeeshareBps() / 1e4;
        assertEq(protocolShare, 0.00019998 ether);

        // Sanity check the fees
        assertEq(mintFee, protocolFlatFee);

        // Check the bucket (should increase by 1x creation fee)
        expectedBalance += creationFee;
        assertEq(bucket.balance(), expectedBalance);

        // Mint a token
        edition.mint{value: protocolFlatFee}(address(this), 1, 1, address(0), "");

        // Check the mint fee distribution, which should be:
        // += 2/3 of flat fee => creator + attributions (split)
        assertEq(address(feeReceiver.target).balance, mintFee - protocolShare);

        // += 1/3 of flat fee => protocol + referrers (direct)
        expectedBalance += protocolShare;
        assertEq(bucket.balance(), expectedBalance);
    }

    function test_createAndMint_pricedEdition_noAttributions() public {
        uint256 expectedBalance = bucket.balance();

        // Create the edition
        Edition edition = _createEditionWithoutAttributions(0.01 ether);
        uint256 mintFee = titles.feeManager().getMintFee(edition, 1, 1).amount;
        uint256 creationFee = titles.feeManager().getCreationFee().amount;
        uint256 protocolFlatFee = titles.feeManager().protocolFlatFee();
        uint256 pricedMintAmount = mintFee - protocolFlatFee;

        // Sanity check the fees
        assertEq(mintFee, 0.0106 ether);
        assertEq(creationFee, 0.0001 ether);
        assertEq(protocolFlatFee, 0.0006 ether);
        assertEq(pricedMintAmount, 0.01 ether);

        // Check the bucket (should increase by 1x creation fee)
        expectedBalance += creationFee;
        assertEq(bucket.balance(), expectedBalance);

        // Mint a token
        edition.mint{value: mintFee}(address(this), 1, 1, address(0), "");

        // Check the mint fee distribution, which should be:
        // += 0.01 eth (creator's mint fee) => creator (direct)
        assertEq(address(0xc0ffee).balance, pricedMintAmount);

        // += 0.0006 eth (protocol flat fee) => protocol + referrers (direct)
        expectedBalance += protocolFlatFee;
        assertEq(bucket.balance(), expectedBalance);

        // Mint 4 more tokens
        edition.mint{value: mintFee * 4}(address(this), 1, 4, address(0), "");

        // Check the distribution again, which should be:
        // += 0.04 eth (4x creator's mint fee) => creator (direct)
        assertEq(address(0xc0ffee).balance, pricedMintAmount * 5);

        // += 0.0024 eth (4x protocol flat fee) => protocol + referrers (direct)
        expectedBalance += (protocolFlatFee * 4);
        assertEq(bucket.balance(), expectedBalance);

        // The creator should have been paid directly (no attributions => no splits)
        assertEq(address(0xc0ffee).balance, 0.05 ether);
    }

    function test_createAndMint_freeEdition_noAttributions() public {
        uint256 expectedBalance = bucket.balance();

        // Create the edition
        Edition edition = _createEditionWithoutAttributions(0);
        uint256 mintFee = titles.feeManager().getMintFee(edition, 1, 1).amount;
        uint256 creationFee = titles.feeManager().getCreationFee().amount;
        uint256 protocolFlatFee = titles.feeManager().protocolFlatFee();

        // Calculate the protocol share of the mint fee:
        // 33.3333% of the flat fee ≈ 0.0002 eth (0.00019998 to be exact)
        uint256 protocolShare = protocolFlatFee * titles.feeManager().protocolFeeshareBps() / 1e4;
        assertEq(protocolShare, 0.00019998 ether);

        // Sanity check the fees
        assertEq(mintFee, protocolFlatFee);

        // Check the bucket (should increase by 1x creation fee)
        expectedBalance += creationFee;
        assertEq(bucket.balance(), expectedBalance);

        // Mint a token via the core
        edition.mint{value: protocolFlatFee}(address(this), 1, 1, address(0), "");

        // Check the mint fee distribution, which should be:
        // += 2/3 of flat fee => creator (direct)
        assertEq(address(0xc0ffee).balance, mintFee - protocolShare);

        // += 1/3 of flat fee => protocol + referrers (direct)
        expectedBalance += protocolShare;
        assertEq(bucket.balance(), expectedBalance);
    }

    function test_create_several_and_reference() public {
        Edition edition1 = PRICED_EDITION;
        Edition edition2 = _createEdition(0);

        Node[] memory attrs = new Node[](2);
        attrs[0] = Node({
            nodeType: NodeType.COLLECTION_ERC1155,
            creator: Target({target: PRICED_EDITION.owner(), chainId: block.chainid}),
            entity: Target({target: address(edition1), chainId: block.chainid}),
            data: abi.encode(0)
        });
        attrs[1] = Node({
            nodeType: NodeType.TOKEN_ERC1155,
            creator: Target({target: address(0xdeadbeef2), chainId: block.chainid}),
            entity: Target({target: address(edition2), chainId: block.chainid}),
            data: abi.encode(1)
        });

        Edition edition3 = _createEdition(
            "Edition III: Revenge of the Spliff", 0.02 ether, 2_000, address(bucket), attrs
        );

        // Check the bucket (should hold 3x creation fee)
        assertEq(bucket.balance(), 0.0003 ether);
    }

    function _createEdition(uint112 mintFee) internal returns (Edition) {
        return _createEdition("Test Edition", mintFee, 2500, address(0xc0ffee), _attributions);
    }

    function _createEditionWithoutAttributions(uint112 mintFee) internal returns (Edition) {
        return _createEdition("Test Edition", mintFee, 2500, address(0xc0ffee), new Node[](0));
    }

    function _createEdition(
        string memory name,
        uint112 mintFee_,
        uint16 revshareBps_,
        address creator_,
        Node[] memory attributions_
    ) internal returns (Edition) {
        bytes memory payload = LibZip.cdCompress(
            abi.encode(
                TitlesCore.EditionPayload({
                    metadata: Metadata({label: name, uri: "QMockContentHash", data: ""}),
                    work: TitlesCore.WorkPayload({
                        creator: Target({target: creator_, chainId: block.chainid}),
                        attributions: attributions_,
                        strategy: Strategy({
                            asset: ETH_ADDRESS,
                            mintFee: mintFee_,
                            revshareBps: revshareBps_,
                            royaltyBps: revshareBps_
                        }),
                        maxSupply: 100,
                        metadata: Metadata({label: name, uri: "QMockContentHash", data: ""}),
                        opensAt: uint64(block.timestamp),
                        closesAt: uint64(block.timestamp + 1 weeks)
                    })
                })
            )
        );

        return titles.createEdition{value: titles.feeManager().getCreationFee().amount}(
            payload, address(0)
        );
    }
}
