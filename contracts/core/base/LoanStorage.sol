// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title LoanStorage
 * @dev The LoanStorage contract holds all state variables related to loans.
 * It includes details such as the USDC and clETH token contracts, total reserves
 * of USDC and clETH, total number of loans, clETH price, next loan ID, interest rate
 * target utilization, interest rate K factor, loan-to-value (LTV) target utilization,
 * LTV K factor, and liquidation threshold.
 * Additionally, it defines a struct for individual loans and a mapping to store loans by ID.
 */
contract LoanStorage is Initializable, OwnableUpgradeable {
    IERC20 public usdcToken; // USDC token contract
    IERC20 public clethToken; // clETH token contract
    uint256 public totalLoans; // Total number of loans
    uint256 public nextLoanId; // Next loan ID
    uint256 public constant interestRateTargetUtilization =70; // Interest rate target utilization
    uint256 public constant interestRateK =1; // Interest rate K factor
    uint256 public constant  ltvTargetUtilization =90; // Loan-to-value target utilization
    uint256 public constant ltvK =1; // LTV K factor
    uint256 public constant  liquidationThreshold = 90; // Liquidation threshold
    AggregatorV3Interface public priceFeed;
    uint256 public totalfund;
    uint256 public totalUSDCReserve;
    address public recoveryAddress;
    struct Loan {
        uint256 amount; // Loan amount
        uint256 interestRate; // Interest rate
        uint256 debt; // Debt
        uint256 startTime; // Loan start time
        bool isRepaid; // Flag indicating if the loan is repaid
        address borrower; // Borrower address
        uint256 collateralAmount; // Collateral amount
    }

    mapping(uint256 => Loan) public loans; // Mapping of loan IDs to Loan structs

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __dex_gap;
}
