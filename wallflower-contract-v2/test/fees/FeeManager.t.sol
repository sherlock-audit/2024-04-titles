// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {SplitV2Lib} from "splits-v2/libraries/SplitV2.sol";

import {IEdition} from "src/interfaces/IEdition.sol";
import {FeeManager} from "src/fees/FeeManager.sol";
import {
    ETH_ADDRESS, Fee, Node, NodeType, Strategy, Target, Unauthorized
} from "src/shared/Common.sol";

contract MockEdition {
    address public owner = address(0xc0ffee);

    function feeStrategy(uint256) external pure returns (Strategy memory) {
        return
            Strategy({asset: ETH_ADDRESS, mintFee: 0.01 ether, revshareBps: 2500, royaltyBps: 1000});
    }

    function creator(uint256) external view returns (address) {
        return owner;
    }

    function node() external view returns (Node memory) {
        return Node({
            nodeType: NodeType.COLLECTION_ERC1155,
            entity: Target({target: address(this), chainId: block.chainid}),
            creator: Target({target: address(0xc0ffee), chainId: block.chainid}),
            data: new bytes(0)
        });
    }

    function node(uint256 id) external view returns (Node memory) {
        return Node({
            nodeType: NodeType.TOKEN_ERC1155,
            entity: Target({target: address(this), chainId: block.chainid}),
            creator: Target({target: address(0xc0ffee), chainId: block.chainid}),
            data: abi.encode(id)
        });
    }
}

contract MockSplitFactory {
    function createSplit(SplitV2Lib.Split memory, address, address)
        external
        view
        returns (address)
    {
        return address(this);
    }

    receive() external payable {}
}

