// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Storage contract holding all state variables
contract LoanStorage is Initializable, OwnableUpgradeable {
    IERC20Upgradeable public usdcToken;
    IERC20Upgradeable public clethToken;
    uint256 public totalUSDCReserve;
    uint256 public totalCLETHReserve;
    uint256 public totalLoans;
    uint256 public clethPrice;
    uint256 public nextLoanId;
    uint256 public interestRateTargetUtilization;
    uint256 public interestRateK;
    uint256 public ltvTargetUtilization;
    uint256 public ltvK;
    uint256 public liquidationThreshold;

    struct Loan {
        uint256 amount;
        uint256 interestRate;
        uint256 debt;
        uint256 startTime;
        bool isRepaid;
        address borrower;
        uint256 collateralAmount;
    }

    mapping(uint256 => Loan) public loans;

    function __LoanStorage_init() internal initializer {
      //  OwnableUpgradeable.__Ownable_init();
    }
}
