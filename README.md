# BaseProofRegistry

BaseProofRegistry is a Solidity smart contract for registering original and derivative digital assets, tracking provenance, and issuing licenses.

## Features

- register original assets onchain
- register derivative assets linked to a parent
- preserve root and parent lineage
- enforce canonical hash uniqueness
- update asset ownership
- update asset metadata URI
- revoke and restore assets
- issue licenses for registered assets
- revoke issued licenses
- enforce a simple exclusive license rule
- verify canonical hashes
- fetch children of a parent asset
- fetch licenses linked to an asset
- check whether a license is currently active

## Project Structure

- `contracts/` — smart contracts
- `scripts/` — deployment scripts
- `test/` — automated tests

## Development

Install dependencies:

```bash
npm install
