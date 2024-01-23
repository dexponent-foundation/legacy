// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CLETH.sol";
import "./StakeHolder.sol";
import "./IFigmentEth2Depositor.sol";


contract StakingMaster {
    CLETH private clethToken;
    mapping(address => StakeHolder) private stakeHolders;
    mapping(address => uint256) private stakedBalance;
    mapping(address => uint256) public lastStakeTime;
    mapping(address => UserAction[]) public userHistory;
    uint256 public totalPool;
    uint256 public lockDuration = 1;
    address public owner;
    IFigmentEth2Depositor public figmentDepositor;

    enum ActionType { Staked, Restaked, Withdrawn, Unstaked }
    struct UserAction {
        ActionType actionType;
        uint256 amount;
        uint256 timestamp;
    }
    event Unstaked(address indexed user, uint256 amount);

    event Staked(address indexed user, StakeHolder stakeHolderContract, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsRestaked(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(CLETH _clethToken) {
        clethToken = _clethToken;
        owner = msg.sender;
    }

    function setFigmentDepositor(IFigmentEth2Depositor _figmentDepositor) external onlyOwner {
        figmentDepositor = _figmentDepositor;
    }

    function stake() public payable {
    require(msg.value > 0, "Must send ETH to stake");

    StakeHolder stakeHolder = stakeHolders[msg.sender];
    if (address(stakeHolder) == address(0)) {
        // Pass the correct number of arguments to the StakeHolder constructor
        stakeHolder = new StakeHolder{value: msg.value}(msg.sender, address(this), figmentDepositor,clethToken);
        stakeHolders[msg.sender] = stakeHolder;
    } else {
        (bool success, ) = address(stakeHolder).call{value: msg.value}("");
        require(success, "Failed to send ETH to StakeHolder");
    }
        stakedBalance[msg.sender] += msg.value;
        lastStakeTime[msg.sender] = block.timestamp;
        totalPool += msg.value;
        userHistory[msg.sender].push(UserAction(ActionType.Staked, msg.value, block.timestamp));
        clethToken.mint(msg.sender, msg.value);

        emit Staked(msg.sender, stakeHolder, msg.value);
    }

   

function unstake(uint256 amount) public {
   
    require(clethToken.balanceOf(msg.sender) >= amount, "Not enough CLETH");

    // Transfer CLETH to StakeHolder contract
    clethToken.transferFrom(msg.sender, address(stakeHolders[msg.sender]), amount);

    // Optionally burn the CLETH tokens immediately
    // clethToken.burnFrom(address(stakeHolders[msg.sender]), amount);

    
    require(stakedBalance[msg.sender] >= amount, "Not enough staked ETH");
    stakedBalance[msg.sender] -= amount;
    totalPool -= amount;
    userHistory[msg.sender].push(UserAction(ActionType.Unstaked, amount, block.timestamp));
   emit Unstaked(msg.sender, amount);
    
}

    function getStakeHolderInfo(address user) public view returns (address, uint256) {
        StakeHolder stakeHolder = stakeHolders[user];
        // Ensure the user has a StakeHolder contract
        require(address(stakeHolder) != address(0), "User has no stake holder contract");
        // The address of the StakeHolder contract
        address stakeHolderAddress = address(stakeHolder);
        // The amount of ETH stored in the StakeHolder contract
        uint256 stakeHolderBalance = address(stakeHolder).balance;
        return (stakeHolderAddress, stakeHolderBalance);
    }
    // Function to deposit ETH into the contract
function depositETH() external payable {
    require(msg.value > 0, "Deposit amount must be greater than 0");
    
    // You can add more logic here if needed, such as updating balances or emitting events
    emit DepositReceived(msg.sender, msg.value);
}
function getStakedBalance(address account) public view returns (uint256) {
         return stakedBalance[account];
     }

event DepositReceived(address indexed depositor, uint256 amount);
// Function to withdraw ETH from the contract to the caller's address
function withdrawETH(uint256 amount) public {
    require(amount > 0 && amount <= address(this).balance, "Invalid withdrawal amount");

   
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");

    emit WithdrawalMade(msg.sender, amount);
}

event WithdrawalMade(address indexed receiver, uint256 amount);

     function isOwner(address _caller) public view returns (bool) {
    return _caller == owner;
}


    function depositToFigment(
    bytes[] calldata pubkeys,
    bytes[] calldata withdrawal_credentials,
    bytes[] calldata signatures,
    bytes32[] calldata deposit_data_roots
) public onlyOwner {
    require(address(figmentDepositor) != address(0), "Figment depositor address not set");
    uint256 totalDepositAmount = address(this).balance; // Use the balance of the StakingMaster contract
    require(totalDepositAmount > 0, "No ETH available for deposit");


    // Forward the ETH from this contract to the Figment Depositor
    figmentDepositor.deposit{value: totalDepositAmount}(
        pubkeys,
        withdrawal_credentials,
        signatures,
        deposit_data_roots
    );
}
enum UserStatus { Unknown, Whitelisted, Blacklisted }
mapping(address => UserStatus) public userStatus;

modifier onlyWhitelisted() {
    require(userStatus[msg.sender] == UserStatus.Whitelisted, "User is not whitelisted");
    _;
}

modifier notBlacklisted() {
    require(userStatus[msg.sender] != UserStatus.Blacklisted, "User is blacklisted");
    _;
}
function addToWhitelist(address user) public onlyOwner(){
    
    userStatus[user] = UserStatus.Whitelisted;
}

function addToBlacklist(address user) public onlyOwner {
   
    userStatus[user] = UserStatus.Blacklisted;
}

function removeFromWhitelist(address user) public onlyOwner{
    
    userStatus[user] = UserStatus.Unknown;
}

function removeFromBlacklist(address user) public onlyOwner {
    
    userStatus[user] = UserStatus.Unknown;
}

function checkUserStatus(address user) public view returns (UserStatus) {
    return userStatus[user];
}
function getTotalPool() public view returns (uint256) {
        return totalPool;
    }



}
