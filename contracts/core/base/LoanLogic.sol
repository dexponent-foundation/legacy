// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./Storage.sol";
contract LoanLogic is LoanStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    event CollateralLiquidated(uint256 indexed loanId, uint256 collateralAmount);
    event LoanCreated(
    uint256 indexed loanId,
    address borrower,
    uint256 loanAmount,
    uint256 interestRate,
    uint256 collateralAmount,
    uint256 debt,
    uint256 startTime);

    function initialize(address _usdcTokenAddress, address _clethTokenAddress) public initializer {
        __LoanStorage_init();
        usdcToken = IERC20Upgradeable(_usdcTokenAddress);
        clethToken = IERC20Upgradeable(_clethTokenAddress);

        // Initialize other state variables
         uint256 decimals = 18; 

        totalUSDCReserve = 100000000000 * (10 ** decimals);
        totalCLETHReserve = 100000 * (10 ** decimals);
        totalLoans = 0;
        clethPrice = 2000; // Example initial value
        nextLoanId = 1;
        interestRateTargetUtilization = 30; // Example initial value
        interestRateK = 1; // Example initial value
        ltvTargetUtilization = 70; // Example initial value
        ltvK = 5; // Example initial value
        liquidationThreshold = 85; // Example initial value
    }

     function updateCLETHPrice(uint256 newPrice) public onlyOwner {
        clethPrice = newPrice;
    }

    

    function setInterestRateParameters(uint256 _targetUtilization, uint256 _k) public onlyOwner {
        interestRateTargetUtilization = _targetUtilization;
        interestRateK = _k;
    }

    function setLTVParameters(uint256 _targetUtilization, uint256 _k) public onlyOwner {
        ltvTargetUtilization = _targetUtilization;
        ltvK = _k;
    }

    // Modified calculateInterestRate function using new variables
    function calculateInterestRate() public view returns (uint256) {
        uint256 baseRate = 6;
        uint256 currentUtilization = (totalLoans * 100) / (totalUSDCReserve > 0 ? totalUSDCReserve : 1);
        return baseRate + interestRateK * (currentUtilization > interestRateTargetUtilization ? currentUtilization - interestRateTargetUtilization : 0);
    }

    // Modified calculateMaxLTV function using new variables
    function calculateMaxLTV() public view returns (uint256) {
        uint256 baseLTV = 70;
        uint256 currentUtilization = (totalLoans * 100) / (totalUSDCReserve > 0 ? totalUSDCReserve : 1);
        if (currentUtilization < ltvTargetUtilization) {
            return baseLTV;
        }
        uint256 ltvAdjustment = ltvK * (currentUtilization - ltvTargetUtilization);
        return baseLTV > ltvAdjustment ? baseLTV - ltvAdjustment : 0;
    }

    function calculateMaxLoanAmount(uint256 clethAmount) public view returns (uint256) {
        uint256 collateralValue = clethAmount * clethPrice;
        uint256 maxLTV = calculateMaxLTV(); 
       // uint256 maxLTV = 70;// Loan-to-Value ratio
        return (collateralValue * maxLTV) / 100000000000000000000;

    }

    function createLoan(uint256 clethAmount) public {
        uint256 loanAmount = calculateMaxLoanAmount(clethAmount);
        require(loanAmount <= totalUSDCReserve, "Insufficient liquidity");
        require(clethToken.transferFrom(msg.sender, address(this), clethAmount), "CLETH transfer failed");

        uint256 interestRate = calculateInterestRate();
      
        loans[nextLoanId] = Loan({
            amount: loanAmount,
            interestRate: interestRate,
            debt: loanAmount,
            startTime: block.timestamp,
            isRepaid: false,
            borrower: msg.sender,
            collateralAmount: clethAmount
        });

        require(usdcToken.transfer(msg.sender, loanAmount), "USDC transfer failed");

        totalUSDCReserve -= loanAmount;
        totalCLETHReserve += clethAmount;
        totalLoans += loanAmount;
        nextLoanId++;
        
        emit LoanCreated(
        nextLoanId,
        msg.sender,
        loanAmount,
        interestRate,
        clethAmount,
        loanAmount,
        block.timestamp
    );
    }
event LoanRepaid(uint256 indexed loanId, address borrower);

    function repayLoan(uint256 loanId) public {
        Loan storage loan = loans[loanId];
        require(!loan.isRepaid, "Loan already repaid");
        require(loan.borrower == msg.sender, "Only the borrower can repay the loan");

        uint256 repaymentAmount = calculateRepaymentAmount(loanId);
        require(usdcToken.transferFrom(msg.sender, address(this), repaymentAmount), "Repayment failed");
        
        loan.isRepaid = true;
        totalLoans -= loan.amount;
        totalUSDCReserve += repaymentAmount;

        // Returning the CLETH collateral to the borrower
        require(clethToken.transfer(loan.borrower, loan.collateralAmount), "Collateral return failed");
        totalCLETHReserve -= loan.collateralAmount;
            emit LoanRepaid(loanId, msg.sender);

        
    }

     

    function calculateRepaymentAmount(uint256 loanId) public view returns (uint256) {
        Loan storage loan = loans[loanId];
        uint256 timeElapsed = block.timestamp - loan.startTime;
        uint256 interest = (loan.amount * loan.interestRate / 100000000000000000000) * timeElapsed / 365 days;
        return loan.amount + interest;
    }
    function calculateInterestTillnow(uint256 loanId) public view returns (uint256) {
        Loan storage loan = loans[loanId];
        uint256 timeElapsed = block.timestamp - loan.startTime;
        uint256 interest = (loan.amount * loan.interestRate / 100000000000000000000) * timeElapsed / 365 days;
        return  interest;
    }
    function liquidateCollateral(uint256 loanId) public {
    Loan storage loan = loans[loanId];
    require(!loan.isRepaid, "Loan is already repaid or liquidated");

    // Calculate the current LTV
    uint256 loanValueInCLETH = (loan.debt * 1e18) / clethPrice; 
    uint256 currentLTV = (loanValueInCLETH * 100) / loan.collateralAmount;

    require(currentLTV > liquidationThreshold, "Loan LTV is below liquidation threshold");

    // Liquidate the collateral: Transfer collateral to the contract as part of the CLETH reserve
    totalCLETHReserve += loan.collateralAmount;
    
    // Mark the loan as repaid to prevent further actions on it
    loan.isRepaid = true;
    loan.debt = 0; 

    // Adjust total loans and reserves accordingly
    totalLoans -= loan.amount;

    emit CollateralLiquidated(loanId, loan.collateralAmount);

    require(clethToken.transferFrom(loan.borrower, address(this), loan.collateralAmount), "Collateral transfer failed");
}

    
}
