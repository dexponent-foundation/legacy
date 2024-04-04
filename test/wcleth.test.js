const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deployProxy } = require("./utils");

describe("wclETH", function () {
  let wclETH;
  let deployer;
  let accounts;

  before(async function () {
    [deployer, ...accounts] = await ethers.getSigners();
    wclETH = await deployProxy("wclETH", deployer, "TokenProxy");
  });
  it("should deploy the CLETH contract", async function () {
    await wclETH.initialize("Wcleth","wcleth")
 });
  it("should deploy the wclETH contract", async function () {
    expect(wclETH.address).to.not.equal(0);
  });

  it("should mint wclETH tokens", async function () {
    const amountToMint = ethers.utils.parseEther("100");
    await wclETH.mint(accounts[0].address, amountToMint);

    expect(await wclETH.balanceOf(accounts[0].address)).to.equal(amountToMint);
  });
  it("should mint wclETH tokens should be reverted as the caller is not owner", async function () {
    const amountToMint = ethers.utils.parseEther("100");
    expect( wclETH.connect(accounts[0]).mint(accounts[0].address, amountToMint)).to.be.reverted;
  });


  it("should revert if mint amount is zero", async function () {
    await expect(
      wclETH.mint(accounts[0].address, ethers.utils.parseEther("0"))
    ).to.be.revertedWith("WCLETH: mint amount must be greater than zero");
  });

  it("should revert if mint destination address is zero address", async function () {
    await expect(
      wclETH.mint(ethers.constants.AddressZero, ethers.utils.parseEther("50"))
    ).to.be.revertedWith("Zero address");
  });

  it("should pause and unpause contract", async function () {
    await wclETH.pause();
    expect(await wclETH.paused()).to.equal(true);

    await wclETH.unpause();
    expect(await wclETH.paused()).to.equal(false);
  });

  it("should revert if caller is not the owner (pause)", async function () {
    await expect(
      wclETH.connect(accounts[1]).pause()
    ).to.be.revertedWith("OwnableUnauthorizedAccount");
  });

  it("should revert if caller is not the owner (unpause)", async function () {
    await expect(
      wclETH.connect(accounts[1]).unpause()
    ).to.be.revertedWith("OwnableUnauthorizedAccount");
  });
  it("should revert if unstake amount is zero", async function () {
    await expect(
      wclETH.unstake(ethers.utils.parseEther("0"), "0x")
    ).to.be.revertedWith("Amount cannot be zero");
  });
  it("should revert if pubkeys length is not 48 bytes", async function () {
    const amountToMint = ethers.utils.parseEther("32"); // Mint 32 wclETH tokens

    // Pubkeys length not equal to 48 bytes
    const invalidPubkeys = ethers.utils.hexlify(
      ethers.utils.randomBytes(40)
    );

    await expect(
      wclETH.unstake(amountToMint, invalidPubkeys)
    ).to.be.revertedWith("Length of pubkeys must be 48 bytes");
  });
  it("should revert if unstake amount is not equal to MIN_WITHDRAWAL_AMOUNT", async function () {
    const invalidAmount = ethers.utils.parseEther("30"); // Not equal to MIN_WITHDRAWAL_AMOUNT

    // Mock pubkeys (48 bytes)
    const pubkeys = ethers.utils.hexlify(
      ethers.utils.randomBytes(48)
    );

    await expect(
      wclETH.unstake(invalidAmount, pubkeys)
    ).to.be.revertedWith("Must sent 32 wclETH");
  });
  it("should pause and unpause contract should be reverted as the caller is not owner", async function () {
    expect(wclETH.connect(deployer).pause()).to.be.reverted;
    expect(wclETH.connect(deployer).unpause()).to.be.reverted;

  });
  it("should revert if contract is paused", async function () {
    const amountToMint = ethers.utils.parseEther("32"); // Mint 32 wclETH tokens

    // Mock pubkeys (48 bytes)
    const pubkeys = ethers.utils.hexlify(
      ethers.utils.randomBytes(48)
    );

    await wclETH.pause();

    await expect(
      wclETH.unstake(amountToMint, pubkeys)
    ).to.be.revertedWith("EnforcedPause");
  });

  
  it("should successfully pass all test cases", async function () {
    await wclETH.unpause();
    const amountToMint = ethers.utils.parseEther("32");
    await wclETH.mint(accounts[0].address, amountToMint);

    // Mock pubkeys (48 bytes)
    const pubkeys = ethers.utils.hexlify(
      ethers.utils.randomBytes(48)
    );

    // Unstake the tokens
    await expect(wclETH.connect(accounts[0]).unstake(amountToMint, pubkeys))
      .to.emit(wclETH, "unstakedRequested")
      .withArgs(accounts[0].address, amountToMint, pubkeys);
    })

});
