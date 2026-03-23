// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BaseProofRegistry {
    address public registryOwner;

    struct Asset {
        uint256 id;
        uint256 rootId;
        uint256 parentId;
        address author;
        address currentOwner;
        bytes32 contentHash;
        uint64 createdAt;
        bool revoked;
        string uri;
    }

    constructor() {
        registryOwner = msg.sender;
    }
}
