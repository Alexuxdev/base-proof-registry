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
});
