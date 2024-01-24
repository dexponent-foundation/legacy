const hre = require("hardhat");

async function main() {
    const CLETH = await hre.ethers.getContractFactory("CLETH");
    const cleth = await CLETH.deploy();

    await cleth.deployed();

    console.log("CLETH deployed to:", cleth.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
