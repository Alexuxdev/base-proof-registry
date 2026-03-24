// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ProofRegistry {
    address public owner;

    event ProofAdded(address indexed user, string ipfsHash, uint256 timestamp);

    struct Proof {
        string ipfsHash;
        uint256 timestamp;
        address submitter;
    }

    mapping(address => Proof[]) public proofs;

    constructor() {
        owner = msg.sender;
    }

    function addProof(string memory _ipfsHash) public {
        proofs[msg.sender].push(
            Proof({
                ipfsHash: _ipfsHash,
                timestamp: block.timestamp,
                submitter: msg.sender
            })
        );

        emit ProofAdded(msg.sender, _ipfsHash, block.timestamp);
    }

    function getProofCount(address user) public view returns (uint256) {
        return proofs[user].length;
    }

    function getProof(address user, uint256 index) public view returns (
        string memory ipfsHash,
        uint256 timestamp,
        address submitter
    ) {
        Proof memory proof = proofs[user][index];
        return (proof.ipfsHash, proof.timestamp, proof.submitter);
    }
}
