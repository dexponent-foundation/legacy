// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import "./StakingMaster.sol";
import {IValidatorShare} from "./interfaces/IValidatorShare.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeHolder {
    address public staker;
    address public masterContract;
    address public stakeManager = 0x00200eA4Ee292E253E6Ca07dBA5EdC07c8Aa37A3;
    IERC20 public clMatic;
    bool private approved = false;
    event DepositReceived(address indexed from, uint256 amount);
    event FundsSent(address indexed to, uint256 amount);
    event ClMaticReceived(address indexed from, uint256 amount);

    constructor(address _staker, address _masterContract, IERC20 _clMatic) {
        staker = _staker;
        masterContract = _masterContract;
        clMatic = _clMatic;
    }

    modifier onlyMasterOwner() {
        require(masterContract == msg.sender, "Caller is not the master owner");
        _;
    }

    receive() external payable {
        revert();
    }

    function TokenAPvoe(
        IERC20 token,
        address _validator,
        uint256 amount
    ) public {
        token.approve(_validator, amount);
    }

    function _buyVoucher(
        uint256 _amount,
        uint256 _minSharesToMint,
        address _validator,
        IERC20 token
    ) public onlyMasterOwner {
        if (!approved) {
            require(
                token.approve(stakeManager, type(uint256).max),
                "Failed to approve allowance"
            );
            approved = true;
        }
        IValidatorShare validatorContract = IValidatorShare(_validator);
        validatorContract.buyVoucher(_amount, _minSharesToMint);
    }

    function _sellVoucher(
        uint256 claimAmount,
        uint256 maximumSharesToBurn,
        address _validator
    ) public onlyMasterOwner {
        IValidatorShare validatorContract = IValidatorShare(_validator);
        validatorContract.sellVoucher(claimAmount, maximumSharesToBurn);
    }

    function unstakeClaimTokens_new(
        uint256 unboundNonce,
        address _validator
    ) public onlyMasterOwner {
        IValidatorShare validatorContract = IValidatorShare(_validator);
        validatorContract.unstakeClaimTokens_new(unboundNonce);
    }

    function withdrawETH(uint256 amount, address user) public {
        require(
            amount > 0 && amount <= address(this).balance,
            "Invalid withdrawal amount"
        );
        address payable to = payable(user);
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // Function to get the balance of Cleth tokens
    function getClethBalance() external view returns (uint256) {
        return clMatic.balanceOf(address(this));
    }

    function getEthbalance() public returns (uint256) {
        return address(this).balance;
    }
}
