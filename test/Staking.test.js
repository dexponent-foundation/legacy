const { expect } = require("chai");
const { ethers } = require("hardhat");
// deploy clMAtic 
// deploy stakingMaster
// stake on contract
describe("StakingMaster Contract", function () {
    let CLETH, cleth, StakingMaster, stakingMaster, owner, addr1, addr2, blacklistedUser, unknownUser;

    before(async () => {
        CLETH = await ethers.getContractFactory("CLMatic");
        cleth = await CLETH.deploy();
        StakingMaster = await ethers.getContractFactory("StakingMaster");
        stakingMaster = await StakingMaster.deploy(cleth.address);
        [owner, addr1, addr2, blacklistedUser, unknownUser, ...addrs] = await ethers.getSigners();
        // await stakingMaster.addToBlacklist(blacklistedUser.address, { from: owner.address });
    });

    it("Should prevent a blacklisted user from staking", async () => {
        await expect(stakingMaster.connect(blacklistedUser).stake({ value: ethers.utils.parseEther("1") }))
            .to.be.revertedWith("User is blacklisted");
    });

    it("Should prevent an unknown user from unstaking", async () => {
        // Assuming the unknown user has staked 1 ETH before
        await stakingMaster.connect(unknownUser).stake({ value: ethers.utils.parseEther("1") });
        await expect(stakingMaster.connect(unknownUser).unstake(ethers.utils.parseEther("1")))
            .to.be.revertedWith("User is not whitelisted");
    });
});
