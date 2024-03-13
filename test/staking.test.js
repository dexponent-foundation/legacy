const { expect } = require("chai");
const { Address } = require("ethereumjs-util");
const { parseEther } = require("ethers/lib/utils");
const { ethers } = require("hardhat");
const hre = require("hardhat");

async function sendETH(address, signer) {
  let amountToSend = parseEther('0.04'); // 0.1 ETH
  let tx = {
    to: address,
    value: amountToSend,
  };
 await signer.sendTransaction(tx);
}

describe("StakingMaster Contract", function () {
  let proxy;
  let signer, user;
  let clETH;
  let StakingMaster
  let stakingMasterProxy;
  const DEPOSIT_AMOUNT = parseEther("32")
  const WRONG_DEPOSIT_AMOUNT = parseEther("12")
  const REWARDS_AMOUNT = parseEther("0.02")
  const ONLY_OWNER_CAN_CALL = "Only the owner can call this function"
  const NOT_ENOUGH_STAKED_ETH = "Not enough staked ETH"
  const INSUFFICIENT_REWARDS =  "Insufficient Rewards to claim"
  const WITHDRAWAL_AMOUNT_IS_NOT_ENOUGH = "withdrawal amount is not enough"
  const NULL_ADDRESS = "0x0000000000000000000000000000000000000000"
  const ZERO_ADDRESS_ERROR ="Account is zero address"
  const UNAUTHORIZEDACCOUNT = "AccessControlUnauthorizedAccount"
  before(async () => {
    [signer, user] = await ethers.getSigners();
    const clETHInstance = await ethers.getContractFactory("CLETH", signer);
    clETH = await clETHInstance.deploy()
    const stakingMasterInstance = await ethers.getContractFactory("StakingMaster", signer);
    StakingMaster = await stakingMasterInstance.deploy()
    const proxyInstance = await ethers.getContractFactory("DexProxy", signer);
    proxy = await proxyInstance.deploy(StakingMaster.address, signer.address, "0x")
    stakingMasterProxy = await ethers.getContractAt("StakingMaster", proxy.address)
    hre.tracer.nameTags[proxy.address] = "PROXY_MSC_!";
    hre.tracer.nameTags[clETH.address] = "CLETH_!";
    hre.tracer.nameTags[user.address] = "USER_!";
    hre.tracer.nameTags[signer.address] = "OWNER_!";
    hre.tracer.nameTags[NULL_ADDRESS] = "NULL_ADDRESS_!";
  });

  describe("Smart contract function test", async () => {
    it("Init clETH contract", async () => {
      await clETH.initialize(signer.address);
    })
    it("Set impelemenation to proxy", async () => {
      await stakingMasterProxy.setUp(clETH.address,signer.address)
    })
    it("Greant role to staking master", async () => {
      await clETH.grantRoles(stakingMasterProxy.address)
    })
    it("Deposit 32ETH to smart contract", async () => {
      await stakingMasterProxy.connect(user).stake({ value: DEPOSIT_AMOUNT })
    })

    it("User cleth balance should be equal to 32 cleth", async () => {
      const userClethBalance = await clETH.balanceOf(user.address)
      expect(userClethBalance).to.be.equal(DEPOSIT_AMOUNT)
    })
    it("Deposit 12ETH to smart contract", async () => {
      expect(stakingMasterProxy.connect(user).stake({ value: WRONG_DEPOSIT_AMOUNT })).to.be.revertedWith("ETH MUST BE IN THE MUTLIPLE OF 32")
    })
  })
  describe("Rewards functions", async () => {
    it("Send 1 ETH to ISC", async () => {
      const userIscAddress = await stakingMasterProxy.StakeHolders(user.address)
      await sendETH(userIscAddress, signer)
    })
    it("Claim clETH rewards for users", async () => {
      await stakingMasterProxy.connect(signer).claimRewardForCleth(user.address,REWARDS_AMOUNT)
      result = await clETH.balanceOf(user.address)
      expect(result).to.be.equal("32020000000000000000")
    })
    it("Claim wclETH rewards for users", async () => {
      await stakingMasterProxy.claimRewardForWcleth(user.address,REWARDS_AMOUNT)
      const userIscAddress = await stakingMasterProxy.StakeHolders(user.address)
      const userClethBalance = await clETH.balanceOf(userIscAddress)
      expect(userClethBalance).to.be.equal(REWARDS_AMOUNT)
    })

    it(`Should be reverted with ${ONLY_OWNER_CAN_CALL}`, async () => { 
  const ONLY_OWNER_CAN_CALL = "Only the owner can call this function"
      expect(stakingMasterProxy.connect(user).claimRewardForWcleth(user.address,REWARDS_AMOUNT)).to.be.revertedWith(ONLY_OWNER_CAN_CALL);
    })
  })
  describe("Unstake flow",async()=>{
    it("Provide approval to Staking master",async()=>{
      await clETH.connect(user).approve(stakingMasterProxy.address,DEPOSIT_AMOUNT)
    })
    it("Unstake the staked Amount",async()=>{
      await stakingMasterProxy.connect(user).unstake(DEPOSIT_AMOUNT)
    })
    it(`Should be rejected with error ${NOT_ENOUGH_STAKED_ETH}`,async()=>{
      expect( stakingMasterProxy.connect(user).unstake(DEPOSIT_AMOUNT)).to.be.revertedWith(NOT_ENOUGH_STAKED_ETH)
    })
    it(`Should be reverted with ${WITHDRAWAL_AMOUNT_IS_NOT_ENOUGH}`,async()=>{
      expect(stakingMasterProxy.burnCleth(user.address,DEPOSIT_AMOUNT+DEPOSIT_AMOUNT)).to.be.revertedWith(WITHDRAWAL_AMOUNT_IS_NOT_ENOUGH)
   })
    it(`Should be reverted with ${ONLY_OWNER_CAN_CALL}`,async()=>{
       expect(stakingMasterProxy.connect(user).burnCleth(user.address,DEPOSIT_AMOUNT)).to.be.revertedWith(ONLY_OWNER_CAN_CALL)
    })
    it("Burn users cleth and give him his staked amount",async()=>{
      await stakingMasterProxy.burnCleth(user.address,DEPOSIT_AMOUNT)
    })
    it(`It should be reverted with ${INSUFFICIENT_REWARDS}`, async () => {
      expect( stakingMasterProxy.claimRewardForWcleth(user.address,REWARDS_AMOUNT)).to.be.revertedWith(INSUFFICIENT_REWARDS)
    })
    it(`It should be reverted with ${ZERO_ADDRESS_ERROR}`, async () => {
      expect( stakingMasterProxy.claimRewardForWcleth(NULL_ADDRESS,REWARDS_AMOUNT)).to.be.revertedWith(ZERO_ADDRESS_ERROR)
    })
    it(`It should be reverted with ${ZERO_ADDRESS_ERROR}`, async () => {
      expect (clETH.mint(user.address,REWARDS_AMOUNT)).to.be.revertedWith(UNAUTHORIZEDACCOUNT)
    })
  })
  
})