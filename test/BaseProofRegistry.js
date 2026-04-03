const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("BaseProofRegistry", function () {
  async function deployRegistryFixture() {
    const [owner, operator, other] = await ethers.getSigners();

    const BaseProofRegistry = await ethers.getContractFactory("BaseProofRegistry");
    const registry = await BaseProofRegistry.deploy();
    await registry.waitForDeployment();

    const ids = {
      asset1: ethers.id("asset-1"),
      asset2: ethers.id("asset-2"),
      parentAsset: ethers.id("parent-asset"),
      derivativeAsset: ethers.id("derivative-asset"),
      transferAsset: ethers.id("transfer-asset"),
      updateAsset: ethers.id("update-asset"),
    };

    const hashes = {
      hash1: ethers.id("hash-1"),
      sameHash: ethers.id("same-hash"),
      parentHash: ethers.id("parent-hash"),
      derivativeHash: ethers.id("derivative-hash"),
      transferHash: ethers.id("transfer-hash"),
      updateHash: ethers.id("update-hash"),
    };

    const uris = {
      asset1: "ipfs://asset-1",
      asset2: "ipfs://asset-2",
      parent: "ipfs://parent",
      derivative: "ipfs://derivative",
      transfer: "ipfs://transfer",
      update: "ipfs://update",
      updated: "ipfs://updated",
    };

    return { registry, owner, operator, other, ids, hashes, uris };
  }

  it("should deploy the registry fixture", async function () {
    const { registry, owner } = await loadFixture(deployRegistryFixture);

    expect(await registry.owner()).to.equal(owner.address);
    expect(await registry.paused()).to.equal(false);
  });

  it("should register an original asset", async function () {
    const { registry, owner, ids, hashes, uris } = await loadFixture(deployRegistryFixture);

    await registry.registerOriginal(ids.asset1, hashes.hash1, uris.asset1);

    const asset = await registry.getAsset(ids.asset1);

    expect(asset[0]).to.equal(ids.asset1);
    expect(asset[1]).to.equal(hashes.hash1);
    expect(asset[2]).to.equal(ids.asset1);
    expect(asset[3]).to.equal(ethers.ZeroHash);
    expect(asset[4]).to.equal(uris.asset1);
    expect(asset[5]).to.equal(owner.address);
    expect(asset[7]).to.equal(false);
    expect(asset[8]).to.equal(true);

    expect(await registry.isCanonicalHashUsed(hashes.hash1)).to.equal(true);
  });

  it("should reject duplicate canonical hash", async function () {
    const { registry, ids, hashes, uris } = await loadFixture(deployRegistryFixture);

    await registry.registerOriginal(ids.asset1, hashes.sameHash, uris.asset1);

    await expect(
      registry.registerOriginal(ids.asset2, hashes.sameHash, uris.asset2)
    ).to.be.revertedWith("Canonical hash already used");
  });

  it("should register a derivative asset", async function () {
    const { registry, owner, ids, hashes, uris } = await loadFixture(deployRegistryFixture);

    await registry.registerOriginal(ids.parentAsset, hashes.parentHash, uris.parent);

    await registry.registerDerivative(
      ids.derivativeAsset,
      hashes.derivativeHash,
      ids.parentAsset,
      uris.derivative
    );

    const asset = await registry.getAsset(ids.derivativeAsset);

    expect(asset[0]).to.equal(ids.derivativeAsset);
    expect(asset[1]).to.equal(hashes.derivativeHash);
    expect(asset[2]).to.equal(ids.parentAsset);
    expect(asset[3]).to.equal(ids.parentAsset);
    expect(asset[4]).to.equal(uris.derivative);
    expect(asset[5]).to.equal(owner.address);
    expect(asset[7]).to.equal(false);
    expect(asset[8]).to.equal(true);

    const children = await registry.getChildren(ids.parentAsset);
    expect(children.length).to.equal(1);
    expect(children[0]).to.equal(ids.derivativeAsset);
  });

  it("should transfer asset ownership", async function () {
    const { registry, owner, other, ids, hashes, uris } = await loadFixture(deployRegistryFixture);

    await registry.registerOriginal(ids.transferAsset, hashes.transferHash, uris.transfer);

    await registry.transferAssetOwnership(ids.transferAsset, other.address);

    const asset = await registry.getAsset(ids.transferAsset);
    expect(asset[5]).to.equal(other.address);

    await expect(
      registry.connect(owner).transferAssetOwnership(ids.transferAsset, owner.address)
    ).to.be.revertedWith("Not authorized");
  });

  it("should reject unauthorized ownership transfer", async function () {
    const { registry, other, ids, hashes, uris } = await loadFixture(deployRegistryFixture);

    await registry.registerOriginal(ids.transferAsset, hashes.transferHash, uris.transfer);

    await expect(
      registry.connect(other).transferAssetOwnership(ids.transferAsset, other.address)
    ).to.be.revertedWith("Not authorized");
  });

  it("should update asset uri", async function () {
    const { registry, ids, hashes, uris } = await loadFixture(deployRegistryFixture);

    await registry.registerOriginal(ids.updateAsset, hashes.updateHash, uris.update);
    await registry.updateAssetURI(ids.updateAsset, uris.updated);

    const asset = await registry.getAsset(ids.updateAsset);
    expect(asset[4]).to.equal(uris.updated);
  });
});
