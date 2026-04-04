async function main() {
  const BaseProofRegistry = await ethers.getContractFactory("BaseProofRegistry");
  const registry = await BaseProofRegistry.deploy();

  await registry.waitForDeployment();

  console.log("BaseProofRegistry deployed to:", await registry.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
