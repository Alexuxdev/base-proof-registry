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

## Architecture

The contract is centered around two main entities:

### Asset

An asset stores:
- unique asset identifier
- canonical content hash
- root asset identifier
- parent asset identifier
- metadata URI
- current registrant
- creation timestamp
- revoked status
- existence flag

### License

A license stores:
- unique license identifier
- linked asset identifier
- licensee address
- terms URI or terms label
- creation timestamp

### Core storage mappings

The registry keeps:
- asset records by asset id
- canonical hash usage tracking
- children grouped by parent asset
- license records by license id
- license issuer tracking
- asset to license lists
- exclusive license flags
- revoked license flags

## Project Structure

- `contracts/` — smart contracts
- `scripts/` — deployment scripts
- `test/` — automated tests

## Development

Install dependencies:

```bash
npm install
