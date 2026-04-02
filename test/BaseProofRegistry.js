const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("BaseProofRegistry", function () {
  async function deployRegistryFixture() {
    const [owner, operator, other] = await ethers.getSigners();

    const BaseProofRegistry = await ethers.getContractFactory("BaseProofRegistry");
    const registry = await BaseProofRegistry.deploy();
    await registry.waitForDeployment();

    return { registry, owner, operator, other };
  }

  it("should deploy the registry fixture", async function () {
    const { registry, owner } = await loadFixture(deployRegistryFixture);

    expect(await registry.owner()).to.equal(owner.address);
    expect(await registry.paused()).to.equal(false);
  });

  it("should register an original asset", async function () {
    const { registry, owner } = await loadFixture(deployRegistryFixture);

    const assetId = ethers.id("asset-1");
    const canonicalHash = ethers.id("hash-1");
    const metadataURI = "ipfs://asset-1";

    await registry.registerOriginal(assetId, canonicalHash, metadataURI);

    const asset = await registry.getAsset(assetId);

    expect(asset[0]).to.equal(assetId);
    expect(asset[1]).to.equal(canonicalHash);
    expect(asset[2]).to.equal(assetId);
    expect(asset[3]).to.equal(ethers.ZeroHash);
    expect(asset[4]).to.equal(metadataURI);
    expect(asset[5]).to.equal(owner.address);
    expect(asset[7]).to.equal(false);
    expect(asset[8]).to.equal(true);

    expect(await registry.isCanonicalHashUsed(canonicalHash)).to.equal(true);
  });

  it("should reject duplicate canonical hash", async function () {
    const { registry } = await loadFixture(deployRegistryFixture);

    const assetId1 = ethers.id("asset-1");
    const assetId2 = ethers.id("asset-2");
    const canonicalHash = ethers.id("same-hash");

    await registry.registerOriginal(assetId1, canonicalHash, "ipfs://asset-1");

    await expect(
      registry.registerOriginal(assetId2, canonicalHash, "ipfs://asset-2")
    ).to.be.revertedWith("Canonical hash already used");
  });

  it("should register a derivative asset", async function () {
    const { registry, owner } = await loadFixture(deployRegistryFixture);

    const parentAssetId = ethers.id("parent-asset");
    const parentHash = ethers.id("parent-hash");
    const parentURI = "ipfs://parent";

    await registry.registerOriginal(parentAssetId, parentHash, parentURI);

    const derivativeAssetId = ethers.id("derivative-asset");
    const derivativeHash = ethers.id("derivative-hash");
    const derivativeURI = "ipfs://derivative";

    await registry.registerDerivative(
      derivativeAssetId,
      derivativeHash,
      parentAssetId,
      derivativeURI
    );

    const asset = await registry.getAsset(derivativeAssetId);

    expect(asset[0]).to.equal(derivativeAssetId);
    expect(asset[1]).to.equal(derivativeHash);
    expect(asset[2]).to.equal(parentAssetId);
    expect(asset[3]).to.equal(parentAssetId);
    expect(asset[4]).to.equal(derivativeURI);
    expect(asset[5]).to.equal(owner.address);
    expect(asset[7]).to.equal(false);
    expect(asset[8]).to.equal(true);

    const children = await registry.getChildren(parentAssetId);
    expect(children.length).to.equal(1);
    expect(children[0]).to.equal(derivativeAssetId);
  });

  it("should transfer asset ownership", async function () {
    const { registry, owner, other } = await loadFixture(deployRegistryFixture);

    const assetId = ethers.id("transfer-asset");
    const canonicalHash = ethers.id("transfer-hash");
    const metadataURI = "ipfs://transfer";

    await registry.registerOriginal(assetId, canonicalHash, metadataURI);

    await registry.transferAssetOwnership(assetId, other.address);

    const asset = await registry.getAsset(assetId);
    expect(asset[5]).to.equal(other.address);

    await expect(
      registry.connect(owner).transferAssetOwnership(assetId, owner.address)
    ).to.be.revertedWith("Not authorized");
  });
});
