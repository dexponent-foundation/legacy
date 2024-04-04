// Import necessary dependencies and libraries
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deployProxy } = require("./utils");
const { NULL_ADDRESS } = require("./constants");


describe("CLETH", function () {
  let CLETH;
  let cLETH;
  let deployer;
  let stakingMaster;
  let accounts;

  before(async function () {
    [deployer, stakingMaster, ...accounts] = await ethers.getSigners();
    [deployer, dexAdmin, ...accounts] = await ethers.getSigners();
    cLETH = await deployProxy("CLETH", stakingMaster, "TokenProxy")
  });
  it("should deploy the CLETH contract should be reverted as the address is zero", async function () {
     expect(cLETH.initialize(NULL_ADDRESS,stakingMaster.address)).to.be.revertedWith("Address can not be zero")
 });
 it("should deploy the CLETH contract should be reverted as the address is zero", async function () {
   expect(cLETH.initialize(stakingMaster.address,NULL_ADDRESS)).to.be.revertedWith("Address can not be zero")
});
  it("should deploy the CLETH contract", async function () {
     await cLETH.initialize(stakingMaster.address,stakingMaster.address)
  });

  it("should deploy the CLETH contract", async function () {
    expect(cLETH.address).to.not.equal(0);
  });
  it("should revert if initialize is called more than once", async function () {
    await expect(
      cLETH.initialize(stakingMaster.address, deployer.address)
    ).to.be.revertedWith("InvalidInitialization");
  });
  it("should mint cLETH tokens", async function () {
    const amountToMint = ethers.utils.parseEther("100");
     expect(cLETH.connect(stakingMaster).mint(accounts[0].address, amountToMint)).to.emit(cLETH,"clethMinted");
    expect(await cLETH.balanceOf(accounts[0].address)).to.equal(amountToMint);
  });
  it("should mint cLETH tokens should be reverted as the caller is not owner", async function () {
    const amountToMint = ethers.utils.parseEther("100");
     expect(cLETH.connect(deployer).mint(accounts[0].address, amountToMint)).to.be.reverted;
  });
  it("should burn cLETH tokens", async function () {
    const amountToBurn = ethers.utils.parseEther("100");
     expect(cLETH.connect(stakingMaster).burnFrom(accounts[0].address, amountToBurn)).to.be.reverted;
  });
  it("should approve cLETH tokens", async function () {
    const amountToBurn = ethers.utils.parseEther("100");
    await cLETH.connect(accounts[0]).approve(stakingMaster.address, amountToBurn);
  });
  it("should burn cLETH tokens", async function () {
    const amountToBurn = ethers.utils.parseEther("100");
    await cLETH.connect(stakingMaster).burnFrom(accounts[0].address, amountToBurn);

    expect(await cLETH.balanceOf(accounts[0].address)).to.equal(ethers.utils.parseEther("0"));
  });
  it("should burn cLETH tokens reverted as the caller dont have role ", async function () {
    const amountToBurn = ethers.utils.parseEther("100");
    expect( cLETH.connect(deployer).burnFrom(accounts[0].address, amountToBurn)).to.be.reverted;
  });
  it("should pause and unpause contract", async function () {
    await cLETH.connect(stakingMaster).pause();
    expect(await cLETH.paused()).to.equal(true);

    await cLETH.connect(stakingMaster).unpause();
    expect(await cLETH.paused()).to.equal(false);
  });
  it("should pause and unpause contract should be reverted as the caller is not owner", async function () {
    expect(cLETH.connect(deployer).pause()).to.be.reverted;
    expect(cLETH.connect(deployer).unpause()).to.be.reverted;
   
  });
  it("should revert if account is zero address", async function () {
    // Attempt to burn tokens from zero address

    await expect(
      cLETH.connect(stakingMaster).burnFrom(ethers.constants.AddressZero, ethers.utils.parseEther("50"))
    ).to.be.revertedWith("ERC20: burn amount exceeds allowance");
  });
  
  it("should revert if amount is zero", async function () {
    await expect(
      cLETH.connect(stakingMaster).burnFrom(accounts[0].address, ethers.utils.parseEther("0"))
    ).to.be.revertedWith("Amount cannot be zero");
  });

  it("should revert if mint amount is zero", async function () {

    await expect(
      cLETH.connect(stakingMaster).mint(accounts[0].address, ethers.utils.parseEther("0"))
    ).to.be.revertedWith("Amount cannot be zero");
  });
  
  it("should revert if mint destination address is zero address", async function () {
    await expect(
      cLETH.connect(stakingMaster).mint(ethers.constants.AddressZero, ethers.utils.parseEther("50"))
    ).to.be.revertedWith("ERC20InvalidReceiver");
  });
  it("should revert if caller is not the owner (pause)", async function () {
    // Attempt to pause the contract with an account that is not the owner
    await expect(
      cLETH.connect(accounts[1]).pause()
    ).to.be.revertedWith("OwnableUnauthorizedAccount");
  });
  
  it("should revert if caller is not the owner (unpause)", async function () {
    // Attempt to unpause the contract with an account that is not the owner
    await expect(
      cLETH.connect(accounts[1]).unpause()
    ).to.be.revertedWith("OwnableUnauthorizedAccount");
  });
});