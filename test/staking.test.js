const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");

const erc20_abi =  require("./utils/ERC20.json");

  ribe("StakingMaster Contract", function () {
    
    ETH,
    h,
    ingMaster,
    ingMaster,
  matics,
  owner,provider
  const ValidaotrAddress = "0x2B37b02c20bD5B180dbE5b39892d5e0187b06537"
    const StakeManager= "0x00200eA4Ee292E253E6Ca07dBA5EdC07c8Aa37A3"
  const TestMAtic = "0x499d11E0b6eAC7c0593d8Fb292DCBbF815Fb29Ae"
    
    (async () => {
    r = await ethers.getImpersonatedSigner("0x56c243BD5B43A84dAb5dF3C4Bc0a61256C2Acf1e");
    ider = ethers.provider
    H = await ethers.getContractFactory("CLMatic");
    h = await CLETH.deploy();
    ingMaster = await ethers.getContractFactory("StakingMaster");
    ingMaster = await StakingMaster.deploy(cleth.address,TestMAtic);
    ole.log(stakingMaster.address)
    atics = await ethers.Contract(TestMAtic, erc20ABI.abi);
    tracer.nameTags[cleth.address] = "CMATIC";
    tracer.nameTags[stakingMaster.address] = "STAKING MASTER";
    hre.tracer.nameTags[ValidaotrAddress] = "ValidatoreAddress";
    tracer.nameTags[StakeManager] = "StakeManager";
    hre.tracer.nameTags[TestMAtic] = "Matic";
  hre.tracer.nameTags[owner.address] = "Owner";

  ;
    proving USDC for 1st contract",async()=>{
  const tokenContract0 = new ethers.Contract(
      TestMAtic,
    erc20_abi.abi, 
    ovider
      
        
        alResponse = await tokenContract0.connect(owner).approve(
    akingMaster.address,
  ethers.utils.parseEther('10000')
    )
  t tokenContract0.connect(owner).approve(
    "0x0e32f852dce23407e35b356c8726a3206c3c176d",
  ethers.utils.parseEther('10000')
  )
  })
  ("grant role to staking master", async()=>{
  await cleth.grantRoles(stakingMaster.address)
  
  ("approve  MAtic to staking master", async () => {
  await stakingMaster.connect(owner).aprove(ethers.utils.parseEther("1000"),"0x00200eA4Ee292E253E6Ca07dBA5EdC07c8Aa37A3")
  ;
  ("Stake to staking master", async () => {
  await expect(
    stakingMaster
      .connect(owner)
      .stake(ethers.utils.parseEther("1"),ValidaotrAddress)
  ).emit(StakingMaster, "Staked");
  ;
  
   it("Deposit to staking master", async () => {
     await stakingMaster
         .connect(owner)
         .deposit(ethers.utils.parseEther("1"))
  
  // });
  it("Staker should recived 1 CLMatic", async () => {
   // console.log(owner)
const balance = await cleth.balanceOf(owner.address);
console.log("user balance clMAtic", balance);
;
("approve  ClMAtic to staking master", async () => {
await cleth.connect(owner).approve(stakingMaster.address,ethers.utils.parseEther("10000"))
;
("User should be able to unstake the ClMAtic", async () => {
    await expect(
      stakingMaster.connect(owner).unstake(ethers.utils.parseEther("1"),ValidaotrAddress)
  ).emit(stakingMaster, "Unstaked");    
  ;
    CLmatic should be burned after unstake", async () => {
     console.log(oner)
    nst balance = await cleth.balanceOf(owner.address);
  console.log("user balance clMAtic", balance);
;
  
    