contract FeeManagerTest is Test {
    FeeManager public feeManager;
    MockEdition public mockEdition = new MockEdition();

    function setUp() public {
        feeManager = new FeeManager(address(1), address(this), address(new MockSplitFactory()));
    }

    function test_createRoute() public {
        Target[] memory attributions = new Target[](2);
        attributions[0] = Target({chainId: 1, target: address(1)});
        attributions[1] = Target({chainId: 2, target: address(2)});

        address[] memory recipients = new address[](3);
        recipients[0] = address(0xc0ffee);
        recipients[1] = attributions[0].target;
        recipients[2] = attributions[1].target;

        uint256[] memory allocations = new uint256[](3);
        allocations[0] = 750_000;
        allocations[1] = 125_000;
        allocations[2] = 125_000;

        MockSplitFactory splitFactory =
            MockSplitFactory(payable(address(feeManager.splitFactory())));
        vm.expectCall(
            address(splitFactory),
            abi.encodeCall(
                splitFactory.createSplit,
                (
                    SplitV2Lib.Split({
                        recipients: recipients,
                        allocations: allocations,
                        totalAllocation: 1e6,
                        distributionIncentive: 0
                    }),
                    address(feeManager),
                    address(0xc0ffee)
                )
            )
        );

        Target memory receiver =
            feeManager.createRoute(IEdition(address(mockEdition)), 1, attributions, address(0));
        assertEq(receiver.target, address(feeManager.splitFactory()));
        assertEq(feeManager.feeReceiver(IEdition(address(mockEdition)), 1).target, receiver.target);
    }

    function test_createRoute_noAttributions() public {
        Target memory receiver =
            feeManager.createRoute(IEdition(address(mockEdition)), 1, new Target[](0), address(0));

        // No attributions, so the receiver should be the creator
        assertEq(receiver.target, address(0xc0ffee));
    }

    function test_createRoute_notOwner() public {
        vm.prank(address(0xdeadbeef));
        vm.expectRevert(Unauthorized.selector);
        feeManager.createRoute(IEdition(address(mockEdition)), 1, new Target[](0), address(0));
    }

    function test_collectCreationFee() public {
        feeManager.createRoute(IEdition(address(mockEdition)), 1, new Target[](0), address(0));

        vm.expectEmit(true, true, true, true);
        emit FeeManager.FeeCollected(address(mockEdition), 1, ETH_ADDRESS, 0.0001 ether, 0);
        feeManager.collectCreationFee{value: 0.0001 ether}(
            IEdition(address(mockEdition)), 1, address(this)
        );
    }

    function test_collectCreationFee_insufficientValue() public {
        vm.expectRevert();
        feeManager.collectCreationFee{value: 0.0001 ether - 1 wei}(
            IEdition(address(mockEdition)), 1, address(this)
        );
    }

    function test_collectMintFee() public {
        feeManager.createRoute(IEdition(address(mockEdition)), 1, new Target[](0), address(0));

        vm.expectEmit(true, true, true, true);
        emit FeeManager.FeeCollected(address(mockEdition), 1, ETH_ADDRESS, 0.0106 ether, 0);
        feeManager.collectMintFee{value: 0.0106 ether}(
            IEdition(address(mockEdition)), 1, 1, address(this), address(0)
        );
    }

    function test_collectMintFee_insufficientValue() public {
        feeManager.createRoute(IEdition(address(mockEdition)), 1, new Target[](0), address(0));

        vm.expectRevert();
        feeManager.collectMintFee{value: 0.0106 ether - 1 wei}(
            IEdition(address(mockEdition)), 1, 1, address(this), address(0)
        );
    }

    function test_collectMintFee_excessValue() public {
        feeManager.createRoute(IEdition(address(mockEdition)), 1, new Target[](0), address(0));

        vm.expectEmit(true, true, true, true);
        emit FeeManager.FeeCollected(address(mockEdition), 1, ETH_ADDRESS, 0.0106 ether, 0);
        feeManager.collectMintFee{value: 0.05 ether}(
            IEdition(address(mockEdition)), 1, 1, address(this), address(0)
        );
    }

    function test_collectMintFee_noCreatorMintFee() public {
        feeManager.createRoute(IEdition(address(mockEdition)), 1, new Target[](0), address(0));

        Strategy memory strategy =
            Strategy({asset: ETH_ADDRESS, mintFee: 0 ether, revshareBps: 1_000, royaltyBps: 1_000});
        vm.expectEmit(true, true, true, true);
        emit FeeManager.FeeCollected(address(mockEdition), 1, ETH_ADDRESS, 0.0006 ether, 0);
        feeManager.collectMintFee{value: 0.0006 ether}(
            IEdition(address(mockEdition)), 1, 1, address(this), address(0), strategy
        );
    }

    function test_getCreationFee() public view {
        assertEq(
            abi.encode(feeManager.getCreationFee()),
            abi.encode(Fee({asset: ETH_ADDRESS, amount: 0.0001 ether}))
        );
    }

    function test_getMintFee() public view {
        assertEq(
            abi.encode(feeManager.getMintFee(IEdition(address(mockEdition)), 1, 1)),
            abi.encode(Fee({asset: ETH_ADDRESS, amount: 0.0106 ether}))
        );

        assertEq(
            abi.encode(
                feeManager.getMintFee(
                    Strategy({
                        asset: ETH_ADDRESS,
                        mintFee: 0.5 ether,
                        revshareBps: 1_000,
                        royaltyBps: 1_000
                    }),
                    1
                )
            ),
            abi.encode(Fee({asset: ETH_ADDRESS, amount: 0.5006 ether}))
        );
    }

    function test_setProtocolFees() public {
        feeManager.setProtocolFees(0.0001 ether, 0.0006 ether, 1000, 1000, 1000);

        assertEq(
            abi.encode(feeManager.getCreationFee()),
            abi.encode(Fee({asset: ETH_ADDRESS, amount: 0.0001 ether}))
        );

        assertEq(
            abi.encode(
                feeManager.getMintFee(
                    Strategy({
                        asset: ETH_ADDRESS,
                        mintFee: 0.5 ether,
                        revshareBps: 1_000,
                        royaltyBps: 1_000
                    }),
                    1
                )
            ),
            abi.encode(Fee({asset: ETH_ADDRESS, amount: 0.5006 ether}))
        );

        assertEq(feeManager.mintReferrerRevshareBps(), 1000);

        assertEq(feeManager.collectionReferrerRevshareBps(), 1000);

        feeManager.setProtocolFees(0, 0, 0, 0, 0);
        assertEq(
            abi.encode(feeManager.getCreationFee()),
            abi.encode(Fee({asset: ETH_ADDRESS, amount: 0}))
        );
        assertEq(
            abi.encode(
                feeManager.getMintFee(
                    Strategy({
                        asset: ETH_ADDRESS,
                        mintFee: 0.5 ether,
                        revshareBps: 1_000,
                        royaltyBps: 1_000
                    }),
                    1
                )
            ),
            abi.encode(Fee({asset: ETH_ADDRESS, amount: 0.5 ether}))
        );
    }

    function test_setProtocolFees_excessiveFees() public {
        // max protocol feeshare is 3333 == 33.33% => should revert
        vm.expectRevert(FeeManager.InvalidFee.selector);
        feeManager.setProtocolFees(0.1 ether, 0.1 ether, 3334, 0, 0);

        // max mint revshare is 10000 == 100% => should revert
        vm.expectRevert(FeeManager.InvalidFee.selector);
        feeManager.setProtocolFees(0.1 ether, 0.1 ether, 0, 10001, 0);

        // max collection revshare is 10000 == 100% => should revert
        vm.expectRevert(FeeManager.InvalidFee.selector);
        feeManager.setProtocolFees(0.1 ether, 0.1 ether, 0, 0, 10001);

        // max mint + collection revshare is 10000 == 100% => should revert
        vm.expectRevert(FeeManager.InvalidFee.selector);
        feeManager.setProtocolFees(0.1 ether, 0.1 ether, 0, 5000, 5001);

        // max creation fee is 0.1 eth => should revert
        vm.expectRevert(FeeManager.InvalidFee.selector);
        feeManager.setProtocolFees(0.1 ether + 1 wei, 0.1 ether, 0, 0, 0);

        // max flat fee is 0.1 eth => should revert
        vm.expectRevert(FeeManager.InvalidFee.selector);
        feeManager.setProtocolFees(0.1 ether, 0.1 ether + 1 wei, 0, 0, 0);

        // max fees => should not revert
        feeManager.setProtocolFees(0.1 ether, 0.1 ether, 3333, 5000, 5000);
    }

    function test_setProtocolFees_notOwner() public {
        vm.prank(address(0xdeadbeef));
        vm.expectRevert(Unauthorized.selector);
        feeManager.setProtocolFees(0.0001 ether, 0.0006 ether, 1000, 1000, 1000);
    }

    function test_validateStrategy() public view {
        Strategy memory validStrategy =
            Strategy({asset: ETH_ADDRESS, mintFee: 0.01 ether, revshareBps: 2500, royaltyBps: 0});

        // Strategy is valid, so it should have been returned as is
        assertEq(abi.encode(feeManager.validateStrategy(validStrategy)), abi.encode(validStrategy));
    }

    function test_validateStrategy_invalidRoyalty() public view {
        Strategy memory strategy;
        strategy.revshareBps = 9501; // should be clamped to 95%
        strategy.royaltyBps = 9501; // should be clamped to 95%
        assertEq(
            abi.encode(feeManager.validateStrategy(strategy)),
            abi.encode(
                Strategy({asset: ETH_ADDRESS, mintFee: 0, revshareBps: 9500, royaltyBps: 9500})
            )
        );

        strategy.revshareBps = 0; // should be clamped to 2.5%
        strategy.royaltyBps = 0; // should be left as is
        assertEq(
            abi.encode(feeManager.validateStrategy(strategy)),
            abi.encode(Strategy({asset: ETH_ADDRESS, mintFee: 0, revshareBps: 250, royaltyBps: 0}))
        );
    }

    function test_getMintReferrerShare(uint256 amount) public view {
        vm.assume(amount < type(uint128).max);
        assertEq(
            feeManager.getMintReferrerShare(amount, address(1)),
            amount * feeManager.mintReferrerRevshareBps() / 1e4
        );
    }

    function test_getMintReferrerShare_noReferrer(uint256 amount) public view {
        assertEq(feeManager.getMintReferrerShare(amount, address(0)), 0);
    }

    function test_getCollectionReferrerShare(uint256 amount) public view {
        vm.assume(amount < type(uint128).max);
        assertEq(
            feeManager.getCollectionReferrerShare(amount, address(1)),
            amount * feeManager.collectionReferrerRevshareBps() / 1e4
        );
    }

    function test_getCollectionReferrerShare_noReferrer(uint256 amount) public view {
        assertEq(feeManager.getCollectionReferrerShare(amount, address(0)), 0);
    }

    function test_getRouteId() public view {
        assertEq(
            feeManager.getRouteId(IEdition(address(mockEdition)), 1),
            keccak256(abi.encodePacked(address(mockEdition), uint256(1)))
        );
    }

    receive() external payable {}
}
