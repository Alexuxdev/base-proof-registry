// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BaseProofRegistry {
    // Core admin state
    address public registryOwner;
    bool public paused;

    uint256 public nextAssetId = 1;
    uint256 public nextLicenseId = 1;

    mapping(address => bool) public operators;

    // Events
    event RegistryOwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // Asset data
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

    // License data
    struct License {
        uint256 id;
        uint256 assetId;
        address licensor;
        address licensee;
        uint64 validFrom;
        uint64 validUntil;
        bool exclusive;
        bool revoked;
        string termsURI;
    }

    constructor() {
        registryOwner = msg.sender;
        emit RegistryOwnershipTransferred(address(0), msg.sender);
    }
}
