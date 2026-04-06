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

## Asset lifecycle

A typical asset flow looks like this:

1. An admin registers an original asset with:
   - asset id
   - canonical hash
   - metadata URI

2. The original asset becomes the root of its own lineage.

3. A derivative asset can be registered later:
   - with a new asset id
   - with a new canonical hash
   - linked to an existing parent asset

4. The derivative inherits the same root asset id from its lineage origin.

5. Asset ownership can be transferred to another address.

6. Metadata URI can be updated when the asset stays active.

7. An asset may be revoked, which blocks state-changing operations tied to that asset.

## License workflow

A typical license flow looks like this:

1. An asset must already exist in the registry.

2. An admin issues a license with:
   - license id
   - linked asset id
   - licensee address
   - terms URI or terms label

3. The license is stored and linked back to the asset.

4. License activity depends on:
   - the license being issued
   - the license not being revoked
   - the linked asset still existing
   - the linked asset not being revoked

5. A license can be revoked by an authorized sender.

6. If license terms are marked as `exclusive`, the registry blocks creation of another exclusive license for the same asset.

## Project Structure

- `contracts/` — smart contracts
- `scripts/` — deployment scripts
- `test/` — automated tests

## Development

Install dependencies:

```bash
npm install
