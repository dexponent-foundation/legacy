// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./StakingMaster.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeHolder {
    address public staker;
    address public masterContract;
    IERC20 public clMatic;

    event DepositReceived(address indexed from, uint256 amount);
    event FundsSent(address indexed to, uint256 amount);
    event ClethReceived(address indexed from, uint256 amount);

    constructor(
        address _staker,
        address _masterContract,
        IERC20 _clMatic
    ) payable {
        staker = _staker;
        masterContract = _masterContract;
        clMatic = _clMatic;
        emit DepositReceived(_staker, msg.value);
    }

    modifier onlyMasterOwner() {
        require(
            StakingMaster(masterContract).isOwner(msg.sender),
            "Caller is not the master owner"
        );
        _;
    }

    receive() external payable {
        emit DepositReceived(msg.sender, msg.value);
    }

    function withdrawETH(uint256 amount) public {
        require(
            amount > 0 && amount <= address(this).balance,
            "Invalid withdrawal amount"
        );
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function receiveCleth(uint256 amount) external {
        require(
            clMatic.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        emit ClethReceived(msg.sender, amount);
    }

    // Function to get the balance of Cleth tokens
    function getClethBalance() external view returns (uint256) {
        return clMatic.balanceOf(address(this));
    }
}
