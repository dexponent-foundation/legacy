// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StakeHolder {
    address public staker;
    address public masterContract;

    // Event to notify when ETH is deposited to the StakeHolder contract
    event DepositReceived(address indexed from, uint256 amount);
    // Event to notify when ETH is released from the StakeHolder contract
    event FundsReleased(address indexed to, uint256 amount);

    constructor(address _staker, address _masterContract) payable {
        require(msg.value > 0, "Must send ETH to create a stake");
        staker = _staker;
        masterContract = _masterContract;
        emit DepositReceived(_staker, msg.value);
    }

    // Function to release funds to the staker
    function releaseFunds(uint256 amount) external {
        require(msg.sender == masterContract, "Only the master contract can release funds");
        require(amount <= address(this).balance, "Insufficient balance to release");
        payable(staker).transfer(amount);
        emit FundsReleased(staker, amount);
    }

    // Function to allow the staker to add more funds to the StakeHolder
    function deposit() external payable {
        require(msg.sender == staker, "Only the staker can deposit more funds");
        emit DepositReceived(msg.sender, msg.value);
    }

    // Ensure that the contract can receive ETH
    receive() external payable {
        emit DepositReceived(msg.sender, msg.value);
    }
}

