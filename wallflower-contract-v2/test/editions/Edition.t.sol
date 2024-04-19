// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {Edition} from "src/editions/Edition.sol";
import {FeeManager} from "src/fees/FeeManager.sol";
import {TitlesGraph} from "src/graph/TitlesGraph.sol";
import {
    Comment,
    Node,
    NodeType,
    NotOpen,
    Metadata,
    Strategy,
    Target,
    Unauthorized
} from "src/shared/Common.sol";

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

    receive() external payable {}
}

contract MockGraph {
    function createEdge(Node memory, Node memory, bytes memory) external {}
}

contract EditionTest is Test {
    Edition public edition;
    FeeManager public feeManager;
    TitlesGraph public graph;

    function setUp() public {
        edition = new Edition();
        feeManager = new FeeManager(address(0xdeadbeef), address(0xc0ffee), address(new MockSplitFactory()));
        graph = new TitlesGraph(address(this), address(this));

        edition.initialize(
            feeManager,
            graph,
            address(this),
            address(this),
            Metadata({label: "Test Edition", uri: "ipfs.io/test-edition", data: new bytes(0)})
        );

        edition.publish(
            address(1), // creator
            10, // maxSupply
            0, // opensAt
            0, // closesAt
            new Node[](0), // attributions
            Strategy({
                asset: address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
                mintFee: 0.01 ether,
                revshareBps: 2500, // 25%
                royaltyBps: 250 // 2.5%
            }),
            Metadata({label: "Best Work Ever", uri: "ipfs.io/best-work-ever", data: new bytes(0)})
        );

        // Normally done by the TitlesCore, but we're testing in isolation
        feeManager.createRoute(edition, 1, new Target[](0), address(0));
    }

    function test_initialState() public {
        assertEq(edition.owner(), address(this));
        assertEq(address(edition.FEE_MANAGER()), address(feeManager));
        assertEq(address(edition.GRAPH()), address(graph));
    }

    function test_name() public {
        assertEq(edition.name(), "Test Edition");
        assertEq(edition.name(1), "Best Work Ever");
        assertEq(edition.name(42), "");
    }

    function test_uri() public {
        assertEq(edition.uri(), "ipfs.io/test-edition");
        assertEq(edition.uri(1), "ipfs.io/best-work-ever");
        assertEq(edition.uri(42), "");
    }

    function test_feeStrategy() public {
        Strategy memory strategy = edition.feeStrategy(1);
        assertEq(strategy.asset, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
        assertEq(strategy.mintFee, 0.01 ether);
        assertEq(strategy.revshareBps, 2500);
        assertEq(strategy.royaltyBps, 250);

        strategy = edition.feeStrategy(42);
        assertEq(strategy.asset, address(0));
        assertEq(strategy.mintFee, 0);
        assertEq(strategy.revshareBps, 0);
        assertEq(strategy.royaltyBps, 0);
    }

    function test_creator() public {
        assertEq(edition.creator(), address(this));
        assertEq(edition.creator(1), address(1));
        assertEq(edition.creator(42), address(0));
    }

    function test_node() public {
        Node memory node = edition.node();
        assertEq(uint8(node.nodeType), uint8(NodeType.COLLECTION_ERC1155));
        assertEq(node.entity.target, address(edition));
        assertEq(node.creator.target, address(this));
        assertEq(node.data.length, 0);

        node = edition.node(1);
        assertEq(uint8(node.nodeType), uint8(NodeType.TOKEN_ERC1155));
        assertEq(node.entity.target, address(edition));
        assertEq(node.creator.target, address(1));
        assertEq(node.data.length, 32);
        (uint256 id) = abi.decode(node.data, (uint256));
        assertEq(id, 1);
    }

    function test_mintFee() public {
        assertEq(edition.mintFee(1), 0.0106 ether);
        assertEq(edition.mintFee(42), 0);

        assertEq(edition.mintFee(1, 100), 1.06 ether);
        assertEq(edition.mintFee(42, 100), 0);
    }

    function test_metadata() public {
        Metadata memory metadata = edition.metadata(0);
        assertEq(metadata.label, "Test Edition");
        assertEq(metadata.uri, "ipfs.io/test-edition");
        assertEq(metadata.data.length, 0);

        metadata = edition.metadata(1);
        assertEq(metadata.label, "Best Work Ever");
        assertEq(metadata.uri, "ipfs.io/best-work-ever");
        assertEq(metadata.data.length, 0);

        metadata = edition.metadata(42);
        assertEq(metadata.label, "");
        assertEq(metadata.uri, "");
        assertEq(metadata.data.length, 0);
    }

    function test_maxSupply() public {
        assertEq(edition.maxSupply(1), 10);
        assertEq(edition.maxSupply(42), 0);
    }

    function test_totalSupply() public {
        assertEq(edition.totalSupply(1), 0);

        edition.mint{value: 0.0106 ether}(address(1), 1, 1, address(0), new bytes(0));
        assertEq(edition.totalSupply(1), 1);

        assertEq(edition.totalSupply(42), 0);
    }

    function test_mint() public {
        edition.mint{value: 0.0106 ether}(address(1), 1, 1, address(0), new bytes(0));
        assertEq(edition.totalSupply(1), 1);
        assertEq(address(1).balance, 0.01 ether);
        assertEq(address(0xc0ffee).balance, 0.0006 ether);
    }

    function test_mint_timeframe() public {
        vm.prank(address(1));
        edition.setTimeframe(
            1, uint64(block.timestamp + 10 minutes), uint64(block.timestamp + 2 hours)
        );

        vm.expectRevert(abi.encodeWithSelector(NotOpen.selector, 601, 7201));
        edition.mint{value: 0.0106 ether}(address(1), 1, 1, address(0), new bytes(0));

        skip(10 minutes + 1 seconds);
        edition.mint{value: 0.0106 ether}(address(1), 1, 1, address(0), new bytes(0));

        skip(1 hours + 49 minutes + 58 seconds);
        edition.mint{value: 0.0106 ether}(address(1), 1, 1, address(0), new bytes(0));

        skip(2 seconds);
        vm.expectRevert(abi.encodeWithSelector(NotOpen.selector, 601, 7201));
        edition.mint{value: 0.0106 ether}(address(1), 1, 1, address(0), new bytes(0));
    }

    function test_mintWithComment() public {
        vm.expectEmit(true, true, true, true);
        emit Comment(address(edition), 1, address(1), "500 $DEGEN");
        edition.mintWithComment{value: 0.0106 ether}(
            address(1), 1, 1, address(0), new bytes(0), "500 $DEGEN"
        );
        assertEq(edition.totalSupply(1), 1);
        assertEq(address(1).balance, 0.01 ether);
        assertEq(address(0xc0ffee).balance, 0.0006 ether);
    }

    function test_mintWithComment_withReferrer() public {
        vm.expectEmit(true, true, true, true);
        emit Comment(address(edition), 1, address(1), "500 $DEGEN");
        edition.mintWithComment{value: 0.0106 ether}(
            address(1), 1, 1, address(2), new bytes(0), "500 $DEGEN"
        );
        assertEq(edition.totalSupply(1), 1);
        assertEq(address(1).balance, 0.01 ether);
        assertEq(address(0xc0ffee).balance, 0.0003 ether);
        assertEq(address(2).balance, 0.0003 ether);
    }

    function test_promoMint() public {
        address[] memory recipients = new address[](2);
        recipients[0] = address(1);
        recipients[1] = address(2);
        edition.promoMint(recipients, 1, new bytes(0));
        assertEq(edition.totalSupply(1), 2);
        assertEq(address(1).balance, 0);
        assertEq(address(0xc0ffee).balance, 0 ether);
    }

    function test_promoMint_authorization() public {
        address[] memory recipients = new address[](1);
        recipients[0] = address(1);

        // Only the owner, edition manager, or edition minter can promo mint,
        // and the caller has none of these roles by default
        vm.prank(address(0xdeadbeef));
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector));
        edition.promoMint(recipients, 1, new bytes(0));

        // Give the caller the EDITION_MANAGER_ROLE
        edition.grantRoles(address(0xdeadbeef), 1 << 11);

        // Call as our newly authorized manager
        vm.prank(address(0xdeadbeef));
        edition.promoMint(recipients, 1, new bytes(0));

        // Give the caller the EDITION_MINTER_ROLE
        edition.revokeRoles(address(0xdeadbeef), 1 << 11);
        edition.grantRoles(address(0xc0ffee), 1 << 12);

        // Call as our newly authorized minter
        vm.prank(address(0xc0ffee));
        edition.promoMint(recipients, 1, new bytes(0));

        // Call as the owner
        edition.promoMint(recipients, 1, new bytes(0));

        assertEq(edition.totalSupply(1), 3);
    }

    function test_grantPublisherRole() public {
        edition.grantPublisherRole(address(0xdeadbeef));
        assertEq(edition.hasAnyRole(address(0xdeadbeef), 1 << 13), true);

        // Only the owner or manager can grant the publisher role
        vm.prank(address(2));
        vm.expectRevert(Unauthorized.selector);
        edition.grantPublisherRole(address(2));
    }

    function test_revokePublisherRole() public {
        edition.grantPublisherRole(address(0xdeadbeef));
        assertEq(edition.hasAnyRole(address(0xdeadbeef), 1 << 13), true);

        edition.revokePublisherRole(address(0xdeadbeef));
        assertEq(edition.hasAnyRole(address(0xdeadbeef), 1 << 13), false);

        // Only the owner or manager can revoke the publisher role
        vm.prank(address(2));
        vm.expectRevert(Unauthorized.selector);
        edition.revokePublisherRole(address(0xdeadbeef));
    }

    function test_transferWork() public {
        // Only the work's creator can transfer it
        vm.expectRevert(Unauthorized.selector);
        edition.transferWork(address(1), 1);

        vm.prank(address(1));
        edition.transferWork(address(2), 1);
        assertEq(edition.creator(1), address(2));
    }

    function test_setMetadata() public {
        // The owner can set the edition's metadata
        edition.setMetadata(0, Metadata({label: "Edition", uri: "ipfs.io/edition", data: new bytes(0)}));
        assertEq(edition.metadata(0).label, "Edition");
        assertEq(edition.metadata(0).uri, "ipfs.io/edition");

        // Owner can't set any work's metadata they don't own
        vm.expectRevert(Unauthorized.selector);
        edition.setMetadata(1, Metadata({label: "NGMI", uri: "ipfs.io/ngmi", data: new bytes(0)}));

        // The creator of a work can set its metadata
        vm.prank(address(1));
        edition.setMetadata(1, Metadata({label: "Work", uri: "ipfs.io/work", data: new bytes(0)}));
        assertEq(edition.metadata(1).label, "Work");
        assertEq(edition.metadata(1).uri, "ipfs.io/work");
    }

    function test_setRoyaltyTarget() public {
        edition.setRoyaltyTarget(1, address(2));
        (address receiver,) = edition.royaltyInfo(1, 1);
        assertEq(receiver, address(2));

        // Only the manager can set the royalty target
        vm.prank(address(1));
        vm.expectRevert(Unauthorized.selector);
        edition.setRoyaltyTarget(1, address(2));
    }

    function test_royaltyInfo() public {
        edition.setRoyaltyTarget(1, address(1));

        (address receiver, uint256 royaltyAmount) = edition.royaltyInfo(1, 1 ether);
        assertEq(receiver, address(1));
        assertEq(royaltyAmount, 0.025 ether); // 2.5% of 1 ether

        (receiver, royaltyAmount) = edition.royaltyInfo(1, 0.0005 ether);
        assertEq(receiver, address(1));
        assertEq(royaltyAmount, 0.0000125 ether); // 2.5% of 0.0005 ether
    }
}
