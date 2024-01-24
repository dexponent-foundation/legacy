const hre = require("hardhat");

async function main() {
    const clethAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Replace with the deployed CLETH contract address

    const StakingMaster = await hre.ethers.getContractFactory("StakingMaster");
    const stakingMaster = await StakingMaster.deploy(clethAddress);

    await stakingMaster.deployed();

    console.log("StakingMaster deployed to:", stakingMaster.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
