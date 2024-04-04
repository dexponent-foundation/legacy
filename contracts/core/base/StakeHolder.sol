// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IFigmentEth2Depositor.sol"; // Import the interface
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./events/Event.sol";

/**
 * @title StakeHolder
 * @dev The StakeHolder contract represents a stakeholder in the staking system.
 * It facilitates depositing, withdrawing, and interacting with the master contract and Figment depositor.
 */
contract StakeHolder is Events {
    address public staker;
    address public masterContractOwner;
    address public masterContract;
    IFigmentEth2Depositor public figmentDepositor;
    IERC20 public clethToken;
    event DepositReceived(address indexed from, uint256 amount);
    event FundsSent(address indexed to, uint256 amount);
    event ClethReceived(address indexed from, uint256 amount);

    /**
     * @dev Constructor to initialize the StakeHolder contract.
     * @param _staker The address of the staker.
     * @param _masterContract The address of the master contract.
     * @param _masterContractOwner The address of the master contract owner.
     * @param _figmentDepositor The Figment Eth2 Depositor contract.
     * @param _clethToken The clETH token contract.
     */
    constructor(
        address _staker,
        address _masterContract,
        address _masterContractOwner,
        IFigmentEth2Depositor _figmentDepositor,
        IERC20 _clethToken
    ) payable {
        staker = _staker;
        masterContractOwner = _masterContractOwner;
        masterContract = _masterContract;
        figmentDepositor = _figmentDepositor;
        clethToken = _clethToken;
        _clethToken.approve(_masterContract, type(uint256).max);
        emit DepositReceived(_staker, msg.value);
    }

    /**
     * @dev Fallback function to receive Ether.
     */
    receive() external payable {
        emit DepositReceived(msg.sender, msg.value);
    }

    /**
     * @dev Withdraws Ether from the contract.
     * @param amount The amount of Ether to withdraw.
     * @param account The address to withdraw Ether to.
     */
    function withdrawETH(uint256 amount, address account) public {
        require(msg.sender == masterContract, "revert caller is not owner");
        require(
            amount > 0 && amount <= address(this).balance,
            "Invalid withdrawal amount"
        );
        (bool success, ) = address(account).call{value: amount}("");
        require(success, "Transfer failed");
    }

    /**
     * @dev Deposits data to Figment Eth2 Depositor contract.
     * Only callable by the master contract owner.
     * @param pubkeys Array of public keys.
     * @param withdrawal_credentials Array of withdrawal credentials.
     * @param signatures Array of signatures.
     * @param deposit_data_roots Array of deposit data roots.
     */
    function depositToFigment(
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signatures,
        bytes32[] calldata deposit_data_roots
    ) external onlyMasterOwner {
        require(
            address(figmentDepositor) != address(0),
            "Figment depositor address not set"
        );
        uint256 depositAmount = 32 ether;
        require(
            address(this).balance >= depositAmount,
            "Insufficient balance for deposit"
        );
        figmentDepositor.deposit{value: depositAmount}(
            pubkeys,
            withdrawal_credentials,
            signatures,
            deposit_data_roots
        );
    }

    /**
     * @dev Modifier to check if the caller is the master contract owner.
     */
    modifier onlyMasterOwner() {
        require(
            masterContractOwner == msg.sender,
            "Caller is not the master owner"
        );
        _;
    }

    /**
     * @dev Sets the Figment Eth2 Depositor contract.
     * Only callable by the master contract owner.
     * @param _figmentDepositor The address of the new Figment Depositor contract.
     */
    function setFigmentDepositor(
        IFigmentEth2Depositor _figmentDepositor
    ) external onlyMasterOwner {
        require(
            address(_figmentDepositor) != address(0),
            "_figmentDepositor is zero address"
        );
        emit UpdateFigmentDepositAddress(
            address(figmentDepositor),
            address(_figmentDepositor)
        );
        figmentDepositor = _figmentDepositor;
    }

    /**
     * @dev Sends Ether to a specified recipient.
     * This function is only for testing purposes.
     * @param recipient The address to send Ether to.
     * @param amount The amount of Ether to send.
     */
    function sendEth(
        address payable recipient,
        uint256 amount
    ) external payable {
        recipient.transfer(amount);
    }
}
