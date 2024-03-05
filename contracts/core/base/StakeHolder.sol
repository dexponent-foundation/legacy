// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../interfaces/IFigmentEth2Depositor.sol"; // Import the interface
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeHolder {
    address public staker;
    address public masterContractOwner;
    address public masterContract;
    IFigmentEth2Depositor public figmentDepositor;
    IERC20 public clethToken;
    event DepositReceived(address indexed from, uint256 amount);
    event FundsSent(address indexed to, uint256 amount);
    event ClethReceived(address indexed from, uint256 amount);

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
        emit DepositReceived(_staker, msg.value);
    }

    receive() external payable {
        emit DepositReceived(msg.sender, msg.value);
    }

    function withdrawETH(uint256 amount, address account) public {
        require(msg.sender == masterContract, "revert caller is not owner");
        require(
            amount > 0 && amount <= address(this).balance,
            "Invalid withdrawal amount"
        );
        (bool success, ) = address(account).call{value: amount}("");
        require(success, "Transfer failed");
    }
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
        uint256 depositAmount = 32 ether; // Specify 32 ETH
        require(
            address(this).balance >= depositAmount,
            "Insufficient balance for deposit"
        );
        // Forward 32 ETH from this contract to the Figment Depositor
        figmentDepositor.deposit{value: depositAmount}(
            pubkeys,
            withdrawal_credentials,
            signatures,
            deposit_data_roots
        );
    }

    modifier onlyMasterOwner() {
        require(
            masterContractOwner == msg.sender,
            "Caller is not the master owner"
        );
        _;
    }
}
