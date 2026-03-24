# Base Proof Registry

A simple smart contract for storing proof records on Base-compatible EVM networks.

## Features

- store IPFS hash
- store timestamp
- link proof to sender wallet
- get total number of proofs by user
- get proof by index
- emit event when proof is added

## Contract methods

### addProof(string memory _ipfsHash)
Stores a new proof for the sender.

### getProofCount(address user)
Returns number of proofs submitted by a user.

### getProof(address user, uint256 index)
Returns proof data:
- ipfsHash
- timestamp
- submitter

## Stack

- Solidity
- Remix
- GitHub

## Purpose

Practice project for Base ecosystem development.
