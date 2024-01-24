const { expect } = require("chai");
const { ethers } = require("hardhat");
describe("StakingMaster Contract", function () {
  let CLETH,
    cleth,
    StakingMaster,
    stakingMaster,
    owner

  before(async () => {
    CLETH = await ethers.getContractFactory("CLMatic");
    cleth = await CLETH.deploy();
    StakingMaster = await ethers.getContractFactory("StakingMaster");
    stakingMaster = await StakingMaster.deploy(cleth.address);
    [owner,] = await ethers.getSigners();
    // await stakingMaster.addToBlacklist(blacklistedUser.address, { from: owner.address });
  });
  it("Greant role to Staking master to mint CLmatic", async () => {
    await cleth.grantRoles(stakingMaster.address);
    
  });
  it("Stake to staking master", async () => {
    await expect(
      stakingMaster
        .connect(owner)
        .stake({ value: ethers.utils.parseEther("1") })
    ).emit(StakingMaster, "Staked");
  });
  it("Staker should recived 1 CLMatic", async () => {
    // console.log(owner)
    const balance = await cleth.balanceOf(owner.address);
    console.log("user balance clMAtic", balance);
  });
  it("approve  ClMAtic to staking master", async () => {
    await cleth.connect(owner).approve(stakingMaster.address,ethers.utils.parseEther("10000"))
  });
  it("User should be able to unstake the ClMAtic", async () => {
    await expect(
      stakingMaster.connect(owner).unstake(ethers.utils.parseEther("1"))
    ).emit(stakingMaster, "Unstaked");
  });
  it("CLmatic should be burned after unstake", async () => {
    // console.log(owner)
    const balance = await cleth.balanceOf(owner.address);
    console.log("user balance clMAtic", balance);
  });
});
