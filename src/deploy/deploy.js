
const {ethers}  = require("hardhat")
const verifyContract = async (
  hre,
  contractAddress ,
  constructorArgsParams
) => {
  try {
    await hre.run("verify", {
      address: contractAddress,
      constructorArgsParams: constructorArgsParams,
    });
  } catch (error) {
    console.log(error);
    console.log(
      `Smart contract at address ${contractAddress} is already verified`
    );
  }
};
async function deployDiamond () {
  const accounts = await ethers.getSigners()
  const clMatic = await ethers.getContractFactory('CLMatic')
  const clMatic_deployed = await clMatic.deploy()
  await clMatic_deployed.deployed()

  console.log('CLmatic deployed:', clMatic_deployed.address)
  const StakingMaster = await ethers.getContractFactory('StakingMaster')
  const StakingMaster_deployed = await StakingMaster.deploy(clMatic_deployed.address)
  await StakingMaster_deployed.deployed()
  console.log('Staking master deployed:', StakingMaster_deployed.address)
  await clMatic_deployed.grantRoles(StakingMaster_deployed.address);

  // Deploy facets and set the `facetCuts` variable
  console.log('Deploying facets')
  await verifyContract(hre,clMatic_deployed.address,[])
  await verifyContract(hre,StakingMaster_deployed.address,[clMatic_deployed.address])
  
}


if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamond = deployDiamond