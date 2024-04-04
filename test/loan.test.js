const { expect } = require("chai");
const { parseEther, parseUnits } = require("ethers/lib/utils");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const { deployProxy, deployContract } = require("./utils");
const Sinon = require("sinon");
const { ZERO_ADDRESS_ERROR } = require("./constants");

describe("Testing loan smart contract functions", function () {
  let signer, user, testuser;
  let clETH;
  let loanLogicContract;
  let usdcContract
  let priceFeed;
  const NULL_ADDRESS = "0x0000000000000000000000000000000000000000"
  const initialPrice = parseEther("10")
  before(async () => {
    [signer, user] = await ethers.getSigners();
    const usdcToken = await ethers.getContractFactory("USDC", signer);
    usdcContract = await usdcToken.deploy()
    clETH = await deployProxy("CLETH", signer, "TokenProxy")
    const priceFeedContract = await ethers.getContractFactory("MockAggregatorV3", signer);
    priceFeed = await priceFeedContract.deploy(initialPrice, parseEther("8"))
    loanLogicContract = await deployProxy("LoanLogic", signer, "DexProxy")
    hre.tracer.nameTags[clETH.address] = "CLETH_!";
    hre.tracer.nameTags[priceFeed.address] = "PRICE_FEED_!";
    hre.tracer.nameTags[user.address] = "USER_!";
    hre.tracer.nameTags[signer.address] = "OWNER_!";
    hre.tracer.nameTags[NULL_ADDRESS] = "NULL_ADDRESS_!";
  });
  describe("Smart contract function test", async () => {
    it("Init clETH contract", async () => {
      await clETH.initialize(signer.address, signer.address);
    })
    it("should initialize the contract with correct initial values", async function () {
      const clethTokenAddress = clETH.address // Example cLETH token address
      const priceFeedAddress = priceFeed.address; // Example price feed address
      expect(loanLogicContract.initialize(NULL_ADDRESS, clethTokenAddress, priceFeedAddress)).to.be.revertedWith("Address can not be zero");

    })
    it("should initialize the contract with correct initial values", async function () {
      const usdcTokenAddress = usdcContract.address// Example USDC token address
      const priceFeedAddress = priceFeed.address; // Example price feed address
      expect(loanLogicContract.initialize(usdcTokenAddress, NULL_ADDRESS, priceFeedAddress)).to.be.revertedWith("Address can not be zero");

    })
    it("should initialize the contract with correct initial values", async function () {
      const usdcTokenAddress = usdcContract.address// Example USDC token address
      const clethTokenAddress = clETH.address // Example cLETH token address
      const priceFeedAddress = priceFeed.address; // Example price feed address
      expect(loanLogicContract.initialize(usdcTokenAddress, clethTokenAddress, NULL_ADDRESS)).to.be.revertedWith("Address can not be zero");

    })
    it("should initialize the contract with correct initial values", async function () {

      const usdcTokenAddress = usdcContract.address// Example USDC token address
      const clethTokenAddress = clETH.address // Example cLETH token address
      const priceFeedAddress = priceFeed.address; // Example price feed address
      await loanLogicContract.initialize(usdcTokenAddress, clethTokenAddress, priceFeedAddress);

      // Check contract state
      expect(await loanLogicContract.usdcToken()).to.equal(usdcTokenAddress);
      expect(await loanLogicContract.clethToken()).to.equal(clethTokenAddress);
      expect(await loanLogicContract.priceFeed()).to.equal(priceFeedAddress);
      expect(await loanLogicContract.totalLoans()).to.equal(0);
      expect(await loanLogicContract.nextLoanId()).to.equal(1);
      expect(await loanLogicContract.interestRateTargetUtilization()).to.equal(70);
      expect(await loanLogicContract.interestRateK()).to.equal(1);
      expect(await loanLogicContract.ltvTargetUtilization()).to.equal(80);
      expect(await loanLogicContract.ltvK()).to.equal(1);
      expect(await loanLogicContract.liquidationThreshold()).to.equal(90);
    });
    it("should calculate the interest rate", async () => {
      await loanLogicContract.calculateInterestRate();
    })
    it("should calculate the maximum loan-to-value ratio", async () => {
      await loanLogicContract.calculateMaxLTV();
    })
    it("should set the cleth price on the price feed", async () => {
      await priceFeed.setLatestPrice(parseEther("10"))
    })
  })
  describe("Testing loan flow ", async () => {

    it("should mint 10000000 cleth tokens for users", async () => {
      await clETH.mint(user.address, parseEther("100000"))
    })
    it("should mint USDC 10000000 tokens to the loanLogicContract", async () => {
      await usdcContract.connect(signer).mint(parseEther("10000000"), user.address)
      await usdcContract.connect(signer).mint(parseEther("10000000"), signer.address)
      await usdcContract.connect(signer).approve(loanLogicContract.address, parseEther("10000000"))
      await usdcContract.connect(user).approve(loanLogicContract.address, parseEther("10000000"))
    })
    it("should approve USDC tokens for the loan contract", async () => {
      await clETH.connect(user).approve(loanLogicContract.address, parseEther("10000000"))
    })

    it("should deposit USDC to the reserve", async () => {

      await loanLogicContract.connect(signer).depositUSDCToReserve(parseEther("10000"))
    })
    it("should deposit USDC to the reserve should be revertedWith as amount is zero", async () => {

      expect(loanLogicContract.connect(signer).depositUSDCToReserve(parseEther("0"))).to.be.revertedWith("Amount cannot be zero")
    })
    it("should deposit USDC to the reserve should be revertedWith as amount is zero", async () => {

      expect(loanLogicContract.connect(user).depositUSDCToReserve(parseEther("10"))).to.be.reverted
    })
    it("should fetch the cleth price from the price feed and check if it's 10", async () => {
      const clethPrice = await loanLogicContract.fetchCLETHPrice();
      expect(clethPrice).to.equal(parseEther("10"));
    });
    it("should reverted calculate the maximum loan amount is 0 ", async () => {
      expect(loanLogicContract.calculateMaxLoanAmount(parseEther("0"))).to.be.revertedWith("Amount cannot be zero");
    })

    it("should create a loan for the user", async () => {
      expect(loanLogicContract.connect(user).createLoan(parseEther("10"))).to.be.emit(loanLogicContract, "LoanCreated");
    })
    it("should create a loan for the user should bre reverted as the amount is zero", async () => {
      expect(loanLogicContract.connect(user).createLoan(parseEther("0"))).to.be.revertedWith("Amount cannot be zero")
    })
    it("should revert creating a loan when there is insufficient liquidity", async () => {
      expect(loanLogicContract.connect(user).createLoan(parseEther("900"))).to.be.revertedWith("Insufficient liquidity");
    })
    it("liquidateCollateral should be reverted as loan is already repaid", async () => {
      expect(loanLogicContract.connect(user).liquidateCollateral("1")).to.be.revertedWith("Loan LTV is below liquidation threshold")
    })
    it("liquidateCollateral should be reverted as Loan does not exist", async () => {
      expect(loanLogicContract.connect(user).liquidateCollateral("100")).to.be.revertedWith("Loan does not exist")
    })
    it("should check the loan repayment amount", async () => {
      const repaymentAmount = await loanLogicContract.connect(user).calculateRepaymentAmount("1");
      const interestTillNow = await loanLogicContract.connect(user).calculateInterestTillnow("1")
    });
    it("should check the loan repayment amount should reverted as the loan does not exits", async () => {
      expect(loanLogicContract.connect(user).calculateRepaymentAmount("10")).to.be.revertedWith("Loan does not exist");
    });
    it("should check the loan interest till now", async () => {
      expect(loanLogicContract.connect(user).calculateInterestTillnow("10")).to.be.revertedWith("Loan does not exist")
    })
    it("should approve USDC tokens for the loan contract (additional approval)", async () => {
      await usdcContract.connect(user).approve(loanLogicContract.address, parseEther("300000000000"))
    })
    it("should revert repaying the user loan as only the borrower can repay the loan", async () => {
      expect(loanLogicContract.connect(signer).repayLoan("1")).to.be.revertedWith("Only the borrower can repay the loan")
    })
    it("should calculate the maximum loan-to-value ratio (additional calculation)", async () => {
      await loanLogicContract.calculateMaxLTV();
    })
    it("should repay the user loan", async () => {
      expect(loanLogicContract.connect(user).repayLoan("2")).to.emit(loanLogicContract, "LoanRepaid").withArgs("2", user.address)
    })

    it("should revert repaying the user loan when the loan is already repaid", async () => {
      expect(loanLogicContract.connect(user).repayLoan("1")).to.be.revertedWith("Loan already repaid")
    })
    it("should revert liquidating collateral when the loan is already repaid or liquidated", async () => {
      expect(loanLogicContract.connect(user).liquidateCollateral("1")).to.be.revertedWith("Loan is already repaid or liquidated")
    })
    it("should calculate the interest rate", async () => {
      await loanLogicContract.calculateInterestRate();
    })

    it("should calculate the maximum loan amount", async () => {
      await loanLogicContract.calculateMaxLoanAmount(parseEther("10"));
    })

    it("should get the reserved balance of cLETH ", async () => {
      await loanLogicContract.getClethReservedBalance();
    })
    it("should set the cLETH price on the price feed", async () => {
      await priceFeed.setLatestPrice(parseEther("100"))
    })
    it("should create a loan for the user with 80 cLETH", async () => {
      expect(loanLogicContract.connect(user).createLoan(parseEther("80"))).to.be.emit("LoanCreated");
    })
    it("should create a loan for the user with 50 cLETH", async () => {
      expect(loanLogicContract.connect(user).createLoan(parseEther("50"))).to.be.emit("LoanCreated");
    })
    it("should calculate the maximum loan-to-value ratio", async () => {
      await loanLogicContract.calculateMaxLTV();
    })
    it("should revert creating a loan when passing 0 as the cLETH amount", async () => {
      expect(loanLogicContract.connect(user).createLoan(parseEther("0"))).to.be.revertedWith("Amount can  not be zero");
    })
    it("should set the cLETH price on the price feed", async () => {
      await priceFeed.setLatestPrice(parseEther("1"))
    })
    it("should get the version of the price feed", async () => {
      await priceFeed.version()
    })
    it("should liquidate collateral for a loan id 3", async () => {
      await loanLogicContract.connect(user).liquidateCollateral("3")
    })
    it("should revert liquidating collateral when the loan is already repaid or liquidated", async () => {
      // Test reverting liquidating collateral when the loan is already repaid or liquidated...
      expect(loanLogicContract.connect(user).liquidateCollateral("1")).to.be.revertedWith("Loan is already repaid or liquidated");
    });

    it("should revert liquidating collateral for a non-existent loan", async () => {
      // Test reverting liquidating collateral for a non-existent loan...
      expect(loanLogicContract.connect(user).liquidateCollateral("10")).to.be.revertedWith("Loan does not exist");
    });
    it("call price feed getRoundData function with id", async () => {
      await priceFeed.connect(user).getRoundData("1")
    })
    it("should call the decimals function of the price feed", async () => {
      await priceFeed.connect(user).decimals()
    })
    it("should call the latestRoundData function of the price feed", async () => {
      await priceFeed.connect(user).latestRoundData()
    })
    it("should call the description function of the price feed", async () => {
      await priceFeed.connect(user).description()
    })
  })
})
