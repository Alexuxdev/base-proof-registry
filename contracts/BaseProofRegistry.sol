// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BaseProofRegistry {
    address public registryOwner;

    constructor() {
        registryOwner = msg.sender;
    }
}
