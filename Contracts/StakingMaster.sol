// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CLMatic.sol";
import "./StakeHolder.sol";
// import "./IFigmentEth2Depositor.sol";
contract StakingMaster {
    CLMatic  private clMatic;
    uint256 public totalPool;
    uint256 public lockDuration = 1;
    address public owner;
    mapping(address => StakeHolder)  public stakeHolders;
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public lastStakeTime;
    mapping(address => UserStatus) public userStatus;

    enum UserStatus { Unknown, Whitelisted, Blacklisted }
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
    event DepositReceived(address indexed depositor, uint256 amount);
    event WithdrawalMade(address indexed receiver, uint256 amount);
    constructor(CLMatic _clMatic) {
        clMatic = _clMatic;
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function stake() public payable   {
    require(msg.value > 0, "Must send ETH to stake");
 // TODO : add validation for 32 eth check 
    StakeHolder stakeHolder = stakeHolders[msg.sender];
    if (address(stakeHolder) == address(0)) {
        // Pass the correct number of arguments to the StakeHolder constructor
        stakeHolder = new StakeHolder{value: msg.value}(msg.sender, address(this),clMatic);
        stakeHolders[msg.sender] = stakeHolder;
    } else {
        (bool success, ) = address(stakeHolder).call{value: msg.value}("");
        require(success, "Failed to send ETH to StakeHolder");
    }
        clMatic.mint(msg.sender, msg.value);
        stakedBalance[msg.sender] += msg.value;
        lastStakeTime[msg.sender] = block.timestamp;
        totalPool += msg.value;
        emit Staked(msg.sender, stakeHolder, msg.value);
    }
function unstake(uint256 amount) public  {
    require(amount !=0,"Amount can not be zero");
    require(stakedBalance[msg.sender] >= amount, "Not enough staked ETH");
    require(clMatic.balanceOf(msg.sender) >= amount, "Not enough CLETH");
    clMatic.transferFrom(msg.sender, address(stakeHolders[msg.sender]), amount);
    stakedBalance[msg.sender] -= amount;
    totalPool -= amount;
   emit Unstaked(msg.sender, amount);
}
function depositETH() external payable {
    require(msg.value > 0, "Deposit amount must be greater than 0");
    emit DepositReceived(msg.sender, msg.value);
}

function withdrawETH(uint256 amount) public {
    require(amount > 0 && amount <= address(this).balance, "Invalid withdrawal amount");
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
    emit WithdrawalMade(msg.sender, amount);
}
function isOwner(address _caller) public view returns (bool) {
    return _caller == owner;
}
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




}
