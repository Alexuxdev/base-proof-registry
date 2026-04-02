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
});
