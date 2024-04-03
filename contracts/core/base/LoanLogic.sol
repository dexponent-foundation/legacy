// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./LoanStorage.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title LoanLogic
 * @dev The main contract handling loan creation, repayment, collateral liquidation, and interest rate calculation.
 */

contract LoanLogic is LoanStorage, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using Math for uint256;
    event CollateralLiquidated(
        uint256 indexed loanId,
        uint256 collateralAmount
    );
    event LoanCreated(
        uint256 indexed loanId,
        address borrower,
        uint256 loanAmount,
        uint256 interestRate,
        uint256 collateralAmount,
        uint256 debt,
        uint256 startTime
    );
    event LoanRepaid(uint256 indexed loanId, address borrower);
    event USDCDeposited(address indexed depositor, uint256 amount);

    /**
     * @dev Initializes the contract with necessary addresses and initial values.
     * @param _usdcTokenAddress Address of the USDC token contract.
     * @param _clethTokenAddress Address of the cLETH token contract.
     * @param _priceFeedAddress Address of the Chainlink price feed contract.
     */
    function initialize(
        address _usdcTokenAddress,
        address _clethTokenAddress,
        address _priceFeedAddress
    ) public initializer {
        usdcToken = IERC20(_usdcTokenAddress);
        clethToken = IERC20(_clethTokenAddress);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        totalLoans = 0;
        nextLoanId = 1;
        interestRateTargetUtilization = 70;
        interestRateK = 1;
        ltvTargetUtilization = 80;
        ltvK = 1;
        liquidationThreshold = 90;
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
    }

    /**
     * @dev Fetches the current cLETH price from the oracle without updating the contract state.
     * @return The current cLETH price.
     */ function fetchCLETHPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/ int price,
            ,
            /*uint startedAt*/ uint256 timeStamp /*uint80 answeredInRound*/,

        ) = priceFeed.latestRoundData();

        // require(price > 0, "Invalid price data");
        // require(block.timestamp - timeStamp < 24 hours, "Price data is stale");

        return uint256(price);
    }

    /**
     * @dev Modifier to ensure the amount passed is greater than zero.
     * @param amount The amount to check.
     */
    modifier ZeroAmount(uint256 amount) {
        require(amount > 0, "Amount can not be zero");
        _;
    }

    /**
     * @dev Allows the owner to deposit USDC into the reserve.
     * @param amount The amount of USDC to deposit.
     */
    function depositUSDCToReserve(
        uint256 amount
    ) public ZeroAmount(amount) onlyOwner {
        require(
            usdcToken.transferFrom(msg.sender, address(this), amount),
            "USDC transfer failed"
        );
        totalUSDCReserve += amount;
        totalfund += totalUSDCReserve;
        emit USDCDeposited(msg.sender, amount);
    }

    /**
     * @dev Calculates the current interest rate based on the utilization of funds.
     * @return interestRate The current interest rate.
     */
    function calculateInterestRate()
        public
        view
        returns (uint256 interestRate)
    {
        uint256 baseRate = 6;

        uint256 currentUtilization = (totalLoans * 100) /
            (totalfund > 0 ? totalfund : 1);
        interestRate =
            baseRate +
            interestRateK *
            (
                currentUtilization > interestRateTargetUtilization
                    ? currentUtilization - interestRateTargetUtilization
                    : 0
            );
        return interestRate * 1e18;
    }

    /**
     * @dev Calculates the maximum Loan-to-Value (LTV) ratio based on the utilization of funds.
     * @return The maximum LTV ratio.
     */
    function calculateMaxLTV() public view returns (uint256) {
        uint256 baseLTV = 70;

        uint256 currentUtilization = ((totalLoans / 1e18) * 100) /
            ((totalfund > 0 ? (totalfund / 1e18) : 1));
        if (currentUtilization < ltvTargetUtilization) {
            return baseLTV;
        }
        uint256 ltvAdjustment = ltvK *
            (currentUtilization - ltvTargetUtilization);
        return baseLTV > ltvAdjustment ? baseLTV - ltvAdjustment : 0;
    }

    /**
     * @dev Calculates the maximum loan amount based on the provided collateral amount.
     * @param clethAmount The amount of cLETH provided as collateral.
     * @return The maximum loan amount.
     */
    function calculateMaxLoanAmount(
        uint256 clethAmount
    ) public view returns (uint256) {
        uint256 collateralValue = clethAmount * fetchCLETHPrice();
        uint256 maxLTV = calculateMaxLTV();

        // require(maxLTV > 0, 'not enough to process this loan');
        return (collateralValue * maxLTV) / 100000000000000000000;
    }

    /**
     * @dev Creates a new loan with the specified collateral amount.
     * @param clethAmount The amount of cLETH provided as collateral.
     */
    function createLoan(
        uint256 clethAmount
    ) public ZeroAmount(clethAmount) nonReentrant {
        uint256 maxLoanAmount = calculateMaxLoanAmount(clethAmount);

        require(maxLoanAmount <= totalfund, "Insufficient liquidity");
        require(
            clethToken.transferFrom(msg.sender, address(this), clethAmount),
            "CLETH transfer failed"
        );
        uint256 interestRate = calculateInterestRate();
        loans[nextLoanId] = Loan({
            amount: maxLoanAmount,
            interestRate: interestRate,
            debt: maxLoanAmount,
            startTime: block.timestamp,
            isRepaid: false,
            borrower: msg.sender,
            collateralAmount: clethAmount
        });

        require(
            usdcToken.transfer(msg.sender, maxLoanAmount),
            "USDC transfer failed"
        );
        totalUSDCReserve -= maxLoanAmount;
        totalLoans += maxLoanAmount;
        emit LoanCreated(
            nextLoanId,
            msg.sender,
            maxLoanAmount,
            interestRate,
            clethAmount,
            maxLoanAmount,
            block.timestamp
        );
        nextLoanId++;
    }

    /**
     * @dev Repays the specified loan.
     * @param loanId The ID of the loan to repay.
     */
    function repayLoan(uint256 loanId) public nonReentrant {
        Loan storage loan = loans[loanId];
        require(loan.borrower != address(0), "Loan does not exist");
        require(!loan.isRepaid, "Loan already repaid");
        require(
            loan.borrower == msg.sender,
            "Only the borrower can repay the loan"
        );

        uint256 repaymentAmount = calculateRepaymentAmount(loanId);
        require(
            usdcToken.transferFrom(msg.sender, address(this), repaymentAmount),
            "Repayment failed"
        );
        loan.isRepaid = true;
        totalLoans -= loan.amount;
        totalUSDCReserve += repaymentAmount;
        require(
            clethToken.transfer(loan.borrower, loan.collateralAmount),
            "Collateral return failed"
        );
        emit LoanRepaid(loanId, msg.sender);
    }

    /**
     * @dev Calculates the total repayment amount for the specified loan.
     * @param loanId The ID of the loan.
     * @return The total repayment amount.
     */
    function calculateRepaymentAmount(
        uint256 loanId
    ) public view returns (uint256) {
        Loan memory loan = loans[loanId];
        return loan.amount + calculateInterestTillnow(loanId);
    }

    /**
     * @dev Calculates the accrued interest for the specified loan until the current block timestamp.
     * @param loanId The ID of the loan.
     * @return The accrued interest.
     */
    function calculateInterestTillnow(
        uint256 loanId
    ) public view returns (uint256) {
        Loan memory loan = loans[loanId];
        uint256 timeElapsed = block.timestamp - loan.startTime;
        uint256 interest = ((loan.amount * loan.interestRate * timeElapsed) /
            100 ether) / (365 days);
        return interest;
    }

    /**
     * @dev Liquidates the collateral for the specified loan if its Loan-to-Value (LTV) ratio is below the liquidation threshold.
     * @param loanId The ID of the loan.
     */

    function liquidateCollateral(uint256 loanId) public nonReentrant {
        Loan storage loan = loans[loanId];
        require(!loan.isRepaid, "Loan is already repaid or liquidated");
        require(loan.borrower != address(0), "Loan does not exist");
        uint256 currentPrice = fetchCLETHPrice();

        uint256 loanValueInCLETH = loan.debt / currentPrice;
        uint256 currentLTV = calculateMaxLoanAmount(loanValueInCLETH);
        require(
            currentLTV > liquidationThreshold,
            "Loan LTV is below liquidation threshold"
        );

        require(
            clethToken.transfer(address(this), loan.collateralAmount),
            "Collateral transfer failed"
        );

        loan.isRepaid = true;
        loan.debt = 0;
        totalLoans -= loan.amount;
        emit CollateralLiquidated(loanId, loan.collateralAmount);
    }

    /**
     * @dev Gets the cLETH balance reserved in the contract.
     * @return The cLETH reserved balance.
     */
    function getClethReservedBalance() external view returns (uint256) {
        return IERC20(clethToken).balanceOf(address(this));
    }
}
