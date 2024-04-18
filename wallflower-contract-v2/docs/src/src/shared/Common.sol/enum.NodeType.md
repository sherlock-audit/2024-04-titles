# NodeType
[Git Source](https://github.com/titlesnyc/wallflower-contract-v2/blob/3def97b53d8f2e1ca0a59e2027614383ba598af9/src/shared/Common.sol)

NodeType represents the different types of nodes in the graph.

*The node types indicate the type of the {Target}. For example, an `ACCOUNT` node type indicates that the target is a wallet, while an `ERC20` node type indicates that the target is an ERC20 token contract.*


```solidity
enum NodeType {
    ACCOUNT,
    COLLECTION_ERC721,
    COLLECTION_ERC1155,
    TOKEN_ERC721,
    TOKEN_ERC1155,
    TOKEN_ERC20
}
```

