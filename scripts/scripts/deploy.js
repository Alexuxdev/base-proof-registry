async function main() {
  const BaseProofRegistry = await ethers.getContractFactory("BaseProofRegistry");
  const registry = await BaseProofRegistry.deploy();

  await registry.waitForDeployment();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
