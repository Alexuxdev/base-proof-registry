const hre = require("hardhat");

async function main() {
  const BaseProofRegistry = await hre.ethers.getContractFactory("BaseProofRegistry");
  const registry = await BaseProofRegistry.deploy();

  await registry.waitForDeployment();

  const address = await registry.getAddress();
  console.log("BaseProofRegistry deployed to:", address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
