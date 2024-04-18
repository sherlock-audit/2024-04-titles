// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {IOpenGraph} from "src/interfaces/IOpenGraph.sol";
import {IEdgeManager} from "src/interfaces/IEdgeManager.sol";
import {TitlesGraph} from "src/graph/TitlesGraph.sol";
import {NodeType, Edge, Node, Target, Unauthorized} from "src/shared/Common.sol";

contract Mock1271Signer {
    bytes public constant JTMB = abi.encodePacked("just trust me bro");
    bytes public constant SRSLY = abi.encodePacked("im so srsly legit");

    modifier check(bytes memory sig) {
        require(
            keccak256(sig) == keccak256(JTMB) || keccak256(sig) == keccak256(SRSLY),
            "Mock1271Signer: not legit"
        );
        _;
    }

    function isValidSignature(bytes32, bytes memory sig)
        external
        view
        check(sig)
        returns (bytes4)
    {
        return bytes4(keccak256("isValidSignature(bytes32,bytes)"));
    }
}

contract TitlesGraphTest is Test {
    TitlesGraph public titlesGraph;

    function setUp() public {
        titlesGraph = new TitlesGraph(address(this), address(this));
    }

    function test_createEdge() public {
        vm.expectEmit(true, true, true, true);
        emit IOpenGraph.EdgeCreated(
            Edge({
                from: Node({
                    nodeType: NodeType.COLLECTION_ERC1155,
                    entity: Target({target: address(this), chainId: block.chainid}),
                    creator: Target({target: address(2), chainId: block.chainid}),
                    data: ""
                }),
                to: Node({
                    nodeType: NodeType.TOKEN_ERC1155,
                    entity: Target({target: address(3), chainId: block.chainid}),
                    creator: Target({target: address(4), chainId: block.chainid}),
                    data: abi.encode(42)
                }),
                acknowledged: false,
                data: ""
            }),
            ""
        );
        titlesGraph.createEdge(
            Node({
                nodeType: NodeType.COLLECTION_ERC1155,
                entity: Target({target: address(this), chainId: block.chainid}),
                creator: Target({target: address(2), chainId: block.chainid}),
                data: ""
            }),
            Node({
                nodeType: NodeType.TOKEN_ERC1155,
                entity: Target({target: address(3), chainId: block.chainid}),
                creator: Target({target: address(4), chainId: block.chainid}),
                data: bytes(hex"000000000000000000000000000000000000000000000000000000000000002a")
            }),
            ""
        );
    }

    function test_createEdge_notFirstParty() public {
        vm.expectRevert();
        titlesGraph.createEdge(
            Node({
                nodeType: NodeType.COLLECTION_ERC1155,
                entity: Target({target: address(1), chainId: block.chainid}),
                creator: Target({target: address(2), chainId: block.chainid}),
                data: ""
            }),
            Node({
                nodeType: NodeType.TOKEN_ERC1155,
                entity: Target({target: address(3), chainId: block.chainid}),
                creator: Target({target: address(4), chainId: block.chainid}),
                data: abi.encode(42)
            }),
            ""
        );
    }

    function test_acknowledgeEdge() public {
        Node memory from = Node({
            nodeType: NodeType.COLLECTION_ERC1155,
            entity: Target({target: address(1), chainId: block.chainid}),
            creator: Target({target: address(2), chainId: block.chainid}),
            data: ""
        });

        Node memory to = Node({
            nodeType: NodeType.TOKEN_ERC1155,
            entity: Target({target: address(3), chainId: block.chainid}),
            creator: Target({target: address(4), chainId: block.chainid}),
            data: abi.encode(42)
        });

        // Only the `from` node's entity can create the edge.
        vm.prank(from.entity.target);
        titlesGraph.createEdge(from, to, "");

        vm.expectEmit(true, true, true, true);
        emit IEdgeManager.EdgeAcknowledged(
            Edge({from: from, to: to, acknowledged: true, data: ""}), to.creator.target, ""
        );

        // Only the `to` node's creator (or the entity itself) can acknowledge it
        vm.prank(to.creator.target);
        titlesGraph.acknowledgeEdge(keccak256(abi.encode(from, to)), "");
    }

    function test_acknowledgeEdge_withSignature() public {
        Mock1271Signer signer = new Mock1271Signer();
        bytes memory jtmb = signer.JTMB();

        Edge memory edge = Edge({
            from: Node({
                nodeType: NodeType.COLLECTION_ERC1155,
                entity: Target({target: address(this), chainId: block.chainid}),
                creator: Target({target: address(2), chainId: block.chainid}),
                data: ""
            }),
            to: Node({
                nodeType: NodeType.TOKEN_ERC1155,
                entity: Target({target: address(3), chainId: block.chainid}),
                creator: Target({target: address(signer), chainId: block.chainid}),
                data: abi.encode(42)
            }),
            acknowledged: true,
            data: ""
        });

        // Create the edge
        titlesGraph.createEdge(edge.from, edge.to, "");
        bytes32 edgeId = titlesGraph.getEdgeId(edge);

        // An invalid signature will revert
        vm.expectRevert(Unauthorized.selector);
        titlesGraph.acknowledgeEdge(edgeId, new bytes(0), abi.encodePacked("h4x0r 5ign4tur3"));

        // A valid signature will acknowledge the edge and emit an event
        vm.expectEmit(true, true, true, true);
        emit IEdgeManager.EdgeAcknowledged(edge, address(this), "");
        titlesGraph.acknowledgeEdge(edgeId, new bytes(0), jtmb);

        // Re-acknowledging with the same signature will revert
        vm.expectRevert(Unauthorized.selector);
        titlesGraph.acknowledgeEdge(edgeId, new bytes(0), jtmb);

        // A different signature will acknowledge the edge again
        vm.expectEmit(true, true, true, true);
        emit IEdgeManager.EdgeAcknowledged(edge, address(this), "");
        titlesGraph.acknowledgeEdge(edgeId, new bytes(0), signer.SRSLY());
    }

    function test_unacknowledgeEdge() public {
        Node memory from = Node({
            nodeType: NodeType.COLLECTION_ERC1155,
            entity: Target({target: address(1), chainId: block.chainid}),
            creator: Target({target: address(2), chainId: block.chainid}),
            data: ""
        });

        Node memory to = Node({
            nodeType: NodeType.TOKEN_ERC1155,
            entity: Target({target: address(3), chainId: block.chainid}),
            creator: Target({target: address(4), chainId: block.chainid}),
            data: abi.encode(42)
        });

        bytes32 edgeId = keccak256(abi.encode(from, to));

        vm.prank(from.entity.target);
        titlesGraph.createEdge(from, to, "");

        vm.prank(to.creator.target);
        titlesGraph.acknowledgeEdge(edgeId, "");

        // Only the `to` node's creator (or the entity itself) can unacknowledge it
        vm.expectRevert();
        titlesGraph.unacknowledgeEdge(edgeId, "");

        vm.prank(to.creator.target);
        vm.expectEmit(true, true, true, true);
        emit IEdgeManager.EdgeUnacknowledged(
            Edge({from: from, to: to, acknowledged: false, data: ""}), to.creator.target, ""
        );
        titlesGraph.unacknowledgeEdge(edgeId, "");
    }

    function test_unacknowledgeEdge_withSignature() public {
        Mock1271Signer signer = new Mock1271Signer();
        bytes memory jtmb = signer.JTMB();
        Edge memory edge = Edge({
            from: Node({
                nodeType: NodeType.COLLECTION_ERC1155,
                entity: Target({target: address(this), chainId: block.chainid}),
                creator: Target({target: address(2), chainId: block.chainid}),
                data: ""
            }),
            to: Node({
                nodeType: NodeType.TOKEN_ERC1155,
                entity: Target({target: address(3), chainId: block.chainid}),
                creator: Target({target: address(signer), chainId: block.chainid}),
                data: abi.encode(42)
            }),
            acknowledged: true,
            data: ""
        });

        // Create the edge
        titlesGraph.createEdge(edge.from, edge.to, "");
        bytes32 edgeId = titlesGraph.getEdgeId(edge);

        // Acknowledge it
        vm.prank(edge.to.creator.target);
        titlesGraph.acknowledgeEdge(edgeId, new bytes(0));

        // An invalid signature will revert
        vm.expectRevert();
        titlesGraph.unacknowledgeEdge(edgeId, new bytes(0), abi.encodePacked("h4x0r 5ign4tur3"));

        // A valid signature will unacknowledge the edge and emit an event
        vm.expectEmit(true, true, true, true);
        emit IEdgeManager.EdgeUnacknowledged(
            Edge({from: edge.from, to: edge.to, acknowledged: false, data: edge.data}),
            address(this),
            ""
        );
        titlesGraph.unacknowledgeEdge(edgeId, new bytes(0), jtmb);

        // Re-unacknowledging with the same signature will revert
        vm.expectRevert(Unauthorized.selector);
        titlesGraph.unacknowledgeEdge(edgeId, new bytes(0), jtmb);

        // A different signature will unacknowledge the edge again
        vm.expectEmit(true, true, true, true);
        emit IEdgeManager.EdgeUnacknowledged(
            Edge({from: edge.from, to: edge.to, acknowledged: false, data: edge.data}),
            address(this),
            ""
        );
        titlesGraph.unacknowledgeEdge(edgeId, new bytes(0), signer.SRSLY());
    }

    function test_createEdges() public {
        Edge[] memory edges = new Edge[](3);

        edges[0] = Edge({
            from: Node({
                nodeType: NodeType.COLLECTION_ERC1155,
                entity: Target({target: address(1), chainId: block.chainid}),
                creator: Target({target: address(2), chainId: block.chainid}),
                data: ""
            }),
            to: Node({
                nodeType: NodeType.TOKEN_ERC1155,
                entity: Target({target: address(3), chainId: block.chainid}),
                creator: Target({target: address(4), chainId: block.chainid}),
                data: abi.encode(1)
            }),
            acknowledged: true, // this is ignored, edges always start unacknowledged
            data: ""
        });

        edges[1] = Edge({
            from: Node({
                nodeType: NodeType.COLLECTION_ERC1155,
                entity: Target({target: address(5), chainId: block.chainid}),
                creator: Target({target: address(6), chainId: block.chainid}),
                data: ""
            }),
            to: Node({
                nodeType: NodeType.COLLECTION_ERC721,
                entity: Target({target: address(7), chainId: block.chainid}),
                creator: Target({target: address(8), chainId: block.chainid}),
                data: ""
            }),
            acknowledged: false,
            data: ""
        });

        edges[2] = Edge({
            from: Node({
                nodeType: NodeType.COLLECTION_ERC1155,
                entity: Target({target: address(9), chainId: block.chainid}),
                creator: Target({target: address(10), chainId: block.chainid}),
                data: ""
            }),
            to: Node({
                nodeType: NodeType.TOKEN_ERC721,
                entity: Target({target: address(11), chainId: block.chainid}),
                creator: Target({target: address(12), chainId: block.chainid}),
                data: abi.encode(42069)
            }),
            acknowledged: true,
            data: ""
        });

        // The first is acknowledged in the request but the graph doesn't care
        // what the request says. The graph will create it as unacknowledged.
        Edge memory sameAsFirstButNotAcked = edges[0];
        sameAsFirstButNotAcked.acknowledged = false;
        vm.expectEmit(true, true, true, true);
        emit IOpenGraph.EdgeCreated(sameAsFirstButNotAcked, "");

        // The second is created exactly as specified in the request
        vm.expectEmit(true, true, true, true);
        emit IOpenGraph.EdgeCreated(edges[1], "");

        // Like the first, the third is acknowledged in the request but this
        // is ignored by the graph. The graph will create it as unacknowledged.
        Edge memory sameAsThirdButNotAcked = edges[2];
        sameAsThirdButNotAcked.acknowledged = false;
        vm.expectEmit(true, true, true, true);
        emit IOpenGraph.EdgeCreated(sameAsThirdButNotAcked, "");

        titlesGraph.createEdges(edges);
    }

    function test_getEdgeId() public {
        Edge memory edge = Edge({
            from: Node({
                nodeType: NodeType.COLLECTION_ERC1155,
                entity: Target({target: address(1), chainId: block.chainid}),
                creator: Target({target: address(2), chainId: block.chainid}),
                data: ""
            }),
            to: Node({
                nodeType: NodeType.TOKEN_ERC1155,
                entity: Target({target: address(3), chainId: block.chainid}),
                creator: Target({target: address(4), chainId: block.chainid}),
                data: abi.encode(42)
            }),
            acknowledged: true,
            data: ""
        });

        bytes32 expectedId = keccak256(abi.encode(edge.from, edge.to));
        assertEq(titlesGraph.getEdgeId(edge), expectedId);
        assertEq(titlesGraph.getEdgeId(edge.from, edge.to), expectedId);
    }

    function test_eip712Domain() public {
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = titlesGraph.eip712Domain();
        assertEq(fields, hex"0f");
        assertEq(name, "TitlesGraph");
        assertEq(version, "1");
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, address(titlesGraph));
        assertEq(salt, bytes32(0));
        assertEq(extensions.length, 0);
    }

    function test_constants() public {
        assertEq(titlesGraph.ACK_TYPEHASH(), keccak256("Ack(bytes32 edgeId,bytes data)"));
        assertEq(
            titlesGraph.DOMAIN_TYPEHASH(),
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );
    }
}
