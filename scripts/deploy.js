const main = async () => {
  const domainContractFactory = await hre.ethers.getContractFactory('Domains');
  const domainContract = await domainContractFactory.deploy("berserk");
  await domainContract.deployed();

  console.log("Contract deployed to:", domainContract.address);

  let txn = await domainContract.register("guts", { value: hre.ethers.utils.parseEther('1') });
  await txn.wait();
  console.log("Minted domain guts.berserk");

  txn = await domainContract.setRecord("guts", "I am Guts! I am the one who kills the ninjas!");
  await txn.wait();
  console.log("Set record for guts.berserk");

  const address = await domainContract.getAddress("guts");
  console.log("Owner of domain guts:", address);

  const balance = await hre.ethers.provider.getBalance(domainContract.address);
  console.log("Contract balance:", hre.ethers.utils.formatEther(balance));
}

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();