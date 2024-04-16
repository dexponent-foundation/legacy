const { expect } = require("chai");
const { parseEther, parseUnits } = require("ethers/lib/utils");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const { deployProxy, deployContract } = require("./utils");
const { ZERO_ADDRESS_ERROR } = require("./constants");

describe("Testing loan smart contract functions", function () {
  let signer, user, testuser,recoveryAddress;
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
    
    });
  
    it("should calculate the interest rate", async () => {
      await loanLogicContract.calculateInterestRate();
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
    it("should calculate the interest rate", async () => {
      await loanLogicContract.calculateInterestRate();
    })
    it("should calculate the maximum loan-to-value ratio", async () => {
      await loanLogicContract.calculateMaxLTV();
    })
    it("should set the cleth price on the price feed", async () => {

     const newPrice = parseEther("10");  // Setting the price
    const currentTime = (await ethers.provider.getBlock('latest')).timestamp; // Fetching the current block timestamp
    await priceFeed.setLatestPrice(newPrice, currentTime);
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
     const newPrice = parseEther("100");  // Setting the price
    const currentTime = (await ethers.provider.getBlock('latest')).timestamp; // Fetching the current block timestamp
    await priceFeed.setLatestPrice(newPrice, currentTime);
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
     
     const newPrice = parseEther("1");  // Setting the price
    const currentTime = (await ethers.provider.getBlock('latest')).timestamp; // Fetching the current block timestamp
    await priceFeed.setLatestPrice(newPrice, currentTime); // Setting the latest price along with the current timestamp
    })
    it("should get the version of the price feed", async () => {
      await priceFeed.version()
    })
    it("should liquidate collateral for a loan id 3", async () => {
      await loanLogicContract.connect(signer).setRecoveryAddress(signer.address);

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
    it("should not allow creating a loan when paused", async function () {
      await loanLogicContract.pause();
      await expect(
          loanLogicContract.connect(user).createLoan(parseEther("10"))
      ).to.be.revertedWith("EnforcedPause");

      await loanLogicContract.unpause();
  });
  it("should allow creating a loan when unpaused", async function () {
    const newPrice = parseEther("10");
    const currentTime = (await ethers.provider.getBlock('latest')).timestamp;
    await priceFeed.setLatestPrice(newPrice, currentTime);

    await expect(
        loanLogicContract.connect(user).createLoan(parseEther("10"))
    ).to.emit(loanLogicContract, "LoanCreated");
});
it("Confirm that setting a zero address fails", async function () {
  await expect(loanLogicContract.setRecoveryAddress(ethers.constants.AddressZero))
    .to.be.revertedWith("Invalid address");  
});
it("Check that a non-owner cannot set the recovery address", async function () {
  await expect(loanLogicContract.connect(user).setRecoveryAddress(user.address))
    .to.be.revertedWith("OwnableUnauthorizedAccount");  // Assuming using OpenZeppelin's Ownable
});
it("Check if the fetched price is outdated", async function () {
  // Simulate outdated price data
  const oldTimestamp = (await ethers.provider.getBlock('latest')).timestamp - 3600; // 1 hour old
  await priceFeed.setLatestPrice(ethers.utils.parseEther("1.5"), oldTimestamp);

  // Fetch the price using the loan logic contract
  await expect(loanLogicContract.fetchCLETHPrice()).to.be.revertedWith("Price data is too old");
});
it("should pause the contract and prevent state changes", async function () {
  await loanLogicContract.pause();
  await expect(loanLogicContract.connect(user).createLoan(parseEther("10"))).to.be.revertedWith("EnforcedPause");
});


it("should unpause the contract and allow state changes", async function() {
  await loanLogicContract.unpause();
  const newPrice = parseEther("1");  // Setting the price
    const currentTime = (await ethers.provider.getBlock('latest')).timestamp; // Fetching the current block timestamp
    await priceFeed.setLatestPrice(newPrice, currentTime);
  await expect(loanLogicContract.connect(user).createLoan(parseEther("10")))
      .to.emit(loanLogicContract, "LoanCreated");
});


it("should fail to create a loan when price data is outdated during operation", async function () {
  const outdatedTime = (await ethers.provider.getBlock('latest')).timestamp - 10000;
  await priceFeed.setLatestPrice(parseEther("1"), outdatedTime);
  await expect(loanLogicContract.connect(user).createLoan(parseEther("5")))
    .to.be.revertedWith("Price data is too old");
});
it("ensures no operations possible when paused", async function() {
  await loanLogicContract.pause();
  await expect(loanLogicContract.connect(user).createLoan(parseEther("5")))
    .to.be.revertedWith("EnforcedPause");
  await expect(loanLogicContract.connect(user).repayLoan(1))
    .to.be.revertedWith("EnforcedPause");
  await expect(loanLogicContract.connect(user).liquidateCollateral(1))
    .to.be.revertedWith("EnforcedPause");
});
it("should handle rapid sequential operations correctly", async function() {
  await loanLogicContract.unpause();
  const currentTimestamp = (await ethers.provider.getBlock('latest')).timestamp;
  await priceFeed.setLatestPrice(ethers.utils.parseEther("1.2"), currentTimestamp);
  await loanLogicContract.connect(user).createLoan(parseEther("5"));
  await loanLogicContract.connect(user).repayLoan(4);
  await expect(loanLogicContract.connect(user).createLoan(parseEther("10")))
    .to.emit(loanLogicContract, "LoanCreated");
  await expect(loanLogicContract.connect(user).repayLoan(5))
    .to.emit(loanLogicContract, "LoanRepaid");
});
it("should prevent non-owners from pausing or unpausing the contract", async function () {
  await expect(loanLogicContract.connect(user).pause()).to.be.revertedWith("OwnableUnauthorizedAccount");
  await expect(loanLogicContract.connect(user).unpause()).to.be.revertedWith("OwnableUnauthorizedAccount");
});
it("should revert if the fetched price is zero", async () => {
  const zeroPrice = parseEther("0");  // Setting the price to zero
  const currentTime = (await ethers.provider.getBlock('latest')).timestamp; // Fetching the current block timestamp
  await priceFeed.setLatestPrice(zeroPrice, currentTime);

  // Expect the fetchCLETHPrice to revert due to zero price
  await expect(loanLogicContract.fetchCLETHPrice()).to.be.revertedWith("CLETH: fetched price is zero");
});
it("should revert if the contract is paused and fetchCLETHPrice is called", async () => {
  await loanLogicContract.pause(); // Pausing the contract
  const validPrice = parseEther("10");  // Setting a non-zero price
  const currentTime = (await ethers.provider.getBlock('latest')).timestamp;
  await priceFeed.setLatestPrice(validPrice, currentTime);

  // Expect the fetchCLETHPrice to revert due to the contract being paused
  await expect(loanLogicContract.fetchCLETHPrice()).to.be.revertedWith("EnforcedPause");
  await loanLogicContract.unpause(); 
});
it("should correctly fetch the price when contract is not paused and price is non-zero", async () => {
  const validPrice = parseEther("10");  
  const currentTime = (await ethers.provider.getBlock('latest')).timestamp;
  await priceFeed.setLatestPrice(validPrice, currentTime);

  // Fetch the price using the loan logic contract
  const fetchedPrice = await loanLogicContract.fetchCLETHPrice();
  expect(fetchedPrice).to.equal(validPrice);
});





  })
})
